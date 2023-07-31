load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

# ----- Rust -----
http_archive(
    name = "rules_rust",
    sha256 = "9d04e658878d23f4b00163a72da3db03ddb451273eb347df7d7c50838d698f49",
    urls = ["https://github.com/bazelbuild/rules_rust/releases/download/0.26.0/rules_rust-v0.26.0.tar.gz"],
)

load("@rules_rust//rust:repositories.bzl", "rules_rust_dependencies", "rust_register_toolchains")

rules_rust_dependencies()

rust_register_toolchains(
    # Versions must match rustup install in //.devcontainer/Dockerfile
    versions = [
        "1.65.0",
    ],
)

load("@rules_rust//crate_universe:defs.bzl", "crate", "crates_repository")

crates_repository(
    name = "crate_index",
    annotations = {},
    cargo_lockfile = "//third_party/cargo:Cargo.Bazel.lock",
    lockfile = "//third_party/cargo:Cargo.lock",
    packages = {
        "anyhow": crate.spec(
            version = "1.0.68",
        ),
        "clap": crate.spec(
            features = [
                "derive",
            ],
            version = "4.0.29",
        ),
        "oauth2": crate.spec(
            version = "4.3.0",
        ),
        "reqwest": crate.spec(
            version = "0.11.13",
        ),
        "tokio": crate.spec(
            features = ["full"],
            version = "1.29.1",
        ),
    },
)

load(
    "@crate_index//:defs.bzl",
    "crate_repositories",
)

crate_repositories()

load("@rules_rust//tools/rust_analyzer:deps.bzl", "rust_analyzer_dependencies")

rust_analyzer_dependencies()

# Prometheus CRDs
http_file(
    name = "prometheus_crds",
    sha256 = "e049a2a2f5eb4f5d021d09e6402b3d2cf4cc27a3c720e71477afff20d2a2eb49",
    url = "https://github.com/prometheus-operator/prometheus-operator/releases/download/v0.62.0/bundle.yaml",
)
