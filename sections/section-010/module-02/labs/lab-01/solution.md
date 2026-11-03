# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was written and checked with static checks only (it has not been run), so the outputs below are described and not copied.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-010/module-02/labs/lab-01
```

## Step 1: Read the Deployment conditions

Start at the top of the reading order, the Deployments:

```sh
kubectl -n starfleet get deployment probe scout
kubectl -n starfleet get deployment probe -o jsonpath='{range .status.conditions[*]}{.type}{"="}{.status}{" "}{.reason}{"\n"}{end}'
```

The table shows that fewer replicas are up to date than desired. For `probe`, the condition `Progressing` is `False` with the reason `ProgressDeadlineExceeded`, and `Available` is `True` because the old pods still run.

## Step 2: Find the cause for probe

List the ReplicaSets of `probe` with their images, then look at the pods:

```sh
kubectl -n starfleet get replicasets -l app=probe -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.replicas}{" "}{.spec.template.spec.containers[0].image}{"\n"}{end}'
kubectl -n starfleet get pods -l app=probe
```

One ReplicaSet has the image `mccutchen/go-httpbin:2.25.0-does-not-exist`. Its pod has the status `ErrImagePull` or `ImagePullBackOff`. That image is the value for `probe-bad-image`.

## Step 3: Find the cause for scout

```sh
kubectl -n starfleet get pods -l app=scout -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.phase}{" "}{.status.conditions[?(@.type=="PodScheduled")].reason}{"\n"}{end}'
```

The new pod is `Pending` with the reason `Unschedulable`. The event from the scheduler (`kubectl -n starfleet describe pods -l app=scout`) says that no node has enough CPU.

## Step 4: Record the facts

Create the report before the fix, while the failing objects still exist:

```sh
kubectl -n starfleet create configmap convergence-report \
  --from-literal=probe-progressing-reason=ProgressDeadlineExceeded \
  --from-literal=probe-bad-image=mccutchen/go-httpbin:2.25.0-does-not-exist \
  --from-literal=scout-pod-reason=Unschedulable
```

## Step 5: Fix both Deployments

Set the working image on `probe`. The pod template becomes equal to the one in the old ReplicaSet, so the controller reuses that ReplicaSet. For `scout`, replace the CPU request and limit:

```sh
kubectl -n starfleet set image deployment/probe probe=mccutchen/go-httpbin:2.25.0
kubectl -n starfleet patch deployment scout -p '{"spec":{"template":{"spec":{"containers":[{"name":"scout","resources":{"requests":{"cpu":"10m"},"limits":{"cpu":"100m"}}}]}}}}'
kubectl -n starfleet rollout status deployment/probe --timeout=180s
kubectl -n starfleet rollout status deployment/scout --timeout=180s
```

Both rollouts finish. `kubectl rollout undo` on each Deployment also works, because the previous template of each one is the working one. Read the conditions again: `Progressing` is `True` with `NewReplicaSetAvailable`, and `Available` is `True`. Grade the lab:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-010/module-02/labs/lab-01
```

All five checks pass. Then remove the lab:

```sh
astrona destroy ats-080-lab-010-02
```
