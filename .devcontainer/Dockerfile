FROM ubuntu:jammy-20221130

RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && echo "$SNIPPET" >> "/root/.bashrc"

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    curl \
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

# Github CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
RUN chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list

# Sapling CLI
RUN wget https://github.com/facebook/sapling/releases/download/0.2.20230124-180750-hf8cd450a/sapling_0.2.20230124-180750-hf8cd450a_amd64.Ubuntu22.04.deb -O sapling.deb
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt install -y ./sapling.deb && rm sapling.deb

# Kubectl
RUN wget https://dl.k8s.io/release/v1.26.0/bin/linux/amd64/kubectl
RUN install kubectl /usr/local/bin && rm kubectl

# ibazel
RUN wget https://github.com/bazelbuild/bazel-watcher/releases/download/v0.21.4/ibazel_linux_amd64 -O ibazel
RUN install ibazel /usr/local/bin && rm ibazel

# jsonnet

# jsonnet bundler
RUN wget https://github.com/jsonnet-bundler/jsonnet-bundler/releases/download/v0.5.1/jb-linux-amd64 -O jb
RUN install jb /usr/local/bin && rm jb

# gojsontoyaml
RUN wget https://github.com/brancz/gojsontoyaml/releases/download/v0.1.0/gojsontoyaml_0.1.0_linux_amd64.tar.gz -o gojsontoyaml.tar.gz
RUN tar xvf gojsontoyaml.tar.gz gojsontoyaml && install gojsontoyaml /usr/local/bin && rm gojsontoyaml

# Rust (for tooling)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
    -y --no-modify-path --default-toolchain 1.65.0 --profile minimal --component clippy,rust-src,rustfmt

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    gh \
    locales \
    jq

ENV LC_ALL="en_US.UTF-8"
ENV LC_CTYPE="en_US.UTF-8"
ENV EDITOR="code --wait"
RUN dpkg-reconfigure locales
