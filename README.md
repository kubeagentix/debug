# KubeAgentiX Debug

**A secure, ephemeral, policy-aware Kubernetes debugging runtime**

---

## Quick Start

```bash
# Pull from GitHub Container Registry
docker pull ghcr.io/kubeagentix/debug:latest

# Use with kubectl debug
kubectl debug mypod -it --image=ghcr.io/kubeagentix/debug:latest

# Target a specific container (recommended)
kubectl debug mypod -it --image=ghcr.io/kubeagentix/debug:latest --target=mycontainer
```

---

## Executive Summary

KubeAgentiX Debug is a purpose-built container image for **interactive troubleshooting of Kubernetes workloads**. It is designed for enterprise environments with strict security, audit, and compliance requirements.

| Security Control | Status |
|-----------------|--------|
| Non-root execution | ✅ Enforced (UID 65532) |
| Pod Security Standards | ✅ "restricted" compatible |
| Privileged mode | ❌ Not required |
| Host namespaces | ❌ Not required |
| SUID/SGID binaries | ✅ Removed |
| Package managers | ✅ Present but optional removal |
| Supply chain signing | ✅ Cosign keyless signatures |
| SBOM | ✅ SPDX & CycloneDX included |

---

## Design Principles

### 1. Ephemeral by Default
- No persistence mechanisms
- No background daemons
- No long-running services
- Container destroyed when session ends

### 2. Explicit Invocation
- Launched only via authenticated `kubectl debug` commands
- Honors existing RBAC, PodSecurity, and Admission Controls
- Fully visible in Kubernetes audit logs

### 3. Least Privilege
- Runs as non-root user (UID 65532)
- No elevated capabilities required
- Compatible with read-only root filesystem

### 4. No Side Effects
- Does not mutate application containers
- Does not inject code or agents
- Does not modify workloads

### 5. Auditability
- All invocations logged via Kubernetes API
- Traceable to authenticated identity
- Visible in `kubectl describe`, events, and audit logs

---

## Security Model

### Identity & Access Control

All access is governed by **Kubernetes RBAC**. The image itself does not authenticate users. Operators must have permission to:

```yaml
# Required RBAC for ephemeral containers
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: debug-operator
rules:
- apiGroups: [""]
  resources: ["pods/ephemeralcontainers"]
  verbs: ["update", "patch"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
```

### Default Security Posture

| Capability | Default | Notes |
|-----------|---------|-------|
| Run as root | ❌ No | UID 65532 enforced |
| Privileged mode | ❌ No | Not required |
| Host PID namespace | ❌ No | Not required |
| Host network | ❌ No | Not required |
| Host filesystem | ❌ No | Not required |
| NET_ADMIN | ❌ No | Not required |
| SYS_ADMIN | ❌ No | Not required |
| SYS_PTRACE | ❌ No | Optional for strace |

### Pod Security Standards Compatibility

KubeAgentiX Debug is compatible with:

| Standard | Compatibility |
|----------|---------------|
| **restricted** | ✅ Full compatibility |
| **baseline** | ✅ Full compatibility |
| **privileged** | ✅ Full compatibility |

The image requires **no exemptions** for default usage in `restricted` namespaces.

### Recommended Security Context

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 65532
  runAsGroup: 65532
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  seccompProfile:
    type: RuntimeDefault
  capabilities:
    drop:
      - ALL
```

---

## Image Contents

### Included Tools

The image contains operator-essential diagnostics only:

| Category | Tools |
|----------|-------|
| **Shell** | `bash`, `bash-completion` |
| **Network** | `curl`, `wget`, `dig`, `nslookup`, `ping`, `ip`, `ss`, `nc`, `mtr`, `tcptraceroute` |
| **Process** | `ps`, `top`, `htop` |
| **Filesystem** | `ls`, `cat`, `stat`, `df`, `find`, `file`, `tree`, `less` |
| **Data** | `jq`, `yq` |
| **TLS/SSL** | `openssl` |

### Intentionally Excluded

- ❌ Compilers and build tools
- ❌ SSH servers
- ❌ Background services
- ❌ Persistence layers
- ❌ Kernel modules

This reduces attack surface and abuse potential.

---

## Usage

### Attach to a Running Pod

```bash
kubectl debug mypod -it --image=kubeagentix/debug
```

### Ephemeral Container (Recommended)

```bash
kubectl debug mypod -it --image=kubeagentix/debug --target=mycontainer
```

This shares the network and PID namespace with the target container for effective debugging.

### Pod Clone for Safe Debugging

```bash
kubectl debug mypod -it --copy-to=my-debug-session --image=kubeagentix/debug
```

Creates an isolated copy for investigation without affecting production.

### Node Debugging (Requires Elevated Privileges)

```bash
kubectl debug node/mynode -it --image=kubeagentix/debug
```

> ⚠️ Node debugging requires cluster-admin privileges and should follow incident response procedures.

---

## Network Behavior

- ❌ No listening ports
- ❌ No inbound services
- ❌ No outbound traffic unless operator-initiated
- ❌ No telemetry by default

All network activity is explicit and operator-controlled.

---

## Supply Chain Security

### Image Signing

All images are signed using [Cosign](https://github.com/sigstore/cosign) with keyless signatures via GitHub OIDC.

**Verify the image signature:**

```bash
cosign verify ghcr.io/kubeagentix/debug:latest \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp="https://github.com/kubeagentix/debug"
```

### Software Bill of Materials (SBOM)

Every image includes an attached SBOM attestation:

```bash
# Verify and extract SBOM attestation
cosign verify-attestation ghcr.io/kubeagentix/debug:latest \
  --type spdxjson \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp="https://github.com/kubeagentix/debug"
