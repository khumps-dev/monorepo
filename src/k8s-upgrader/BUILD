load("@rules_rust//rust:defs.bzl", "rust_binary", "rust_test")

rust_binary(
    name = "k8s-upgrader",
    srcs = [
        "main.rs",
    ],
    compile_data = [
        "//config/kubernetes:nodes.toml",
    ],
    edition = "2021",
    deps = [
        "@crate_index//:anyhow",
        "@crate_index//:clap",
        "@crate_index//:lazy_static",
        "@crate_index//:toml",
        "@crate_index//:serde",
        "@crate_index//:futures",
        # "@crate_index//:reqwest",
        "@crate_index//:tokio",
    ],
)

rust_test(
    name = "k8s-upgrader-test",
    size = "large",
    crate = ":k8s-upgrader",
)
