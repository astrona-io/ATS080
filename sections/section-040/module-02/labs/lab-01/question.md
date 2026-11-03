# Question

Solve this question on: `terminal`

cert-manager v1.21.3 is installed in the namespace `cert-manager` and works. No Issuer and no ClusterIssuer exist. The namespaces `starfleet` and `outpost` exist. In `outpost`, a Certificate named `drifter-cert` was created earlier. It asks for the Secret `drifter-tls` and refers to the Issuer `outpost-issuer`, which does not exist yet. Do not change cert-manager, and do not edit the `issuerRef` of `drifter-cert`.

1. In the namespace `starfleet`, create a selfSigned Issuer named `starfleet-selfsigned`.

2. In `starfleet`, create a Certificate named `scout-cert` that stores its key pair in the Secret `scout-tls`. It must use the Issuer from step 1 and list the DNS names `scout.starfleet.svc` and `scout.starfleet.svc.cluster.local`. The certificate must be valid for 48 hours, and cert-manager must start the renewal 12 hours before it expires.

3. Make `drifter-cert` in `outpost` become Ready. Find out why it is not Ready and fix the cause.

4. Use namespaced Issuer resources only. Do not create a ClusterIssuer.

`kubectl` already points at the cluster. cert-manager needs a few seconds to issue a certificate, so run a check again if it still shows the old result.
