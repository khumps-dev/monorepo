FROM mcr.microsoft.com/vscode/devcontainers/base:1.0-ubuntu22.04

# RUN export DEBIAN_FRONTEND=noninteractive

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
g++ \
git=1:2.34.1-1ubuntu1.5 \
libssl-dev=3.0.2-0ubuntu1.7 \
pkg-config \
python3 \
unzip \
wget \
zip \
zlib1g-dev

# Bazel
RUN wget https://github.com/bazelbuild/bazel/releases/download/6.0.0/bazel-6.0.0-linux-x86_64 -O bazel
RUN install bazel /usr/local/bin && rm bazel

# Buildifier
RUN wget https://github.com/bazelbuild/buildtools/releases/download/5.1.0/buildifier-linux-amd64 -O buildifier
RUN install buildifier /usr/local/bin && rm buildifier

# Buildozer
RUN wget https://github.com/bazelbuild/buildtools/releases/download/5.1.0/buildozer-linux-amd64 -O buildozer
RUN install buildozer /usr/local/bin && rm buildozer

# Terraform
RUN wget https://releases.hashicorp.com/terraform/1.3.6/terraform_1.3.6_linux_amd64.zip -O terraform
RUN unzip terraform -d /usr/local/bin
