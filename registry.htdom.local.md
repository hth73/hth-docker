# registry.htdom.local 

Hier wird kurz erklärt wie man eine eigene Docker Registry anlegt, um diese später für die GitHub Actions nutzen zu können.
Warum ist die eigene Docker Registry entstanden? Ich wollte nicht immer 1,2 GB aus dem Internet laden. Daher habe ich es einmal heruntergeladen und das Docker Image in die lokale Registry verschoben.
Auch hier wurde der Caddy Reverse Proxy für das Zertifikat genutzt.

> https://registry.htdom.local

---
#### Inhaltsverzeichnis

* [Ordner-Struktur](#ordner-struktur---top-of-page)
	* [~/docker/caddy/config/Caddyfile](#dockercaddyconfigcaddyfile---top-of-page)
	* [~/docker/docker-compose.yaml](#dockerdocker-composeyaml---top-of-page)
* [Docker Registry testen](#docker-registry-testen---top-of-page)
	* [~/docker/Dockerfile](#dockerdockerfile---top-of-page)
* [Renovate Docker Image bauen, taggen und in die Registry hochladen](#renovate-docker-image-bauen-taggen-und-in-die-registry-hochladen---top-of-page)
	* [Docker Host aufräumen](#docker-host-aufräumen---top-of-page)
---

#### Ordner-Struktur - [Top of Page](#inhaltsverzeichnis)
```bash
sudo vi /etc/hosts
# <Docker-Host IP-Adresse> registry.htdom.local

mkdir -p /opt/registry/data
cp /opt/caddy/data/caddy/pki/authorities/local/root.crt ~/docker/root.crt
```

#### ~/docker/caddy/config/Caddyfile - [Top of Page](#inhaltsverzeichnis)
```bash
registry.htdom.local {
  reverse_proxy http://registry.htdom.local:5000
  tls internal
}
```

#### ~/docker/docker-compose.yaml - [Top of Page](#inhaltsverzeichnis)
```yaml
  registry:
    image: docker.io/registry:2
    container_name: registry
    hostname: registry.${FQDN}
    network_mode: "host"
    restart: always
    ports:
      - "5000:5000"
    environment:
      REGISTRY_STORAGE_DELETE_ENABLED: "true"
      REGISTRY_HTTP_ADDR: "0.0.0.0:5000"
    volumes:
      - "/opt/registry/data:/var/lib/registry"
```

#### Docker Registry testen - [Top of Page](#inhaltsverzeichnis)
```bash
curl -sk -X GET https://registry.htdom.local/v2/_catalog
# {"repositories":[]}
```

#### ~/docker/Dockerfile - [Top of Page](#inhaltsverzeichnis)
```bash
FROM docker.io/renovate/renovate:39

# Wechsel zu Root für Zertifikatsupdate
USER root

# Arbeitsverzeichnis setzen
WORKDIR /usr/src/app

# Root-CA Zertifikat ins System einfügen
COPY root.crt /usr/local/share/ca-certificates/caddy-root.crt 
RUN update-ca-certificates

# Standardkommando für den Container
CMD ["renovate"]
```

#### Renovate Docker Image bauen, taggen und in die Registry hochladen - [Top of Page](#inhaltsverzeichnis)
```bash
## https://git.htdom.local/hth/docker/src/branch/master/Dockerfile
docker build -t renovate/renovate:39 .

docker images
# hth/renovate:39    9b31adbbcd96   49 minutes ago   1.25GB

docker tag renovate/renovate:39 registry.htdom.local/renovate/renovate:39
docker push registry.htdom.local/renovate/renovate:39

ls -la /opt/registry/data/docker/registry/v2/repositories/renovate/renovate
# drwxr-xr-x  3 root root 4096 Mar  2 14:51 _layers
# drwxr-xr-x  4 root root 4096 Mar  2 14:52 _manifests
# drwxr-xr-x 10 root root 4096 Mar  2 14:52 _uploads

curl -sk -X GET https://registry.htdom.local/v2/_catalog | jq -r '.'
# {
#   "repositories": [
#     "renovate/renovate"
#   ]
# }

curl -sk -X GET https://registry.htdom.local/v2/renovate/renovate/tags/list | jq -r '.'
# {
#   "name": "renovate/renovate",
#   "tags": [
#     "39"
#   ]
# }
```

#### Docker Host aufräumen - [Top of Page](#inhaltsverzeichnis)
```bash
## Da auf dem Docker Host nun beide Renovate Images vorhanden sind. Das eine aus dem DockerHub und das zweite aus der internen Registry "siehe IMAGE ID"
## Werden beide Docker Images auf dem Docker Host gelöscht und aus der Registry neu gezogen.

docker images                                                            
# REPOSITORY                               TAG       IMAGE ID       CREATED         SIZE
# renovate/renovate                        39        223cdf2b6e80   4 minutes ago   1.26GB
# registry.htdom.local/renovate/renovate   39        223cdf2b6e80   4 minutes ago   1.26GB

docker rmi 223cdf2b6e80 --force
# Untagged: renovate/renovate:39
# Untagged: registry.htdom.local/renovate/renovate:39
# Untagged: registry.htdom.local/renovate/renovate@sha256:d473ed555e6af8b21a6060e83f48d8c69dab3942055cddf9e720954c451e0c0a
# Deleted: sha256:223cdf2b6e801050747bda7838cbb6e516c26dc2cafbdaf21431312c3ed1f568

docker pull registry.htdom.local/renovate/renovate:39

docker images                                        
# REPOSITORY                               TAG       IMAGE ID       CREATED         SIZE
# registry.htdom.local/renovate/renovate   39        223cdf2b6e80   6 minutes ago   1.26GB
```
