load("@rules_rust//rust:defs.bzl", "rust_binary")

rust_binary(
    name = "deploy",
    srcs = [
        "deploy.rs",
    ],
    compile_data = [
        "@prometheus_crds//file",
    ],
    edition = "2021",
    deps = [
        "@crate_index//:anyhow",
        "@crate_index//:clap",
        "@crate_index//:oauth2",
        "@crate_index//:reqwest",
    ],
)
