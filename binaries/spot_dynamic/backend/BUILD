load("@crate_index//:defs.bzl", "aliases", "all_crate_deps")
load("@rules_rust//rust:defs.bzl", "rust_binary")

rust_binary(
    name = "backend",
    srcs = [
        "src/main.rs",
    ],
    edition = "2021",
    deps = [
        "@crate_index//:clap",
        "@crate_index//:oauth2",
        "@crate_index//:reqwest",
    ],
)
