load("@rules_rust//rust:defs.bzl", "rust_binary")

rust_binary(
    name = "plex-pruner",
    srcs = [
        "main.rs",
    ],
    edition = "2021",
    deps = [
        "@crate_index//:anyhow",
        "@crate_index//:reqwest",
        "@crate_index//:serde",
        "@crate_index//:serde_json",
    ],
)
