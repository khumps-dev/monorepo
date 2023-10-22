{
  global+: {
    slack_api_url: std.extVar('ALERTMANAGER_SLACK_URL'),
  },
  receivers: [
    {
      name: 'Default',
      slack_configs: [
        {
          send_resolved: true,
          http_config:
            {
              follow_redirects: true,
              enable_http2: true,
            },
          username: 'Singularity Bot',
          color: '{{ if eq .Status "firing" }}danger{{ else }}good{{ end }}',
          title: '{{ template "slack.default.title" . }}',
          title_link: '{{ template "slack.default.titlelink" . }}',
          pretext: '{{ template "slack.default.pretext" . }}',
          text: '{{ template "slack.default.text" . }}',
          short_fields: false,
          footer: '{{ template "slack.default.footer" . }}',
          fallback: '{{ template "slack.default.fallback" . }}',
          callback_id: '{{ template "slack.default.callbackid" . }}',
          icon_emoji: '{{ template "slack.default.iconemoji" . }}',
          icon_url: '{{ template "slack.default.iconurl" . }}',
          link_names: false,
        },
      ],
    },
    {
      name: 'Watchdog',
    },
    {
      name: 'null',
    },
  ],
  route: {
    receiver: 'Default',
    group_wait: '30s',
    group_by: ['namespace'],
    group_interval: '5m',
    repeat_interval: '12h',
    routes: [
      {
        receiver: 'Watchdog',
        matchers: ['alertname=Watchdog'],
      },
      {
        receiver: 'null',
        matchers: ['alertname=InfoInhibitor'],
      },
    ],
  },
  inhibit_rules: [
    {
      source_matchers: ['severity=critical'],
      target_matchers: ['severity=~warning|info'],
      equal:
        [
          'namespace',
          'alertname',
        ],
    },
    {
      source_matchers: ['severity=warning'],
      target_matchers: ['severity=info'],
      equal:
        [
          'namespace',
          'alertname',
        ],
    },
    {
      source_matchers: ['alertname=InfoInhibitor'],
      target_matchers: ['severity=info'],
      equal: ['namespace'],
    },
  ],
}
