// CryptoClaw Multi-Architecture Docker Build Configuration
// Usage: docker buildx bake [target] [flags]
//
// Examples:
//   docker buildx bake                    # Build all targets for current platform
//   docker buildx bake --set *.platform=linux/amd64,linux/arm64  # Multi-arch build
//   docker buildx bake cryptoclaw         # Build only cryptoclaw image
//   docker buildx bake --push             # Build and push to registry
//   docker buildx bake --set *.output=type=docker  # Load to local Docker

// Variables
variable "REGISTRY" {
  default = "cryptoclaw"
}

variable "VERSION" {
  default = "1.0.0"
}

variable "GIT_SHA" {
  default = ""
}

// Target: CryptoClaw Gateway
target "cryptoclaw" {
  context    = "./gateway"
  dockerfile = "Dockerfile"
  
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
  
  tags = [
    "${REGISTRY}/cryptoclaw:latest",
    "${REGISTRY}/cryptoclaw:${VERSION}",
    GIT_SHA != "" ? "${REGISTRY}/cryptoclaw:sha-${GIT_SHA}" : "${REGISTRY}/cryptoclaw:dev"
  ]
  
  labels = {
    "org.opencontainers.image.title"       = "CryptoClaw Gateway"
    "org.opencontainers.image.description" = "AI-Powered Crypto Trading Assistant"
    "org.opencontainers.image.version"     = VERSION
    "org.opencontainers.image.vendor"      = "CryptoClaw Team"
    "org.opencontainers.image.source"      = "https://github.com/franklili3/CryptoClaw"
    "org.opencontainers.image.revision"    = GIT_SHA
  }
  
  cache-from = ["type=registry,ref=${REGISTRY}/cryptoclaw:buildcache"]
  cache-to   = ["type=registry,ref=${REGISTRY}/cryptoclaw:buildcache,mode=max"]
}

// Target: Development build (single platform, faster)
target "cryptoclaw-dev" {
  inherits  = ["cryptoclaw"]
  platforms = ["linux/amd64"]
  target    = "development"
  tags      = ["${REGISTRY}/cryptoclaw:dev"]
  output    = ["type=docker"]
}

// Target: Production build with all optimizations
target "cryptoclaw-prod" {
  inherits  = ["cryptoclaw"]
  target    = "production"
  output    = ["type=registry"]
}

// Group: Build all images
group "default" {
  targets = ["cryptoclaw"]
}

// Group: Build and push all production images
group "release" {
  targets = ["cryptoclaw-prod"]
}

// Group: Local development build
group "dev" {
  targets = ["cryptoclaw-dev"]
}
