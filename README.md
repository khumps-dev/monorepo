## Development
All development should be done within a vscode devcontainer. Simply launch the repo from within VSCode and it should recommend you to re-open in a container

## Directories
- `//.devcontainer` - configuration for the VSCode devcontainer (you should always open this repository within it)
- `//.vscode` - any additional settings for configuring VSCode
- `//kube-prometheus` - local installation and configuration of [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus) monitoring stack (may be moved into `//services/kube-prometheus`)
- `//services` - any third-party code that is running as a service
- `//terraform` - all infrastructure that has been stood up using [Terraform](https://www.terraform.io/)
- `//third_party` - externally vendored code that is used for building (not deployed directly)