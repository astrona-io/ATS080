# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. Command output is described in words, because names and ages differ on every run.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-040/module-01/labs/lab-01
```

Look at the starting state first. The operator runs, and each `Beacon` has a child ConfigMap, but nothing else:

```sh
kubectl -n starfleet get beacons,configmaps
kubectl -n beacon-system logs deployment/beacon-operator
kubectl -n starfleet get configmap beacon-scout -o jsonpath='{.metadata.ownerReferences}'
```

The `Beacon` list shows an empty `PHASE` column. The log shows the start line only. The last command prints nothing, because the child has no `ownerReference`.

## Step 1: Give the operator the permissions it needs

The operator must patch `Beacon` resources (to add and remove a finalizer), patch the `status` subresource, and create and delete ConfigMaps in `beacon-registry`. Keep the permissions in Roles, one per namespace, so the access stays small. Save this as `rbac-beacon-operator.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: beacon-operator
  namespace: starfleet
rules:
  - apiGroups: ["ops.starfleet.example"]
    resources: ["beacons"]
    verbs: ["get", "list", "watch", "patch"]
  - apiGroups: ["ops.starfleet.example"]
    resources: ["beacons/status"]
    verbs: ["get", "patch"]
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list", "create", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: beacon-operator-registry
  namespace: beacon-registry
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "create", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: beacon-operator-registry
  namespace: beacon-registry
subjects:
  - kind: ServiceAccount
    name: beacon-operator
    namespace: beacon-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: beacon-operator-registry
```

Apply it:

```sh
kubectl apply -f rbac-beacon-operator.yaml
```

The Role `beacon-operator` in `starfleet` changes, and the Role and RoleBinding in `beacon-registry` are new. The service account gets no `delete` on ConfigMaps in `starfleet`: the garbage collector deletes the child, not the operator.

## Step 2: Replace the script

The new script adds three things to the starter loop. `ensure_child` puts an `ownerReferences` entry with the `uid` of the `Beacon` into the ConfigMap it applies. `ensure_registry_entry` creates the registry entry only when it is missing. `reconcile` adds the finalizer, and when `deletionTimestamp` is set it removes the registry entry first and the finalizer second. `update_status` patches the status subresource only when it differs. Save this as `configmap-beacon-operator-script.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: beacon-operator-script
  namespace: beacon-system
