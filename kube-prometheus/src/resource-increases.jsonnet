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
          requests+: { cpu: '40m' },
          limits+: { cpu: '80m' },
        },
      },
    },
    kubeStateMetrics+:: {
      kubeRbacProxyMain+:: {
        resources+: {
          limits+: { cpu: '320m' },
          requests+: { cpu: '160m' },
        },
      },
      kubeRbacProxySelf+:: {
        resources+: {
          limits+: { cpu: '320m' },
          requests+: { cpu: '160m' },
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
