# Question

Solve this question on: `terminal`

The platform offers an `Outpost` claim that creates a namespace, a Service and a `scout` Deployment, and writes a record ConfigMap about each claim into the namespace `starfleet-records`. Two claims exist in the `starfleet` namespace: `scout` and `probe`. Both are only partly working, and the platform team wants three things fixed. `kubectl` points at the cluster as the cluster administrator.

1. The identity of `provider-kubernetes` (the service account `provider-kubernetes` in `crossplane-system`) cannot create Deployments, so the `deployment` Object of each claim fails. Give the identity the permission to manage Deployments with a new ClusterRole and ClusterRoleBinding. Do not bind `cluster-admin` and do not make the access wider than Deployments in the `apps` group. Wait until both claims are `Synced` and `Ready`.

2. The claim `scout` must publish a connection secret. The XRD and the Composition already provide the key `endpoint`. Make Crossplane write the secret `scout-conn` in the namespace `starfleet`. Its key `endpoint` must hold `scout.outpost-scout.svc.cluster.local:9898`.

3. The record ConfigMap in `starfleet-records` is deleted together with its claim. The platform team wants the record to stay after a claim is deleted, while everything else of the claim is removed. Change the Composition `outpost-kubernetes` so the resource named `record` is not deleted from the cluster when its Object is deleted. Wait until the Object of the claim `probe` carries the change, and then delete the claim `probe`. The namespace `outpost-probe` must disappear, and the ConfigMap `record-probe` must stay in `starfleet-records`.

Do not delete the claim `scout`, the XRD or the function.