```

### Reproducible Builds

Builds are reproducible using `SOURCE_DATE_EPOCH`:

```bash
# Reproduce the exact build
git checkout <commit>
docker buildx build \
  --build-arg SOURCE_DATE_EPOCH=<epoch> \
  --build-arg VERSION=<version> \
  --build-arg COMMIT=<commit> \
  -t ghcr.io/kubeagentix/debug:local .
```

---

## Compliance Considerations

KubeAgentiX Debug is suitable for environments subject to:

| Framework | Suitability | Notes |
|-----------|-------------|-------|
| **SOC 2** | ✅ Suitable | Audit logging, access controls |
| **ISO 27001** | ✅ Suitable | Least privilege, no persistence |
| **HIPAA** | ✅ Suitable | With cluster-level controls |
| **PCI-DSS** | ✅ Suitable | With RBAC restrictions |
| **FedRAMP** | ✅ Suitable | Supply chain controls, SBOM |

> Final compliance depends on **cluster policy enforcement**, not the image itself.

---

## Policy Integration

### OPA/Gatekeeper

```rego
package kubernetes.admission

deny[msg] {
  input.request.kind.kind == "Pod"
  container := input.request.object.spec.ephemeralContainers[_]
  not startswith(container.image, "kubeagentix/debug:")
  msg := "Only approved debug images are allowed"
}
```

### Kyverno

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: restrict-debug-images
spec:
  validationFailureAction: enforce
  rules:
  - name: check-debug-image
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Only kubeagentix/debug images are allowed for ephemeral containers"
      pattern:
        spec:
          ephemeralContainers:
          - image: "kubeagentix/debug:*"
```

---

## Lifecycle & Cleanup

- Debug containers are **ephemeral**
- Automatically removed when session ends
- No data persists across restarts
- No artifacts remain after termination

For incident investigations requiring isolation:

```bash
kubectl debug mypod --copy-to=incident-$(date +%s) --image=kubeagentix/debug
```

---

## Logging & Auditing

All activity is:

1. **Visible** in Kubernetes audit logs
2. **Traceable** to a Kubernetes identity
3. **Bound** to the debug session lifecycle

Example audit log entry:

```json
{
  "kind": "Event",
  "apiVersion": "audit.k8s.io/v1",
  "level": "RequestResponse",
  "verb": "patch",
  "user": {"username": "admin@example.com"},
  "objectRef": {
    "resource": "pods",
    "subresource": "ephemeralcontainers",
    "name": "mypod",
    "namespace": "production"
  }
}
```

---

## Building Locally

### Prerequisites

- Docker with BuildKit support
- (Optional) QEMU for multi-arch builds

### Build Commands

```bash
# Single architecture
docker build -t kubeagentix-debug:local .

# Multi-architecture
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t kubeagentix-debug:local \
  --load .
```

### Build Arguments

| Argument | Description |
|----------|-------------|
| `VERSION` | Semantic version (e.g., `1.0.0`) |
| `COMMIT` | Git commit SHA |
| `BUILD_DATE` | ISO 8601 timestamp |
| `SOURCE_DATE_EPOCH` | Unix timestamp for reproducibility |

---

## Governance

### Recommended Access Policies

- Restrict usage to approved roles: **SRE**, **Platform**, **On-Call**
- Production usage should follow incident response procedures
- Define clear policies for debug session duration limits
- Enable audit logging for all debug activities

### Session Time Limits

Consider implementing time limits via admission controllers:

```yaml
# Example: Kyverno policy for session limits
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: debug-session-ttl
spec:
  rules:
  - name: add-ttl-annotation
    match:
      resources:
        kinds:
        - Pod
    mutate:
      patchStrategicMerge:
        metadata:
          annotations:
            debug.kubeagentix.io/expires: "{{ time.Now().Add(time.Hour).Format(time.RFC3339) }}"
```

---

## Summary for Security Review

**KubeAgentiX Debug:**

| Claim | Verification |
|-------|--------------|
| Does not bypass Kubernetes security | ✅ Uses native `kubectl debug` |
| Does not introduce persistent agents | ✅ Ephemeral by design |
| Does not expand privileges silently | ✅ Requires explicit flags |
| Does not run continuously | ✅ Session-bound lifecycle |
| Does not modify workloads | ✅ Read-only operations |
| Is fully auditable | ✅ Kubernetes audit logs |
| Has verified supply chain | ✅ Signed artifacts, SBOM |

**If your organization approves `kubectl debug`, KubeAgentiX Debug requires no additional security review.**

---

## Support

- **Issues:** [GitHub Issues](https://github.com/kubeagentix/debug/issues)
- **Security:** security@kubeagentix.io
- **Documentation:** This README

---

## License

Apache License 2.0 - See [LICENSE](LICENSE) for details.
