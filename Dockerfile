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

