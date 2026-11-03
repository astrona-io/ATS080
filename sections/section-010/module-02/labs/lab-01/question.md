# Question

Solve this question on: `terminal`

A release to the `starfleet` namespace did not finish. Two Deployments, `probe` and `scout`, do not converge, and the pipeline reported `Progressing=False`. You must find the two causes, record them, and bring both Deployments to a converged state, without deleting anything. `kubectl` already points at the cluster as the cluster administrator. Both Deployments use `progressDeadlineSeconds: 60`.

1. Read the facts before you fix anything. Create the ConfigMap `convergence-report` in the namespace `starfleet` with these keys:
   - `probe-progressing-reason`: the `reason` of the `Progressing` condition of the Deployment `probe`
   - `probe-bad-image`: the container image that the newest, not working ReplicaSet of `probe` uses
   - `scout-pod-reason`: the `reason` of the `PodScheduled` condition of the new `scout` pod that is `Pending`

2. Fix `probe` in place. The Deployment must use the image `mccutchen/go-httpbin:2.25.0` again and it must converge: every replica available and updated, `status.observedGeneration` equal to `metadata.generation`, `Available` true and `Progressing` true with the reason `NewReplicaSetAvailable`. Keep `progressDeadlineSeconds` at 60.

3. Fix `scout` in place. Its pods must be scheduled and ready, the CPU request of the container must be `100m` or lower, and the Deployment must converge in the same way as `probe`.

4. Do not delete or create the Deployments again, and do not change `shuttle` or `drifter`. `shuttle` must get an answer from the `scout` and `probe` Services.
