# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was written and checked with static checks only (it has not been run), so the outputs below are described and not copied.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-010/capstone/labs/lab-01
```

## Step 1: Read the Deployments from the top

```sh
kubectl -n starfleet get deployment scout probe
kubectl -n starfleet get deployment scout -o jsonpath='{range .status.conditions[*]}{.type}{"="}{.status}{" "}{.reason}{"\n"}{end}'
kubectl -n starfleet get pods -l 'app in (scout,probe)'
```

Both Deployments have fewer up-to-date replicas than desired, and `Progressing` is `False` with `ProgressDeadlineExceeded`. The new `scout` pod shows `ErrImagePull` or `ImagePullBackOff`. The new `probe` pods have the status `Running` with `READY` `0/1`.

## Step 2: Find the causes

```sh
kubectl -n starfleet describe pods -l app=scout
kubectl -n starfleet describe pods -l app=probe
```

For `scout`, the events show `Failed` and `BackOff` messages about the image `ghcr.io/stefanprodan/podinfo:6.15.0-does-not-exist`. For `probe`, the events show `Unhealthy` with a message that the readiness probe failed with the status code 404. The probe path is `/ready`, and go-httpbin answers `/get`.

## Step 3: Fix both Deployments

```sh
kubectl -n starfleet set image deployment/scout scout=ghcr.io/stefanprodan/podinfo:6.15.0
kubectl -n starfleet patch deployment probe --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/get"}]'
kubectl -n starfleet rollout status deployment/scout --timeout=180s
kubectl -n starfleet rollout status deployment/probe --timeout=180s
```

Both rollouts finish. The template of `scout` is again the original one, so the controller reuses the old ReplicaSet and gives it a new revision number. The new `probe` template is correct, so its new pods become ready and the old ones are removed.

## Step 4: Release the finalizer

The ConfigMap has a `deletionTimestamp` and one finalizer. Check, then remove the finalizer:

```sh
kubectl -n starfleet get configmap decommissioned-beacon -o jsonpath='{.metadata.deletionTimestamp}{" "}{.metadata.finalizers}{"\n"}'
kubectl -n starfleet patch configmap decommissioned-beacon --type=merge -p '{"metadata":{"finalizers":null}}'
kubectl -n starfleet get configmaps
```

The list no longer has `decommissioned-beacon`, and `active-beacon` is still there.

## Step 5: Create the dependent release note

Read the three values from the cluster:

```sh
kubectl -n starfleet get deployment scout -o jsonpath='{.metadata.uid}{"\n"}'
kubectl -n starfleet get deployment scout -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}{"\n"}'
kubectl -n starfleet get pods -l app=scout -o jsonpath='{.items[0].spec.containers[0].image}{"\n"}'
```

Save this as `configmap-release-note.yaml`. Replace `<UID>` with the first value and `<REVISION>` with the second:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: release-note
  namespace: starfleet
  ownerReferences:
    - apiVersion: apps/v1
      kind: Deployment
      name: scout
      uid: <UID>
data:
  revision: "<REVISION>"
  image: ghcr.io/stefanprodan/podinfo:6.15.0
```

Apply it:

```sh
kubectl apply -f configmap-release-note.yaml
```

Then check the result:

```sh
kubectl -n starfleet get configmap release-note -o jsonpath='{.metadata.ownerReferences[0].kind}{" "}{.metadata.ownerReferences[0].name}{"\n"}'
```

The command prints `Deployment scout`. If the `uid` does not match a live object, the garbage collector treats the owner as missing and deletes the ConfigMap, so copy the value exactly. Grade the lab:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-010/capstone/labs/lab-01
```

All five checks pass. Then remove the lab:

```sh
astrona destroy ats-080-capstone-010
```
