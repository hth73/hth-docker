# loki.htdom.local

Um die Logs von einem Linux System zentral steuern zu können, setze ich das Log Aggregation System von Grafana Loki ein. Die Logs werden über einen Client Agent gesammelt und dann an Grafana Loki gesendet. Angefangen hat alles mit Grafana Loki und den Grafana Promtail Agent. Da aber der Promtail Agent Ende März 2026 EOL geht, habe ich zusätzlich noch die Alternative Grafana Alloy Agent getestet um die Logs an Loki zu senden.

> https://loki.htdom.local/metrics  
https://loki.htdom.local/ready  
http://mina.htdom.local:3200/

---
#### Inhaltsverzeichnis

* [Ordner-Struktur](#ordner-struktur---top-of-page)
	* [~/docker/loki/config/loki-config.yaml](#etcalloyconfigalloy-journal-daemon-logs-beispiel---top-of-page)
	* [~/docker/caddy/config/Caddyfile](#dockercaddyconfigcaddyfile---top-of-page)
	* [~/docker/docker-compose.yaml](#dockerdocker-composeyaml---top-of-page)
* [Beispiel Abfragen ob Loki Daten zurückliefert](#beispiel-abfragen-ob-loki-daten-zurückliefert---top-of-page)
* [Promtail Agent installieren und konfigurieren](#promtail-agent-installieren-und-konfigurieren---top-of-page)
	* [Logging Konzept in einem Ubuntu System](#logging-konzept-in-einem-ubuntu-system---top-of-page)
	* [/etc/promtail/promtail-config.yaml (Journal Daemon Logs Beispiel)](#etcpromtailpromtail-configyaml-journal-daemon-logs-beispiel---top-of-page)
	* [/etc/promtail/promtail-config.yaml (rsyslog Beispiel)](#etcpromtailpromtail-configyaml-rsyslog-logs--beispiel---top-of-page)
* [Grafana Alloy Beschreibung](#grafana-alloy-beschreibung---top-of-page)
* [Grafana Alloy Agent Installation (Alternative zu Promtail)](#grafana-alloy-agent-installation-alternative-zu-promtail---top-of-page)
	* [/etc/alloy/config.alloy (Journal Daemon Logs Beispiel)](#etcalloyconfigalloy-journal-daemon-logs-beispiel---top-of-page)
	* [/etc/alloy/config.alloy (rsyslog Daemon Logs Beispiel)](#etcalloyconfigalloy-rsyslog-daemon-logs-beispiel---top-of-page)
	* [Loki Metriken Abfrage](#loki-metriken-abfrage---top-of-page)
---

#### Ordner-Struktur - [Top of Page](#inhaltsverzeichnis)
```bash
sudo vi /etc/hosts
# <Docker-Host IP-Adresse> loki.htdom.local

mkdir -p ~/docker/loki/config
mkdir -p /opt/loki/data

mkdir -p ~/docker/loki/promtail/config

## Beispielconfiguration für Loki Server herunterladen
## https://grafana.com/docs/loki/latest/configure/examples/configuration-examples
##
cd /tmp
wget https://github.com/grafana/loki/blob/main/cmd/loki/loki-local-config.yaml -O loki-config.yaml
```

#### ~/docker/loki/config/loki-config.yaml - [Top of Page](#inhaltsverzeichnis)
```yaml
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096
  grpc_server_max_recv_msg_size: 104857600 # 100 Mb
  grpc_server_max_send_msg_size: 104857600 # 100 Mb

ingester_client:
  grpc_client_config:
    max_recv_msg_size: 104857600 # 100 Mb
    max_send_msg_size: 104857600 # 100 Mb

ingester:
  chunk_encoding: snappy
  chunk_idle_period: 3h
  chunk_target_size: 3072000
  max_chunk_age: 2h

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2023-01-05
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: loki_index_
        period: 24h

limits_config:
  ingestion_rate_mb: 20
  ingestion_burst_size_mb: 30
  per_stream_rate_limit: "3MB"
  per_stream_rate_limit_burst: "10MB"
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  retention_period: 744h
  max_query_length: 0h
```

#### ~/docker/caddy/config/Caddyfile - [Top of Page](#inhaltsverzeichnis)
```html
loki.htdom.local {
  reverse_proxy http://loki.htdom.local:3100
  tls internal
}
```

#### ~/docker/docker-compose.yaml - [Top of Page](#inhaltsverzeichnis)
```yaml
  loki:
    image: docker.io/grafana/loki:3.4.2
    container_name: loki
    hostname: loki.${FQDN}
    network_mode: "host"
    user: root
    restart: always
    volumes:
      - "./loki/config/loki-config.yaml:/etc/loki/loki-config.yaml:ro"
      - "/opt/loki/data:/loki"
    command: 
      -config.file=/etc/loki/loki-config.yaml
      -config.expand-env=true
    ports:
      - "3100:3100"
```

#### Beispiel Abfragen ob Loki Daten zurückliefert - [Top of Page](#inhaltsverzeichnis)
```bash
## https://loki.htdom.local/ready
## https://loki.htdom.local/metrics
##
curl -G -s "https://loki.htdom.local/loki/api/v1/labels" | jq -r '.'
curl -G -s "https://loki.htdom.local/loki/api/v1/label/host/values" | jq -r '.data[]'
curl -G -s "https://loki.htdom.local/loki/api/v1/query_range" --data-urlencode 'query=sum(rate({job="varlogs"}[10m])) by (level)' --data-urlencode 'step=300' | jq
curl -G -s "https://loki.htdom.local/loki/api/v1/query_range" --data-urlencode 'query={job="varlogs"}' | jq -r '.'

curl -s "https://loki.htdom.local/loki/api/v1/series" --data-urlencode 'match[]={host=~"mina.*"}' | jq -r '.'
curl -s "https://loki.htdom.local/loki/api/v1/series" --data-urlencode 'match[]={syslog_identifier=~"sshd*"}' | jq -r '.'
curl -s "https://loki.htdom.local/loki/api/v1/series" --data-urlencode 'match[]={priority=~"error*"}' | jq -r '.'

curl -G -s "https://loki.htdom.local/loki/api/v1/query" --data-urlencode 'query=sum(rate({syslog_identifier="sshd"}[30m])) by (unit)' | jq -r '.'
curl -G -s "https://loki.htdom.local/loki/api/v1/query_range" --data-urlencode 'query={syslog_identifier="sshd"}' | jq -r '.'

## Unix Timestamp berücksichtigen beim hinzufügen von Datensätzen (--> [1715785516]000000000 <--)
## https://www.unixtimestamp.com/

## Daten an Loki senden und wieder abfragen
##
curl -S -H "Content-Type: application/json" -XPOST -s https://loki.htdom.local/loki/api/v1/push --data-raw '{"streams": [{ "stream": { "app": "app1" }, "values": [ [ "1715785516000000000", "random log line" ] ] }]}'

## entry for stream '{app="app1"}' has timestamp too old: 2022-05-29T20:18:38Z, oldest acceptable timestamp is: 2024-05-08T15:02:04Z

curl https://loki.htdom.local/loki/api/v1/labels
## {"status":"success","data":["_cmdline","_priority","app","host_name","job","priority","syslog_identifier","transport","unit"]}

curl https://loki.htdom.local/loki/api/v1/label/app/values
## {"status":"success","data":["app1"]}

curl -G -Ss https://loki.htdom.local/loki/api/v1/query_range --data-urlencode 'query={app="app1"}' | jq -r '.'
# {
#   "status": "success",
#   "data": {
#     "resultType": "streams",
#     "result": [
#       {
#         "stream": {
#           "app": "app1"
#         },
#         "values": [
#           [
#             "1715785516000000000",
#             "random log line"
#           ]
#         ]
#       }
#     ],
#
```

#### Promtail Agent installieren und konfigurieren - [Top of Page](#inhaltsverzeichnis)
```bash
sudo groupadd promtail
sudo useradd --system --gid promtail --shell /bin/false --comment "Promtail Service User" promtail

sudo mkdir /etc/promtail

## Beispielconfiguration herunterladen
##
cd /tmp
wget https://raw.githubusercontent.com/grafana/loki/v2.9.4/clients/cmd/promtail/promtail-docker-config.yaml -O promtail-config.yaml

sudo vi /etc/promtail/promtail-config.yaml

## Promtail installieren
##
cd /tmp

wget https://github.com/grafana/loki/releases/download/v3.4.2/promtail-linux-arm64.zip
unzip promtail-linux-arm64.zip
sudo mv promtail-linux-arm64 /usr/local/bin/promtail

# ---

sudo vi /etc/systemd/system/promtail.service

[Unit]
Description=Promtail
Documentation=https://grafana.com/docs/loki/latest/send-data/promtail
After=network.target

[Service]
User=root
Group=root
ExecStart=/usr/local/bin/promtail -config.file /etc/promtail/promtail-config.yaml -config.expand-env=true
Restart=on-failure
RestartSec=5s
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target

# ---

sudo systemctl enable --now promtail.service
sudo systemctl status promtail.service
```

#### Logging Konzept in einem Ubuntu System - [Top of Page](#inhaltsverzeichnis)
```bash
In einem Debian/Ubuntu System gibt es folgendes Logging Konzept:

# --------------------------------------------------
# journald (journalctl)
# --------------------------------------------------
journald ist der zentrale Logging-Dienst von systemd. Er sammelt Logs von allen Diensten, die über systemd gestartet werden.
Dies umfasst einen Großteil der Systemdienste, was journalctl zu einer sehr wichtigen Quelle für Logs macht.  
# sudo systemctl list-unit-files --state=enabled

# --------------------------------------------------
# rsyslog
# --------------------------------------------------
rsyslog ist ein traditioneller Syslog-Dienst
rsyslog empfängt Logs von verschiedenen Quellen und schreibt diese in Textdateien unter /var/log/

# --------------------------------------------------
# Fazit
# --------------------------------------------------
Standardmäßig leitet Ubuntu viele Logs von journald an rsyslog weiter. Das bedeutet, dass viele Logs sowohl in journald als auch in den traditionellen Logdateien zu finden sind.
/var/log/syslog und /var/log/auth.log sind typische Logdateien, die von rsyslog verwaltet werden, jedoch werden die Daten die diese Dateien beinhalten auch von Journalctl verwaltet.

Weitere wichtige Logdateien auf einen Default Ubuntu System:

- /var/log/syslog: Allgemeine Systemmeldungen. # (Wird nach journald geschrieben)
- /var/log/auth.log: Authentifizierungsversuche # (Wird nach journald geschrieben)
- /var/log/kern.log: Kernel-Meldungen. # (Wird nach journald geschrieben)
- /var/log/dmesg: Kernelringpuffer # (Wird nach journald geschrieben)
- /var/lib/docker/containers: Alle Logs der Docker Container # (Wird nach journald geschrieben)
- /var/log/apt/history.log: APT-Paketverwaltungsaktivitäten.
- /var/log/alternatives.log (Alternativen-System von Debian-basierten Linux-Distributionen)
- /var/log/apport.log (Apport-Fehlerberichterstattungssystems auf Ubuntu-Systemen) 
- /var/log/bootstrap.log (dpkg und Update Informationen)
- /var/log/dpkg.log (Software und Update Installationen)
```

#### /etc/promtail/promtail-config.yaml (Journal Daemon Logs Beispiel) - [Top of Page](#inhaltsverzeichnis)
```yaml
server:
  http_listen_address: 0.0.0.0
  http_listen_port: 9080

positions:
  filename: /var/log/positions.yaml

clients:
  - url: https://loki.htdom.local/loki/api/v1/push
    tls_config:
      insecure_skip_verify: true

scrape_configs:
  - job_name: journalctl
    journal:
      json: false
      max_age: 12h
      path: /var/log/journal
      labels:
        job: journalctl
    relabel_configs:
      - action: drop
        source_labels: ["__journal__transport"]
        regex: "kernel"
      - source_labels: ["__journal__systemd_unit"]
        target_label: "unit"
      - source_labels: ["__journal__hostname"]
        target_label: "host_name"
      - source_labels: ["__journal__transport"]
        target_label: "transport"
      - source_labels: ["__journal__cmdline"]
        target_label: "_cmdline"
      - source_labels: ["__journal_priority"]
        target_label: "_priority"
      - source_labels: ["__journal_priority_keyword"]
        target_label: "priority"
      - source_labels: ["__journal_syslog_identifier"]
        target_label: "syslog_identifier"
      - source_labels: ["__journal_syslog_message_severity"]
        target_label: "level"
      - source_labels: ["__journal_syslog_message_facility"]
        target_label: "syslog_facility"
```

#### /etc/promtail/promtail-config.yaml (rsyslog Logs  Beispiel) - [Top of Page](#inhaltsverzeichnis)
```yaml
  - job_name: syslog
    static_configs:
      labels:
        job: syslog
        __path__: /var/log/*log
    relabel_configs:
      - source_labels: ["__syslog_message_hostname"]
        target_label: "host_name"
      - source_labels: ["__syslog_message_severity"]
        target_label: "level"
      - source_labels: ["__syslog_message_facility"]
        target_label: "syslog_facility"
      - source_labels: ["__syslog_message_app_name"]
        target_label: "syslog_identifier"

  - job_name: container-logs
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 15s
    pipeline_stages:
      - docker: {}
    relabel_configs:
      - source_labels: ['__meta_docker_container_name'] # the name of the container
        regex: '/(.*)'
        target_label: 'container_name'
      - source_labels: ['__meta_docker_container_id'] # the id of the container
        target_label: 'container_id'
      - source_labels: ['__meta_docker_container_network_mode']
        target_label: 'network_mode'
      - source_labels: ['__meta_docker_network_ip'] 
        target_label: 'network_ip'
      - source_labels: ['__meta_docker_port_private'] 
        target_label: 'port_private'
      - source_labels: ['__meta_docker_port_public'] 
        target_label: 'port_public'
      - source_labels: ['__meta_docker_port_public_ip'] 
        target_label: 'port_public_ip'
```

#### Grafana Alloy Beschreibung - [Top of Page](#inhaltsverzeichnis)
```bash
Grafana Alloy ist ein neues Konzept für die Log/Metrics und Telemetry Daten Erfassung, das in Grafana integriert ist und Loki sowie Promtail/node-exporter/blackbox-exporter teilweise ersetzen soll. Der Übergang von Loki/Promtail zu Grafana Alloy könnte in Zukunft in Betracht gezogen werden, aber es gibt einige Punkte, die zu berücksichtigen sind:
Technische Dokumentation: https://grafana.com/docs/alloy/latest/

Grafana Alloy ist noch nicht vollständig in allen Versionen von Grafana integriert. Es handelt sich um eine zukünftige Funktionalität, die schrittweise eingeführt wird.

Der Migrationspfad von Loki/Promtail zu Alloy ist nicht unbedingt "einfach" im klassischen Sinn. Je nachdem, wie tief das Setup in Loki und Promtail integriert ist, muss man möglicherweise bestimmte Konfigurationen und Datenströme migrieren. Wenn man bereits auf Loki für Logs setzt, könnte die Umstellung auf Alloy bedeuten, dass die Art der Log-Erfassung und -Visualisierung sich ändert.

Grafana Alloy könnte Log-Daten, die früher in Loki/Promtail gespeichert wurden, direkt verarbeitet, aber man müsste sicherstellen, dass bisherige Log-Daten auch weiterhin verwalten werden können. Ein vollständiges "Ersetzen" von Loki/Promtail könnte daher mit einer Umstellung der gesamten Architektur und dem möglichen Verlust von historischen Daten verbunden sein.
```

#### Grafana Alloy Agent Installation (Alternative zu Promtail) - [Top of Page](#inhaltsverzeichnis)
```bash
cd /tmp
VERSION="$(curl --silent -qI https://github.com/grafana/alloy/releases/latest | awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}')"
# ${VERSION} = v1.7.1
# ${VERSION#v} = 1.7.1

wget https://github.com/grafana/alloy/releases/download/${VERSION}/alloy-linux-arm64.zip # ARM64
unzip alloy-linux-arm64.zip
chmod +x alloy-linux-arm64
sudo mv alloy-linux-arm64 /usr/local/bin/alloy

sudo mkdir /etc/alloy
sudo vi /etc/alloy/config.alloy
sudo vi /etc/systemd/system/grafana-alloy-agent.service

# ---

## /etc/systemd/system/grafana-alloy-agent.service
##
[Unit]
Description=Grafana Alloy Agent
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
WorkingDirectory=/usr/local/bin/
ExecStart=/usr/local/bin/alloy run --server.http.listen-addr=0.0.0.0:3200 /etc/alloy/config.alloy
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

#### /etc/alloy/config.alloy (Journal Daemon Logs Beispiel) - [Top of Page](#inhaltsverzeichnis)
```yaml
logging {
    level  = "debug"
    format = "logfmt"
}

loki.relabel "journalctl" {
    forward_to = []

    rule {
        source_labels = ["__journal__transport"]
        regex         = "kernel"
        action        = "drop"
    }

    rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
    }

    rule {
        source_labels = ["__journal__transport"]
        target_label  = "transport"
    }

    rule {
        source_labels = ["__journal__cmdline"]
        target_label  = "_cmdline"
    }

    rule {
        source_labels = ["__journal_priority"]
        target_label  = "_priority"
    }

    rule {
        source_labels = ["__journal_priority_keyword"]
        target_label  = "priority"
    }

    rule {
        source_labels = ["__journal_syslog_identifier"]
        target_label  = "syslog_identifier"
    }

    rule {
        source_labels = ["__journal_syslog_message_severity"]
        target_label  = "level"
    }

    rule {
        source_labels = ["__journal_syslog_message_facility"]
        target_label  = "syslog_facility"
    }
}

loki.source.journal "journalctl" {
    max_age       = "12h0m0s"
    path          = "/var/log/journal"
    relabel_rules = loki.relabel.journalctl.rules
    forward_to    = [loki.write.grafana_loki.receiver]
    labels        = {
        job = "journalctl",
    }
}

loki.write "grafana_loki" {
    endpoint {
        url = "https://loki.htdom.local/loki/api/v1/push"

        tls_config {
            insecure_skip_verify = true
        }
    }

    external_labels = {
        job = "alloy-agent",
        host = "mina.htdom.local",
    }
}
```

#### /etc/alloy/config.alloy (rsyslog Daemon Logs Beispiel) - [Top of Page](#inhaltsverzeichnis)
```yaml
logging {
  level  = "debug"
  format = "logfmt"
}

local.file_match "var_log_logs" {
  path_targets = [{ "__path__" = "/var/log/*.log" }]
  sync_period  = "5s"
}

local.file_match "var_log_apt_history" {
  path_targets = [{ "__path__" = "/var/log/apt/history.log" }]
  sync_period  = "5s"
}

local.file_match "var_log_syslog" {
    path_targets = [{ "__path__" = "/var/log/syslog" }]
    sync_period = "5s"
}

local.file_match "var_log_dmesg" {
    path_targets = [{ "__path__" = "/var/log/dmesg" }]
    sync_period = "5s"
}

loki.source.file "log_scrape" {
  targets = concat(
    local.file_match.var_log_logs.targets,
    local.file_match.var_log_apt_history.targets,
    local.file_match.var_log_syslog.targets,
    local.file_match.var_log_dmesg.targets,
  )
  forward_to = [loki.process.filter_logs.receiver]
  tail_from_end = true
}

loki.process "filter_logs" {
  stage.drop {
    source = ""
    expression = ".*Connection closed by authenticating user root"
    drop_counter_reason = "noisy"
  }
  stage.drop {
    source = ""
    expression = ".*session (opened|closed) for user root.*"
    drop_counter_reason = "sudo_session_activity"
  }
  forward_to = [loki.write.grafana_loki.receiver]
}

loki.write "grafana_loki" {
  endpoint {
    url = "https://loki.htdom.local/loki/api/v1/push"

    tls_config {
      insecure_skip_verify = true
    }
  }

  external_labels = {
    job = "alloy-agent",
    host = "mina.htdom.local",
  }
}
```

#### Loki Metriken Abfrage - [Top of Page](#inhaltsverzeichnis)
```bash
## Wichtige Metriken um zu sehen ob Logs übertragen werden.
## Logs werden erst an Loki gesendet, wenn es neue Einträge in den Logs gibt.
## Wenn keine Einträge geschrieben werden, wird auch nichts an Loki übertragen.
##
curl -s http://mina.htdom.local:3200/metrics | grep loki

# HELP loki_source_file_file_bytes_total Number of bytes total.
# TYPE loki_source_file_file_bytes_total gauge
loki_source_file_file_bytes_total{component_id="loki.source.file.log_scrape",component_path="/",path="/var/log/alternatives.log"} 153
loki_source_file_file_bytes_total{component_id="loki.source.file.log_scrape",component_path="/",path="/var/log/apport.log"} 0
loki_source_file_file_bytes_total{component_id="loki.source.file.log_scrape",component_path="/",path="/var/log/auth.log"} 78978
...

# HELP loki_source_file_read_bytes_total Number of bytes read.
# TYPE loki_source_file_read_bytes_total gauge
loki_source_file_read_bytes_total{component_id="loki.source.file.log_scrape",component_path="/",path="/var/log/alternatives.log"} 153
loki_source_file_read_bytes_total{component_id="loki.source.file.log_scrape",component_path="/",path="/var/log/apport.log"} 0
loki_source_file_read_bytes_total{component_id="loki.source.file.log_scrape",component_path="/",path="/var/log/auth.log"} 78978
...

# HELP loki_source_file_read_lines_total Number of lines read.
# TYPE loki_source_file_read_lines_total counter
loki_source_file_read_lines_total{component_id="loki.source.file.log_scrape",component_path="/",path="/var/log/apt/history.log"} 6
loki_source_file_read_lines_total{component_id="loki.source.file.log_scrape",component_path="/",path="/var/log/dpkg.log"} 38
loki_source_file_read_lines_total{component_id="loki.source.file.log_scrape",component_path="/",path="/var/log/syslog"} 22
...

# HELP loki_write_sent_bytes_total Number of bytes sent.
# TYPE loki_write_sent_bytes_total counter
loki_write_sent_bytes_total{component_id="loki.write.grafana_loki",component_path="/",host="loki.htdom.local"} 5275

# HELP loki_write_sent_entries_total Number of log entries sent to the ingester.
# TYPE loki_write_sent_entries_total counter
loki_write_sent_entries_total{component_id="loki.write.grafana_loki",component_path="/",host="loki.htdom.local"} 71

curl -G -s 'https://loki.htdom.local/loki/api/v1/query_range' --data-urlencode 'query={job="alloy-agent"}' | jq -r '.'
curl -G -s 'https://loki.htdom.local/loki/api/v1/query_range' --data-urlencode 'query={host="mina.htdom.local"}' | jq -r '.'
```