data:
  reconcile.sh: |
    #!/usr/bin/env bash
    # Reconcile loop for Beacon resources: child ConfigMap, status, registry entry and finalizer.
    set -u
    WATCH_NAMESPACE="${WATCH_NAMESPACE:-starfleet}"
    REGISTRY_NAMESPACE="${REGISTRY_NAMESPACE:-beacon-registry}"
    INTERVAL="${INTERVAL:-5}"
    FINALIZER="ops.starfleet.example/registry-cleanup"
    
    log() { echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $*"; }
    
    # ensure_child applies the child ConfigMap. The ownerReference makes the
    # Kubernetes garbage collector delete the ConfigMap when the Beacon is deleted.
    ensure_child() {
      local name="$1" uid="$2" message="$3" channel="$4"
      jq -n --arg ns "$WATCH_NAMESPACE" --arg name "$name" --arg uid "$uid" --arg message "$message" --arg channel "$channel" '{
        apiVersion: "v1",
        kind: "ConfigMap",
        metadata: {
          name: ("beacon-" + $name),
          namespace: $ns,
          labels: {"app.kubernetes.io/managed-by": "beacon-operator"},
          ownerReferences: [{
            apiVersion: "ops.starfleet.example/v1",
            kind: "Beacon",
            name: $name,
            uid: $uid,
            controller: true,
            blockOwnerDeletion: true
          }]
        },
        data: {message: $message, channel: $channel}
      }' | kubectl apply -f - >/dev/null
    }
    
    # ensure_registry_entry creates the registry entry only when it is missing.
    # The entry lives in another namespace, so an ownerReference cannot cover it.
    ensure_registry_entry() {
      local name="$1" uid="$2" entry="${WATCH_NAMESPACE}-$1"
      if kubectl -n "$REGISTRY_NAMESPACE" get configmap "$entry" >/dev/null 2>&1; then
        return 0
      fi
      jq -n --arg ns "$REGISTRY_NAMESPACE" --arg entry "$entry" --arg beacon "$WATCH_NAMESPACE/$name" --arg uid "$uid" '{
        apiVersion: "v1",
        kind: "ConfigMap",
        metadata: {name: $entry, namespace: $ns, labels: {"app.kubernetes.io/managed-by": "beacon-operator"}},
        data: {beacon: $beacon, uid: $uid}
      }' | kubectl create -f - >/dev/null
    }
    
    remove_registry_entry() {
      kubectl -n "$REGISTRY_NAMESPACE" delete configmap "${WATCH_NAMESPACE}-$1" --ignore-not-found >/dev/null
    }
    
    # add_finalizer and remove_finalizer keep every other finalizer on the object.
    add_finalizer() {
      local name="$1" json="$2"
      kubectl -n "$WATCH_NAMESPACE" patch beacon "$name" --type=merge \
        -p "$(jq -c --arg f "$FINALIZER" '{metadata: {finalizers: (((.metadata.finalizers // []) + [$f]) | unique)}}' <<<"$json")" >/dev/null
    }
    
    remove_finalizer() {
      local name="$1" json="$2"
      kubectl -n "$WATCH_NAMESPACE" patch beacon "$name" --type=merge \
        -p "$(jq -c --arg f "$FINALIZER" '{metadata: {finalizers: ((.metadata.finalizers // []) - [$f])}}' <<<"$json")" >/dev/null
    }
    
    update_status() {
      local name="$1" generation="$2" observed="$3" phase="$4"
      if [ "$observed" = "$generation" ] && [ "$phase" = "Ready" ]; then
        return 0
      fi
      kubectl -n "$WATCH_NAMESPACE" patch beacon "$name" --subresource=status --type=merge \
        -p "$(jq -nc --argjson generation "$generation" --arg configmap "beacon-$name" \
          '{status: {phase: "Ready", observedGeneration: $generation, configMapName: $configmap}}')" >/dev/null
    }
    
    reconcile() {
      local name="$1" json uid message channel generation observed phase deleting has_finalizer
      json="$(kubectl -n "$WATCH_NAMESPACE" get beacon "$name" -o json 2>/dev/null)" || return 0
      uid="$(jq -r '.metadata.uid' <<<"$json")"
      deleting="$(jq -r '.metadata.deletionTimestamp // ""' <<<"$json")"
      has_finalizer="$(jq -r --arg f "$FINALIZER" '((.metadata.finalizers // []) | index($f)) != null' <<<"$json")"
    
      if [ -n "$deleting" ]; then
        if [ "$has_finalizer" = "true" ]; then
          if remove_registry_entry "$name"; then
            remove_finalizer "$name" "$json" && log "cleaned up $name"
          else
            log "error: cannot remove registry entry for $name, keeping finalizer"
          fi
        fi
        return 0
      fi
    
      if [ "$has_finalizer" != "true" ]; then
        add_finalizer "$name" "$json" || { log "error: cannot add finalizer to $name"; return 1; }
      fi
    
      message="$(jq -r '.spec.message' <<<"$json")"
      channel="$(jq -r '.spec.channel // "routine"' <<<"$json")"
      generation="$(jq -r '.metadata.generation' <<<"$json")"
      observed="$(jq -r '.status.observedGeneration // 0' <<<"$json")"
      phase="$(jq -r '.status.phase // ""' <<<"$json")"
    
      ensure_registry_entry "$name" "$uid" || { log "error: cannot create registry entry for $name"; return 1; }
      ensure_child "$name" "$uid" "$message" "$channel" || { log "error: cannot ensure child for $name"; return 1; }
      update_status "$name" "$generation" "$observed" "$phase" || log "error: cannot update status for $name"
    }
    
    log "beacon-operator starting, namespace=$WATCH_NAMESPACE interval=${INTERVAL}s"
    while true; do
      for name in $(kubectl -n "$WATCH_NAMESPACE" get beacons -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
        reconcile "$name"
      done
      sleep "$INTERVAL"
    done
```

Apply it and restart the operator, because the pod reads the script when it starts:

```sh
kubectl apply -f configmap-beacon-operator-script.yaml
kubectl -n beacon-system rollout restart deployment/beacon-operator
kubectl -n beacon-system rollout status deployment/beacon-operator
```

Then check the result:

```sh
kubectl -n starfleet get beacons
kubectl -n starfleet get configmap beacon-scout -o jsonpath='{.metadata.ownerReferences[0].kind}'
kubectl -n beacon-registry get configmaps
```

After a few seconds the `PHASE` column shows `Ready` for both `Beacon` resources. The second command prints `Beacon`. The registry namespace holds `starfleet-scout` and `starfleet-probe`. Run the grader:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-040/module-01/labs/lab-01 --keep
```

The checks `child-owned-by-beacon`, `status-follows-spec`, `finalizer-cleans-registry` and `restart-is-idempotent` pass. If `status-follows-spec` fails, read the operator log: a `Forbidden` message means the Role misses `beacons/status`.

## Step 3: Prove the least privilege

Ask the API server what the service account may do:

```sh
kubectl auth can-i get secrets -n starfleet --as=system:serviceaccount:beacon-system:beacon-operator
kubectl auth can-i delete configmaps -n starfleet --as=system:serviceaccount:beacon-system:beacon-operator
kubectl auth can-i delete configmaps -n beacon-registry --as=system:serviceaccount:beacon-system:beacon-operator
```

The first two print `no`. The third prints `yes`. Run the grader without `--keep`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-040/module-01/labs/lab-01
```

All five checks pass. The check `least-privilege` fails when a Role grants `delete` on ConfigMaps in `starfleet`, any access to Secrets, or a ClusterRole that lets the operator list `Beacon` resources in every namespace. The check `restart-is-idempotent` fails when the script creates the registry entry without testing for it first and so errors or replaces the object.
