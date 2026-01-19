# Changelog

All notable changes to KubeAgentiX Debug will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-01-19

### Added
- ASCII art branding banner displayed on shell startup
- Custom prompt with KubeAgentiX branding (`kubeagentix:path$`)
- `help-debug` command for quick reference of common debugging commands
- Useful shell aliases (ll, la, l, .., ...)
- Bash completion support enabled by default
- Version display in banner via `KUBEAGENTIX_VERSION` environment variable

### Changed
- Enhanced user experience with professional debug mode interface
- Shell now displays system info, hostname, and available tools on connect

## [1.0.1] - 2026-01-03

### Fixed
- GitHub Actions workflow improvements for GHCR publishing

## [1.0.0] - 2026-01-03

### Added
- Initial release of KubeAgentiX Debug container image
- Alpine 3.19 base image for minimal attack surface
- Bash shell with completion for enterprise-friendly debugging
- Non-root user execution (UID 65532) for Pod Security Standards compliance
- Networking tools: curl, wget, dig, nslookup, ping, ip, ss, nc, mtr, tcptraceroute
- Process inspection: ps, top, htop
- Filesystem utilities: ls, cat, stat, df, find, file, tree, less
- Data processing: jq, yq
- TLS/SSL debugging: openssl
- GitHub Actions workflow for multi-arch builds (amd64, arm64)
- Cosign keyless signing for supply chain security
- SBOM generation in SPDX and CycloneDX formats
- Reproducible builds with SOURCE_DATE_EPOCH
- Enterprise security-focused documentation

### Security
- SUID/SGID bits removed from all binaries
- Compatible with Pod Security Standards "restricted" profile
- No listening ports or inbound services
- No telemetry or outbound traffic by default
- Bash history disabled for security

[Unreleased]: https://github.com/kubeagentix/debug/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/kubeagentix/debug/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/kubeagentix/debug/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/kubeagentix/debug/releases/tag/v1.0.0
