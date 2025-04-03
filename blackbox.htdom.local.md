# blackbox.htdom.local

In dieser Note werden nur die Configs hinzugefügt, die derzeit auf dem Raspberry Pi laufen. 

> https://blackbox.htdom.local

<a href="images/blackbox.jpg" target="_blank"><img src="images/blackbox.jpg" alt="Blackbox Exporter" title="Blackbox Exporter" width="460" height="230" /></a>

---
#### Inhaltsverzeichnis

* [Ordner-Struktur](#ordner-struktur---top-of-page)
	* [~/docker/blackbox/config/blackbox.yml](#dockerblackboxconfigblackboxyml---top-of-page)
	* [~/docker/docker-compose.yaml](#dockerdocker-composeyaml---top-of-page)
	* [~/docker/caddy/config/Caddyfile](#dockercaddyconfigcaddyfile---top-of-page)
* [blackbox.yml - Beispiele für weitere E2E Tests](#blackboxyml---beispiele-für-weitere-e2e-tests---top-of-page)
* [prometheus.yaml - Beispiele für weitere E2E Tests](#prometheusyaml---beispiele-für-weitere-e2e-tests---top-of-page)
* [Beispiel Checks](#beispiel-checks---top-of-page)
---

#### Ordner-Struktur - [Top of Page](#inhaltsverzeichnis)
```bash
sudo vi /etc/hosts
# <Docker-Host IP-Adresse> blackbox.htdom.local

mkdir -p ~/docker/blackbox/config
```

#### ~/docker/blackbox/config/blackbox.yml - [Top of Page](#inhaltsverzeichnis)
```yaml
modules: 
  http_2xx:
    prober: http
    timeout: 10s
    http:
      ip_protocol_fallback: false
      no_follow_redirects: false
      fail_if_not_ssl: false
      preferred_ip_protocol: ip4
      method: GET
      valid_status_codes: []
      valid_http_versions: 
        - HTTP/1.1
        - HTTP/2.0
      tls_config:
        insecure_skip_verify: true
  tcp_connect: 
    prober: tcp
    timeout: 10s
    tcp: 
      ip_protocol_fallback: false
      preferred_ip_protocol: ip4
      tls_config: 
        insecure_skip_verify: true
  ssh_banner:
    prober: tcp
    timeout: 10s
    tcp:
      query_response:
      - expect: "^SSH-2.0-"
  icmp:
    prober: icmp
    timeout: 5s
    icmp:
      preferred_ip_protocol: ip4
      ip_protocol_fallback: true
```

#### ~/docker/docker-compose.yaml - [Top of Page](#inhaltsverzeichnis)
```yaml
  blackbox:
    image: docker.io/prom/blackbox-exporter:v0.26.0
    container_name: blackbox
    hostname: blackbox.${FQDN}
    network_mode: "host"
    restart: always
    volumes:
      - "./blackbox/config/blackbox.yml:/etc/blackbox/blackbox.yml:ro"
    command:
      - '--config.file=/etc/blackbox/blackbox.yml'
    ports:
      - "9115:9115"
```

#### ~/docker/caddy/config/Caddyfile - [Top of Page](#inhaltsverzeichnis)
```html
blackbox.htdom.local {
  reverse_proxy http://blackbox.htdom.local:9115
  tls internal
}
```

#### blackbox.yml - Beispiele für weitere E2E Tests - [Top of Page](#inhaltsverzeichnis)
```yaml
modules:
  http_2xx:
    prober: http
    timeout: 10s
    http:
      valid_http_versions:
        - HTTP/1.1
        - HTTP/2.0
      preferred_ip_protocol: ip4
      method: GET
      tls_config:
        insecure_skip_verify: true
      follow_redirects: true
      enable_http2: true
    tcp:
      ip_protocol_fallback: true
    icmp:
      ip_protocol_fallback: true
      ttl: 64
    dns:
      ip_protocol_fallback: true
      recursion_desired: true
  icmp:
    prober: icmp
    timeout: 5s
    http:
      ip_protocol_fallback: true
      follow_redirects: true
      enable_http2: true
    tcp:
      ip_protocol_fallback: true
    icmp:
      preferred_ip_protocol: ip4
      ip_protocol_fallback: true
      ttl: 64
    dns:
      ip_protocol_fallback: true
      recursion_desired: true
  ssh_banner:
    prober: tcp
    timeout: 10s
    http:
      ip_protocol_fallback: true
      follow_redirects: true
      enable_http2: true
    tcp:
      ip_protocol_fallback: true
      query_response:
        - expect: ^SSH-2.0-
    icmp:
      ip_protocol_fallback: true
      ttl: 64
    dns:
      ip_protocol_fallback: true
      recursion_desired: true
  tcp_connect:
    prober: tcp
    timeout: 10s
    http:
      ip_protocol_fallback: true
      follow_redirects: true
      enable_http2: true
    tcp:
      preferred_ip_protocol: ip4
      tls_config:
        insecure_skip_verify: true
    icmp:
      ip_protocol_fallback: true
      ttl: 64
    dns:
      ip_protocol_fallback: true
      recursion_desired: true
```

#### prometheus.yaml - Beispiele für weitere E2E Tests - [Top of Page](#inhaltsverzeichnis)
```yaml
- job_name: 'blackbox.htdom.local'
  static_configs:
    - targets: ['blackbox.htdom.local:9115']

- job_name: 'blackbox-http-check'
  metrics_path: /probe
  params:
    module: [ http_2xx ]
  static_configs:
    - targets:
      - https://git.htdom.local
      - https://mfa.htdom.local
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: blackbox.htdom.local:9115

- job_name: 'blackbox-tcp-check'
  metrics_path: /probe
  params:
    module: [ tcp_connect ]
  static_configs:
    - targets:
        - "mina.htdom.local:443"
        - "git.htdom.local:443"
        - "mfa.htdom.local:443"
  relabel_configs:
    - source_labels: [ __address__ ]
      target_label: __param_target
    - source_labels: [ __param_target ]
      target_label: instance
    - target_label: __address__
      replacement: blackbox.htdom.local:9115

- job_name: 'blackbox-icmp-check'
  metrics_path: /probe
  params:
    module: [ icmp ]
  static_configs:
    - targets:
      - mina.htdom.local
      - git.htdom.local
  relabel_configs:
    - source_labels: [ __address__ ]
      target_label: __param_target
    - source_labels: [ __param_target ]
      target_label: instance
    - target_label: __address__
      replacement: blackbox.htdom.local:9115

```

#### Beispiel Checks - [Top of Page](#inhaltsverzeichnis)
```bash
## variables in Grafana
job - label_values(probe_success, job)
instance - label_values(probe_duration_seconds{job=~"$job"}, instance)

avg(probe_success{job=~"$job", instance=~"$instance"})

count(probe_success{job=~"$job", instance=~"$instance"} == 1)
count(probe_success{job=~"$job", instance=~"$instance"} == 0)

avg(scrape_duration_seconds{job=~"$job", instance=~"$instance"})
avg(scrape_duration_seconds{job="blackbox-http-check", instance=~"https://mina.htdom.local"})

avg by (phase) (probe_http_duration_seconds{job=~"$job", instance=~"$instance"})

count_values("http_version", probe_http_version{job=~"$job", instance=~"$instance"})
count by (version) (probe_tls_version_info{job=~"$job", instance=~"$instance"})
count_values("value", probe_http_status_code{job=~"$job", instance=~"$instance"})

(probe_ssl_earliest_cert_expiry{job=~"$job", instance=~"$instance"} - time()) / 3600 / 24
(probe_ssl_earliest_cert_expiry{job=~"blackbox-http-check", instance=~"https://mina.htdom.local"} - time()) / 3600 / 24

avg_over_time(probe_duration_seconds{job=~"blackbox-http-check", instance=~"https://mina.htdom.local"}[1m])

probe_tls_version_info{job=~"$job", instance=~"$instance"}
probe_http_version{job=~"$job", instance=~"$instance"}

## Debug Ausgabe vom Blackbox Server ausführen
##
curl -s "localhost:9115/probe?target=http://www.domain.de&module=http_2xx" | grep -v '^#'
curl -s "localhost:9115/probe?target=http://www.domain.de&module=tcp_connect" | grep -v '^#'
curl -s "localhost:9115/probe?target=http://www.domain.de&module=icmp" | grep -v '^#'

curl -s "localhost:9115/probe?target=http://www.domain.de&module=http_2xx&debug=true" | grep -v '^#'
curl -s "localhost:9115/probe?target=http://www.domain.de&module=tcp_connect&debug=true" | grep -v '^#'
curl -s "localhost:9115/probe?target=http://www.domain.de&module=icmp&debug=true" | grep -v '^#'

# Logs for the probe:
# ts=2024-12-18 caller=main.go:190 module=http_2xx target=http://www.domain.de level=info msg="Beginning probe" probe=http timeout_seconds=10
# ts=2024-12-18 caller=http.go:328 module=http_2xx target=http://www.domain.de level=info msg="Resolving target address" target=www.domain.de ip_protocol=ip4
# ts=2024-12-18 caller=http.go:328 module=http_2xx target=http://www.domain.de level=info msg="Resolved target address" target=www.domain.de ip=192.168.100.1
# ts=2024-12-18 caller=client.go:259 module=http_2xx target=http://www.domain.de level=info msg="Making HTTP request" url=http://192.168.100.1 host=www.domain.de
# ts=2024-12-18 caller=handler.go:119 module=http_2xx target=http://www.domain.de level=info msg="Received HTTP response" status_code=200
# ts=2024-12-18 caller=main.go:190 module=http_2xx target=http://www.domain.de level=info msg="Probe succeeded" duration_seconds=1.23230353

# ...
# probe_http_redirects 0
# probe_http_ssl 0
# probe_http_status_code 200
# probe_http_version 1.1
# probe_ip_protocol 4
# probe_success 1

# Module configuration:
# prober: http
# timeout: 10s
# http:
#   valid_http_versions:
#   - HTTP/1.1
#   - HTTP/2.0
#   preferred_ip_protocol: ip4
#   method: GET
#   tls_config:
#     insecure_skip_verify: true
#   follow_redirects: true
#   enable_http2: true
```
