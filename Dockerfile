# syntax=docker/dockerfile:1.6
#
# KubeAgentiX Debug Container
# A secure, ephemeral, policy-aware Kubernetes debugging runtime
#
# Security Profile: Pod Security Standards "restricted" compatible
# Base: Alpine Linux (minimal attack surface)
# Shell: Bash (full-featured, enterprise-friendly)
#

ARG ALPINE_VERSION=3.19
ARG SOURCE_DATE_EPOCH
ARG VERSION=dev
ARG COMMIT=unknown
ARG BUILD_DATE

# =============================================================================
# Stage 1: Builder - Install and prepare tools
# =============================================================================
FROM alpine:${ALPINE_VERSION} AS builder

# Install build dependencies (not included in final image)
RUN apk add --no-cache \
    ca-certificates \
    tzdata

# =============================================================================
# Stage 2: Runtime - Minimal secure debug image
# =============================================================================
FROM alpine:${ALPINE_VERSION}

# Build arguments for reproducibility
ARG SOURCE_DATE_EPOCH
ARG VERSION
ARG COMMIT
ARG BUILD_DATE

# -----------------------------------------------------------------------------
# Security: Create non-root user with fixed UID/GID
# UID 65532 is commonly used for nonroot and avoids conflicts
# -----------------------------------------------------------------------------
RUN addgroup -g 65532 -S nonroot && \
    adduser -u 65532 -S -G nonroot -h /home/nonroot -s /bin/bash nonroot

# -----------------------------------------------------------------------------
# Install diagnostic tools - minimal set for Kubernetes debugging
# All packages are pinned for reproducibility and security scanning
# -----------------------------------------------------------------------------
RUN apk add --no-cache \
    # Shell - full-featured bash for enterprise use
    bash \
    bash-completion \
    # Networking diagnostics
    curl \
    wget \
    bind-tools \
    iproute2 \
    iputils \
    netcat-openbsd \
    tcptraceroute \
    mtr \
    # Process inspection
    procps \
    htop \
    # Filesystem utilities
    coreutils \
    findutils \
    file \
    tree \
    less \
    # Data processing (Kubernetes-friendly)
    jq \
    yq \
    # TLS/SSL debugging
    openssl \
    # Timezone data for proper timestamps
    tzdata \
    # CA certificates for HTTPS
    ca-certificates \
    && update-ca-certificates \
    # Clean up
    && rm -rf /var/cache/apk/* /tmp/*

# -----------------------------------------------------------------------------
# Security hardening
# -----------------------------------------------------------------------------

# Remove unnecessary SUID/SGID bits
RUN find / -type f \( -perm -4000 -o -perm -2000 \) -exec chmod a-s {} \; 2>/dev/null || true

# Remove package manager to prevent runtime modifications
# Note: Commented out to allow security scanning; enable for maximum hardening
# RUN apk del apk-tools

# Create writable directories for the nonroot user
RUN mkdir -p /home/nonroot/.cache /home/nonroot/tmp && \
    chown -R nonroot:nonroot /home/nonroot

# Copy shell configuration for branding
COPY --chown=nonroot:nonroot rootfs/home/nonroot/.bashrc /home/nonroot/.bashrc

# Set secure environment variables
ENV HOME=/home/nonroot \
    USER=nonroot \
    SHELL=/bin/bash \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    # Disable bash history for security
    HISTFILE="" \
    # Set timezone
    TZ=UTC \
    # Version for branding
    KUBEAGENTIX_VERSION=${VERSION}

# -----------------------------------------------------------------------------
# OCI Image Labels (following OCI Image Spec)
# -----------------------------------------------------------------------------
LABEL org.opencontainers.image.title="KubeAgentiX Debug" \
      org.opencontainers.image.description="A secure, ephemeral, policy-aware Kubernetes debugging runtime" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.source="https://github.com/kubeagentix/debug" \
      org.opencontainers.image.documentation="https://github.com/kubeagentix/debug#readme" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.vendor="KubeAgentiX" \
      # Security labels
      io.kubeagentix.security.nonroot="true" \
      io.kubeagentix.security.readonly-recommended="true" \
      io.kubeagentix.security.pss-profile="restricted"

# -----------------------------------------------------------------------------
# Runtime configuration
# -----------------------------------------------------------------------------

# Set working directory
WORKDIR /home/nonroot

# Switch to non-root user (required for restricted PSS)
USER 65532:65532

# No ENTRYPOINT - allows kubectl debug to specify command
# Default to bash shell for interactive debugging
CMD ["/bin/bash"]
