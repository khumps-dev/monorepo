Follow https://longhorn.io/docs/1.4.1/deploy/install/install-with-helm/

devcontainer already has helm installed

Ensure you have the longhorn repo installed:

```bash
helm repo add longhorn https://charts.longhorn.io
helm repo update
```

`helm upgrade --install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace --version 1.5.1 --values values.yaml` pointing at the singularity kubernetes context