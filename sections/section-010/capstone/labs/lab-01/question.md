# Question

Solve this question on: `terminal`

A release to the `starfleet` namespace is stuck in three places, and the platform team needs a clean, documented state before the next release. The Deployments use `progressDeadlineSeconds: 60`. `kubectl` already points at the cluster as the cluster administrator. Fix everything in place: do not delete or create the Deployments again, and do not change `shuttle` or `drifter`.

1. The Deployment `scout` reports `Progressing=False`. Find the cause from the pods and events, and fix the Deployment so that it uses the image `ghcr.io/stefanprodan/podinfo:6.15.0` and converges: every replica updated and available, `status.observedGeneration` equal to `metadata.generation`, `Available` true, and `Progressing` true with the reason `NewReplicaSetAvailable`.

2. The Deployment `probe` also reports `Progressing=False`, but its new pods are running. Find out why they are not ready, and fix the Deployment so that it converges in the same way. Keep the readiness probe: the probe must use a path that the `probe` container answers with HTTP 200.

3. The ConfigMap `decommissioned-beacon` in `starfleet` was deleted a while ago, but it is still there. The cleanup that it stood for is done, so release the object. Delete nothing else: the ConfigMap `active-beacon` must stay.

4. After the fix, create the ConfigMap `release-note` in `starfleet` as a dependent of the Deployment `scout`: its `ownerReferences` must name the Deployment `scout` (`apiVersion: apps/v1`, `kind: Deployment`) with the live `uid`. It must have two keys: `revision` with the value of the annotation `deployment.kubernetes.io/revision` of `scout` at that time, and `image` with the image that the `scout` pods run.

5. `shuttle` must still get an answer from the `scout` and `probe` Services.
