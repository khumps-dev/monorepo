{
  values+:: {
    blackboxExporter+:: {
      resources+: {
        requests+: { cpu: '75m' },
        limits+: { cpu: '200m' },
      },
    },
    nodeExporter+:: {
      resources+: {
        requests+: { cpu: '400m' },
        limits+: { cpu: '750m' },
      },
      kubeRbacProxy+:: {
        resources+: {
          requests+: { cpu: '20m' },
          limits+: { cpu: '40m' },
        },
      },
    },
    kubeStateMetrics+:: {
      kubeRbacProxyMain+:: {
        resources+: {
          limits+: { cpu: '160m' },
          requests+: { cpu: '80m' },
        },
      },
      kubeRbacProxySelf+:: {
        resources+: {
          limits+: { cpu: '160m' },
          requests+: { cpu: '80m' },
        },
      },
    },
    grafana+:: {
      resources+: {
        requests+: {
          cpu: '150m',
        },
        limits+: {
          cpu: '400m',
        },
      },
    },
  },
}
