# Question

Solve this question on: `terminal`

The `scout` Deployment in the namespace `starfleet` must run four replicas for a longer sensor sweep. After the change, the team writes down the ownership chain of the `scout` pods as evidence that the Deployment controller manages them. `kubectl` already points at the cluster as the cluster administrator.

1. Scale the Deployment `scout` to 4 replicas. Change the Deployment, not the ReplicaSet or the pods, and do not delete or create the Deployment again. Wait until the controller has finished: all 4 replicas must be available, and `status.observedGeneration` must be equal to `metadata.generation`.

2. Create the ConfigMap `owner-chain` in the namespace `starfleet`. It must hold these four keys, and every value must be read from the live cluster after the scaling:
   - `deployment-uid`: the `uid` of the Deployment `scout`
   - `replicaset`: the name of the ReplicaSet that owns the `scout` pods
   - `pod-owner-kind`: the `kind` that is written in `ownerReferences` of a `scout` pod
   - `observed-generation`: the value of `status.observedGeneration` of the Deployment `scout`

3. Do not change `probe`, `shuttle` or `drifter`. They must keep their current Deployments, and `shuttle` must still get an answer from the `scout` and `probe` Services.
