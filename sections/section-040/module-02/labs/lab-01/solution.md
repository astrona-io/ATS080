# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. Command output is described in words, because names, times and keys differ on every run.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-040/module-02/labs/lab-01
```

Look at the starting state. cert-manager runs, and `drifter-cert` is waiting:

```sh
kubectl -n cert-manager get deployments
kubectl -n outpost get certificate drifter-cert
kubectl -n outpost describe certificate drifter-cert
```

The Certificate shows `READY` as `False`. The Ready condition and the events say that cert-manager cannot find the Issuer `outpost-issuer`. This is the cause for step 3.

## Step 1: Create the Issuer in starfleet

An Issuer is a namespaced resource. It can sign only Certificates in its own namespace. The `selfSigned` type signs a certificate with the key of the certificate itself, so no certificate authority is needed. Save this as `issuer-starfleet-selfsigned.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: starfleet-selfsigned
  namespace: starfleet
spec:
  selfSigned: {}
```

Apply it:

```sh
kubectl apply -f issuer-starfleet-selfsigned.yaml
```

Then check the result:

```sh
kubectl -n starfleet get issuer starfleet-selfsigned
```

The `READY` column shows `True` after a moment.

## Step 2: Request the certificate

`duration` is the lifetime of the certificate and `renewBefore` is how long before the end cert-manager starts to renew. The webhook accepts a duration of at least one hour and a `renewBefore` of at least five minutes. Save this as `certificate-scout-cert.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: scout-cert
  namespace: starfleet
spec:
  secretName: scout-tls
  duration: 48h
  renewBefore: 12h
  dnsNames:
    - scout.starfleet.svc
    - scout.starfleet.svc.cluster.local
  issuerRef:
    name: starfleet-selfsigned
    kind: Issuer
    group: cert-manager.io
```

Apply it:

```sh
kubectl apply -f certificate-scout-cert.yaml
```

Then check the result:

```sh
kubectl -n starfleet get certificate scout-cert
kubectl -n starfleet get certificaterequest
kubectl -n starfleet get secret scout-tls
kubectl -n starfleet get certificate scout-cert -o jsonpath='{.status.notBefore} {.status.notAfter} {.status.renewalTime}'
```

The Certificate becomes `READY` `True`. One CertificateRequest exists, and the Secret `scout-tls` has the type `kubernetes.io/tls`. The last command prints three times: the end is 48 hours after the start, and the renewal time is 12 hours before the end. Run the grader:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-040/module-02/labs/lab-01 --keep
```

The checks `scout-certificate-ready`, `scout-secret-issued` and `scout-lifetime` pass.

## Step 3: Fix drifter-cert

The cause is the missing Issuer, and the Certificate refers to it by name. Do not edit the Certificate. Create the Issuer in `outpost`. Save this as `issuer-outpost-issuer.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: outpost-issuer
  namespace: outpost
spec:
  selfSigned: {}
```

Apply it:

```sh
kubectl apply -f issuer-outpost-issuer.yaml
```

Then check the result. The Certificate needs no change, because cert-manager retries a Certificate that waits for its Issuer:

```sh
kubectl -n outpost get certificate drifter-cert
kubectl -n outpost get secret drifter-tls
```

Within a short time the Certificate is `READY` `True` and the Secret exists. If it is still `False` after a minute, read the events with `kubectl -n outpost describe certificate drifter-cert`. Run the grader without `--keep`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-040/module-02/labs/lab-01
```

All five checks pass. The check `drifter-certificate-ready` fails when the `issuerRef` was changed or when the Issuer was created in the wrong namespace. The check `scoped-issuers-only` fails when a ClusterIssuer exists or when something in the namespace `cert-manager` was scaled or edited.
