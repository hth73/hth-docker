# caddy.htdom.local

In dieser Note werden nur die Configs hinzugefügt, die derzeit auf dem Raspberry Pi laufen. 

---
#### Inhaltsverzeichnis

* [Ordner und Verzeichnis Struktur](#ordner-und-verzeichnis-struktur---top-of-page)
	* [~/docker/caddy/config/Caddyfile](#dockercaddyconfigcaddyfile---top-of-page)
	* [~/docker/docker-compose.yaml](#dockerdocker-composeyaml---top-of-page)
---

#### Ordner und Verzeichnis Struktur - [Top of Page](#inhaltsverzeichnis)
```bash
mkdir -p ~/docker/caddy/config
mkdir -p /opt/caddy/data

## Caddy RootCA Zertifikat für den Browser
##
ls -la /opt/caddy/data/caddy/pki/authorities/local 
-rw------- 1 root root  680 Mar 29 20:18 intermediate.crt
-rw------- 1 root root  227 Mar 29 20:18 intermediate.key
-rwxr-xr-x 1 root root  631 Sep 15  2024 root.crt
-rwxr-xr-x 1 root root  227 Sep 15  2024 root.key

## Serverzertifikate
##
ls -la /opt/caddy/data/caddy/certificates/local/
drwxr-xr-x 2 root root 4096 Apr  3 09:18 blackbox.htdom.local
drwxr-xr-x 2 root root 4096 Apr  3 13:28 git.htdom.local
drwxr-xr-x 2 root root 4096 Apr  3 09:18 grafana.htdom.local
drwxr-xr-x 2 root root 4096 Apr  3 09:18 loki.htdom.local
drwx------ 2 root root 4096 Apr  3 09:08 oidc.htdom.local
drwxr-xr-x 2 root root 4096 Apr  3 09:18 prometheus.htdom.local
drwxr-xr-x 2 root root 4096 Apr  3 13:08 registry.htdom.local
```

#### ~/docker/caddy/config/Caddyfile - [Top of Page](#inhaltsverzeichnis)
```yaml
git.htdom.local {
  reverse_proxy http://git.htdom.local:3000
  tls internal
}

grafana.htdom.local {
  reverse_proxy http://grafana.htdom.local:3001
  tls internal
}

oidc.htdom.local {
  tls internal
  reverse_proxy http://oidc.htdom.local:3002 {
    header_up Host {host}
    header_up X-Forwarded-Proto {scheme}
    header_up X-Forwarded-For {remote}
  }
}

loki.htdom.local {
  reverse_proxy http://loki.htdom.local:3100
  tls internal
}

registry.htdom.local {
  reverse_proxy http://registry.htdom.local:5000
  tls internal
}

prometheus.htdom.local {
  reverse_proxy http://prometheus.htdom.local:9090
  tls internal
}

blackbox.htdom.local {
  reverse_proxy http://blackbox.htdom.local:9115
  tls internal
}
```

#### ~/docker/docker-compose.yaml - [Top of Page](#inhaltsverzeichnis)
```yaml
  caddy:
    image: docker.io/caddy:2.9.1
    container_name: caddy
    hostname: caddy.${FQDN}
    network_mode: "host"
    restart: always
    volumes:
      - "./caddy/config/Caddyfile:/etc/caddy/Caddyfile:ro"
      - "/opt/caddy/data:/data"
      - "/opt/caddy/config:/config"
    ports:
      - "80:80"
      - "443:443"
```
