load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# ----- Rust -----
http_archive(
    name = "rules_rust",
    sha256 = "5c2b6745236f8ce547f82eeacbbcc81d736734cc8bd92e60d3e3cdfa6e167bb5",
    urls = ["https://github.com/bazelbuild/rules_rust/releases/download/0.15.0/rules_rust-v0.15.0.tar.gz"],
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
        "clap": crate.spec(
            version = "4.0.29",
        ),
        "oauth2": crate.spec(
            version = "4.3.0",
        ),
        "reqwest": crate.spec(
            version = "0.11.13",
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
