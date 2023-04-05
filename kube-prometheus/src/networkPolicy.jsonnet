local policy = {
  spec+: {
    ingress+: [
      {
        from: [
          {
            podSelector: {
              matchLabels: {
                app: 'cloudflare-tunnel',
              },
            },
          },
          {
            namespaceSelector: {
              matchLabels: {
                'kubernetes.io/metadata.name': 'kube-system',
              },
            },
          },
        ],
        ports: [
          {
            port: 9090,
            protocol: 'TCP',
          },
        ],
      },
    ],
  },
};

local grafanaPolicy = policy {
  spec+: {
    ingress+: [
      {
        ports: [
          {
            port: 3000,
            protocol: 'TCP',
          },
        ],
      },
    ],
  },
};

local alertmanagerPolicy = policy {
  spec+: {
    ingress+: [
      {
        ports: [
          {
            port: 9093,
            protocol: 'TCP',
          },
        ],
      },
    ],
  },
};

{
  prometheus+: {
    networkPolicy+: policy,
  },
  grafana+: {
    networkPolicy+: grafanaPolicy,
  },
  alertmanager+: {
    networkPolicy+: alertmanagerPolicy,
  },
}
