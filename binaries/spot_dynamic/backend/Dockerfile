FROM rust:1.66.0-bullseye

ENV HOME=/home/root
WORKDIR /home/root/workspace

COPY /Cargo.toml .
COPY /Cargo.lock .

COPY /libraries ./libraries
COPY /binaries/spot_dynamic/backend ./binaries/spot_dynamic/backend

RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/home/root/workspace/target \
    cargo build --release --bin spot_dynamic_backend