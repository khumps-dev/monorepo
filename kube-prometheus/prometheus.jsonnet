local kp =
  (import 'kube-prometheus/main.libsonnet') +
  (import 'src/networkPolicy.jsonnet') +
  (import 'kube-prometheus/addons/managed-cluster.libsonnet') +
  // (import 'kube-prometheus/addons/all-namespaces.libsonnet') +
  // Uncomment the following imports to enable its patches
  // (import 'kube-prometheus/addons/anti-affinity.libsonnet') +
  // (import 'kube-prometheus/addons/managed-cluster.libsonnet') +
  // (import 'kube-prometheus/addons/node-ports.libsonnet') +
  // (import 'kube-prometheus/addons/static-etcd.libsonnet') +
  // (import 'kube-prometheus/addons/custom-metrics.libsonnet') +
  // (import 'kube-prometheus/addons/external-metrics.libsonnet') +
  // (import 'kube-prometheus/addons/pyrra.libsonnet') +
  {
    values+:: {
      common+: {
        namespace: 'monitoring',
      },
      prometheus+: {
        namespaces+: [
          'exporters',
          'knowhere',
          'longhorn-system',
          'plex',
        ],
      },
      alertmanager+: {
        config+: {
          global+: {
            slack_api_url: std.extVar('ALERTMANAGER_SLACK_URL'),
          },
          receivers+: [
            {
              name: 'Slack',
              slack_configs: [
                {
                  send_resolved: true,
                  username: 'Singularity Bot',
                },
              ],
            },
          ],
          route+: {
            routes+: [
              { receiver: 'Slack' },
            ],
          },
        },
      },
      blackboxExporter+:: {
        resources+: {
          requests+: { cpu: '30m' },
          limits+: { cpu: '60m' },
        },
      },
      nodeExporter+:: {
        resources+: {
          requests+: { cpu: '400m' },
          limits+: { cpu: '750m' },
        },
      },
      kubeStateMetrics+:: {
        kubeRbacProxyMain+:: {
          resources+: {
            limits+: { cpu: '160m' },
            requests+: { cpu: '80m' },
          },
        },
      },
      grafana+: {
        config+: {  // http://docs.grafana.org/installation/configuration/
          sections+: {
            'auth.anonymous': { enabled: true },
            'auth.github': {
              enabled: true,
              allow_sign_up: true,
              client_id: std.extVar('GRAFANA_OAUTH_ID'),
              client_secret: std.extVar('GRAFANA_OAUTH_SECRET'),
              allowed_organizations: ['khumps-dev'],
              allow_assign_grafana_admin: true,
              role_attribute_path: "[login==khumps] && 'GrafanaAdmin' || 'Viewer'",
            },
            server+: {
              root_url: 'https://grafana.khumps.dev',
            },
          },
        },
        datasources+: [
          {
            name: 'Alertmanager',
            type: 'alertmanager',
            jsonData: {
              implementation: 'prometheus',
            },
            access: 'proxy',
            url: 'http://alertmanager-operated.monitoring:9093',
          },
        ],
        folderDashboards+:: {
          Plex: {
            'plex-overview.json': (import 'src/dashboards/plex-overview.json'),
          },
          Networking: {
            'mikrotik-overview.json': (import 'src/dashboards/mikrotik/mikrotik-overview.json'),
          },
        },
      },
    },
    alertmanager+: {
      alertmanager+: {
        spec+: {
          externalUrl: 'https://alertmanager.khumps.dev',
        },
      },
    },
    prometheus+: {
      prometheus+: {
        spec+: {
          retention: '90d',
          storage: {
            volumeClaimTemplate: {
              apiVersion: 'v1',
              kind: 'PersistentVolumeClaim',
              spec: {
                accessModes: ['ReadWriteOnce'],
                resources: { requests: { storage: '100Gi' } },
                storageClassName: 'longhorn',
              },
            },
          },
          externalUrl: 'https://prometheus.khumps.dev',
        },
      },
    },
  };

{ 'setup/0namespace-namespace': kp.kubePrometheus.namespace } +
{
  ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor' && name != 'prometheusRule'), std.objectFields(kp.prometheusOperator))
} +
// { 'setup/pyrra-slo-CustomResourceDefinition': kp.pyrra.crd } +
// serviceMonitor and prometheusRule are separated so that they can be created after the CRDs are ready
{ 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ 'prometheus-operator-prometheusRule': kp.prometheusOperator.prometheusRule } +
{ 'kube-prometheus-prometheusRule': kp.kubePrometheus.prometheusRule } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['blackbox-exporter-' + name]: kp.blackboxExporter[name] for name in std.objectFields(kp.blackboxExporter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) } +
// { ['pyrra-' + name]: kp.pyrra[name] for name in std.objectFields(kp.pyrra) if name != 'crd' } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['kubernetes-' + name]: kp.kubernetesControlPlane[name] for name in std.objectFields(kp.kubernetesControlPlane) }
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) }
