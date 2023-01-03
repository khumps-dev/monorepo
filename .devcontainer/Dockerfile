FROM ubuntu:lunar-20221216

RUN export DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
g++ \
pkg-config \
python3 \
unzip \
wget \
zip \
zlib1g-dev

# Bazel
RUN wget https://github.com/bazelbuild/bazel/releases/download/6.0.0/bazel-6.0.0-linux-x86_64 -O bazel
RUN install ./bazel /usr/local/bin && rm ./bazel

# Terraform
RUN wget https://releases.hashicorp.com/terraform/1.3.6/terraform_1.3.6_linux_amd64.zip -O terraform
RUN install ./terraform /usr/local/bin && rm ./terraform

# Rust

RUN apt-get update
RUN apt-get install -y \
git=1:2.37.2-1ubuntu1 \
libssl-dev=3.0.5-2ubuntu2