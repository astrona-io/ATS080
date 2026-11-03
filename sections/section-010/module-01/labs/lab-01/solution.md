# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was written and checked with static checks only (it has not been run), so the outputs below are described and not copied.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-010/module-01/labs/lab-01
```

## Step 1: Scale the Deployment

The Deployment controller owns the ReplicaSet size, so the change goes to the Deployment:

```sh
kubectl -n starfleet scale deployment scout --replicas=4
kubectl -n starfleet rollout status deployment/scout
```

The first command prints `deployment.apps/scout scaled`. The second waits until the controller reports that all replicas are available. A scale is a change to `spec`, so `metadata.generation` goes up, and the controller copies the new value into `status.observedGeneration` when it has processed the change. Compare the two numbers:

```sh
kubectl -n starfleet get deployment scout -o jsonpath='{.metadata.generation} {.status.observedGeneration} {.status.availableReplicas}{"\n"}'
```

The first two numbers are equal and the third is `4`.

## Step 2: Read the ownership chain

Read each value and keep it in a shell variable. The Deployment `uid` comes from the Deployment itself:

```sh
DEPLOYMENT_UID=$(kubectl -n starfleet get deployment scout -o jsonpath='{.metadata.uid}')
```

The pod owner is in the `ownerReferences` of the first pod. Its name is the ReplicaSet name and its kind is `ReplicaSet`:

```sh
POD_OWNER_KIND=$(kubectl -n starfleet get pods -l app=scout -o jsonpath='{.items[0].metadata.ownerReferences[0].kind}')
REPLICASET_NAME=$(kubectl -n starfleet get pods -l app=scout -o jsonpath='{.items[0].metadata.ownerReferences[0].name}')
OBSERVED_GENERATION=$(kubectl -n starfleet get deployment scout -o jsonpath='{.status.observedGeneration}')
```

As a cross-check, the owner of that ReplicaSet must be the same Deployment `uid`:

```sh
kubectl -n starfleet get replicaset "$REPLICASET_NAME" -o jsonpath='{.metadata.ownerReferences[0].uid}{"\n"}'
```

The value is equal to `DEPLOYMENT_UID`. Now create the ConfigMap from the four variables:

```sh
kubectl -n starfleet create configmap owner-chain \
  --from-literal=deployment-uid="$DEPLOYMENT_UID" \
  --from-literal=replicaset="$REPLICASET_NAME" \
  --from-literal=pod-owner-kind="$POD_OWNER_KIND" \
  --from-literal=observed-generation="$OBSERVED_GENERATION"
```

Run the grader:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-010/module-01/labs/lab-01
```

All four checks pass. Then remove the lab:

```sh
astrona destroy ats-080-lab-010-01
```
