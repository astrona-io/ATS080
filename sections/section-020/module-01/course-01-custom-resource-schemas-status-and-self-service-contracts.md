---
draft: true
exam_objectives:
- APIs for Self-Service Platforms (CRDs)
---
# Custom Resource Schemas, Status And Self-Service Contracts

A platform API lets users request and observe supported capabilities through a stable contract. Kubernetes custom resources are one way to implement that interface. A custom resource definition establishes a kind, scope, versions and schema. A controller or operator then interprets instances of that kind and performs the required work. The definition alone does not create arbitrary external infrastructure.

The specification describes intent. A database claim might request an approved service class, region and retention policy. The API should expose choices the platform intends to support rather than every provider-specific option. This reduces user complexity while preserving enough information to express meaningful needs. Defaults should be deliberate and versioned because they influence resulting behavior.

Status describes observed progress. Conditions can indicate that a request is accepted, awaiting a dependency, ready or failed under the controller's contract. The status should identify useful reasons without exposing credentials. An accepted API write is not proof that the database exists or can be used. The transition to readiness needs evidence from the implementing controller and provider.

Consider a custom resource named DatabaseClaim. The API server can validate its fields and store it. A controller reads the claim, checks policy and requests a supported database from an external provider. Provider denial leaves the claim present but not ready. That distinction gives users a way to understand pending work rather than receiving a misleading synchronous success message.

Schema validation limits unsupported inputs. Required fields, types and constrained choices can catch errors early. Additional validation can express relationships among fields where supported. Authorization separately controls who may create, read or update resources. A valid request can still be forbidden for a particular tenant, so shape and permission are different contracts.

Tenant boundaries should be explicit. Namespaced resources can support organizational separation, but controllers must use identities and policies that preserve intended access. A user should not be able to select another tenant's secret or external account through an unconstrained reference. API abstraction should not become a route for exercising the controller's broader authority.

Versioning protects consumers from silent semantic change. Adding an optional field can differ from renaming a required one or changing a default. Served and stored versions, conversion behavior and controller compatibility need deliberate handling. A portal and automation client can both depend on the same API even when they present different interfaces. The contract belongs to all of them.

Deletion is part of the API lifecycle. Removing a claim can mean deleting an external resource, retaining it or initiating a handoff according to policy. Finalizers can allow a controller to perform required cleanup before Kubernetes completes deletion. They are not magic guarantees; a failed controller can leave deletion pending. Persistent-data consequences must be visible and supported.

Connection information and secrets need controlled delivery. Status can identify a reference to an approved secret rather than expose the credential itself. Reading the claim should not automatically grant access to all external accounts. Audit should connect the requester, desired version and resulting operation so sensitive provisioning is accountable.

The useful API design lets users express intent, observe progress and understand failure without operating every provider detail. Students should distinguish the schema, authorization, controller and external provider boundaries when explaining why a request is accepted but not yet usable.

A fictional platform resource can express limited user intent:

```yaml
apiVersion: platform.example/v1alpha1
kind: DatabaseClaim
metadata:
  name: ordering-development
spec:
  serviceClass: development-small
  retentionPolicy: retain
```

This is an illustrative API shape, not an installed kind. A CRD must define its accepted schema and a controller must implement its meaning. The retention choice only has operational effect if that implementation supports and enforces it.

## Common pitfalls

> [!WARNING]
> A CRD is a schema contract, not the whole implementation. Validate references and tenant scope as well as field types. Accepted intent, ready status and external access are distinct, and deletion must account for persistent-resource policy.
