FROM ubuntu:jammy-20221130

RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && echo "$SNIPPET" >> "/root/.bashrc"

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    curl \
    g++ \
    git \
    iputils-ping \
    jsonnet \
    libssl-dev \
    netcat \
    pkg-config \
    python3 \
    unzip \
    wget \
    zip \
    zlib1g-dev

# Terraform
RUN wget https://releases.hashicorp.com/terraform/1.3.6/terraform_1.3.6_linux_amd64.zip -O terraform
RUN unzip terraform -d /usr/local/bin

# Github CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
RUN chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list

# Kubectl
RUN wget https://dl.k8s.io/release/v1.26.0/bin/linux/amd64/kubectl
RUN install kubectl /usr/local/bin && rm kubectl

# jsonnet bundler
RUN wget https://github.com/jsonnet-bundler/jsonnet-bundler/releases/download/v0.5.1/jb-linux-amd64 -O jb
RUN install jb /usr/local/bin && rm jb

# gojsontoyaml
RUN wget https://github.com/brancz/gojsontoyaml/releases/download/v0.1.0/gojsontoyaml_0.1.0_linux_amd64.tar.gz -O gojsontoyaml.tar.gz
RUN tar xzf gojsontoyaml.tar.gz gojsontoyaml && install gojsontoyaml /usr/local/bin && rm gojsontoyaml

# Rust (for tooling)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
    -y --no-modify-path --default-toolchain 1.73.0 --component clippy,rust-src,rustfmt
RUN echo "source $HOME/.cargo/env" >> /root/.bashrc

# Helm
RUN wget https://get.helm.sh/helm-v3.11.2-linux-amd64.tar.gz -O helm.tar.gz
RUN tar xzf helm.tar.gz --strip-components 1 linux-amd64/helm && install helm /usr/local/bin && rm helm

# Skaffold
RUN curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
RUN install skaffold /usr/local/bin/

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    gh \
    locales \
    jq

ENV LC_ALL="en_US.UTF-8"
ENV LC_CTYPE="en_US.UTF-8"
ENV EDITOR="code --wait"
RUN dpkg-reconfigure locales
