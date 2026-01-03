# KubeAgentiX Debug - Build Automation
# =====================================

IMAGE_NAME ?= kubeagentix-debug
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT ?= $(shell git rev-parse HEAD 2>/dev/null || echo "unknown")
BUILD_DATE ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
PLATFORMS ?= linux/amd64,linux/arm64

.PHONY: all build build-multi test validate clean help

# Default target
all: build validate

# Build for local architecture
build:
	@echo "Building $(IMAGE_NAME):$(VERSION)..."
	docker build \
		--build-arg VERSION=$(VERSION) \
		--build-arg COMMIT=$(COMMIT) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		-t $(IMAGE_NAME):$(VERSION) \
		-t $(IMAGE_NAME):latest \
		.

# Build for multiple architectures
build-multi:
	@echo "Building $(IMAGE_NAME):$(VERSION) for $(PLATFORMS)..."
	docker buildx build \
		--platform $(PLATFORMS) \
		--build-arg VERSION=$(VERSION) \
		--build-arg COMMIT=$(COMMIT) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		-t $(IMAGE_NAME):$(VERSION) \
		-t $(IMAGE_NAME):latest \
		--load \
		.

# Run security validation
validate:
	@echo "Running security validation..."
	@echo ""
	@echo "1. Checking user (should be UID 65532):"
	@docker run --rm $(IMAGE_NAME):$(VERSION) id
	@echo ""
	@echo "2. Checking SUID/SGID binaries (should be 0):"
	@docker run --rm $(IMAGE_NAME):$(VERSION) sh -c "find / -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | wc -l | tr -d ' '"
	@echo ""
	@echo "3. Verifying bash:"
	@docker run --rm $(IMAGE_NAME):$(VERSION) bash --version | head -1
	@echo ""
	@echo "4. Essential tools:"
	@docker run --rm $(IMAGE_NAME):$(VERSION) sh -c "for t in curl dig ping ip ss nc mtr jq yq openssl htop ps; do which \$$t; done"
	@echo ""
	@echo "5. Image size:"
	@docker images $(IMAGE_NAME):$(VERSION) --format "{{.Size}}"
	@echo ""
	@echo "✅ Validation complete"

# Interactive test shell
test:
	@echo "Starting interactive debug session..."
	docker run --rm -it $(IMAGE_NAME):$(VERSION)

# Save image as tar for release
save:
	@echo "Saving $(IMAGE_NAME):$(VERSION) to $(IMAGE_NAME).tar.gz..."
	docker save $(IMAGE_NAME):$(VERSION) | gzip > $(IMAGE_NAME).tar.gz
	@echo "Generating checksum..."
	shasum -a 256 $(IMAGE_NAME).tar.gz > $(IMAGE_NAME).tar.gz.sha256
	@cat $(IMAGE_NAME).tar.gz.sha256

# Clean up
clean:
	@echo "Cleaning up..."
	-docker rmi $(IMAGE_NAME):$(VERSION) 2>/dev/null
	-docker rmi $(IMAGE_NAME):latest 2>/dev/null
	-rm -f $(IMAGE_NAME).tar.gz $(IMAGE_NAME).tar.gz.sha256

# Help
help:
	@echo "KubeAgentiX Debug - Build Targets"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build        Build image for local architecture"
	@echo "  build-multi  Build multi-arch image (amd64, arm64)"
	@echo "  validate     Run security validation checks"
	@echo "  test         Start interactive debug session"
	@echo "  save         Save image as tar.gz with checksum"
	@echo "  clean        Remove built images and artifacts"
	@echo "  help         Show this help message"
	@echo ""
	@echo "Variables:"
	@echo "  IMAGE_NAME   Image name (default: kubeagentix-debug)"
	@echo "  VERSION      Version tag (default: git describe)"
	@echo "  PLATFORMS    Build platforms (default: linux/amd64,linux/arm64)"
