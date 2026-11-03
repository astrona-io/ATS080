# Question

Solve this question on: `terminal`

The team behind the `probe` application asked for TLS with cert-manager v1.21.3, which is installed in the namespace `cert-manager`. Someone started the work and left it broken. The application lives in the namespace `starfleet`: a Deployment `probe`, a Service `probe`, a ServiceAccount `probe` and a Certificate `probe-cert`. The pod of `probe` does not start, and the Certificate is not Ready. Repair the integration. Several things are wrong, and they do not all show up at once.

1. Find out why the Certificate `probe-cert` gets no status at all. Fix the cause. All three Deployments of cert-manager must run one available replica afterwards.

2. The Certificate refers to a ClusterIssuer named `starfleet-ca`. Make that issuer exist as a selfSigned ClusterIssuer, and make it Ready.

3. `probe-cert` must stay in `starfleet` and write the Secret `probe-tls`. It must cover the DNS names `probe.starfleet.svc` and `probe.starfleet.svc.cluster.local`. Keep the existing name and add the missing one. The certificate must become Ready.

4. The Deployment `probe` must start and mount the issued Secret `probe-tls` in the volume named `tls`, at the path `/etc/probe/tls`. Change the Deployment. Do not create a second Secret to match the wrong name.

5. The service account `probe` has more rights than a web application needs. Remove the excess so that it cannot read Secrets in other namespaces. Keep the service account itself.

`kubectl` already points at the cluster. cert-manager needs a few seconds to issue a certificate, and a pod needs a few seconds to start, so run a check again if it still shows the old result.
