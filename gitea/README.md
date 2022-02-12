# Gitea

[Back to home](../README.md)

---

## Description
Gitea über docker-compose bereitstellen.

## Preparation

```bash
vi ~/docker/gitea/docker-compose.yml

# --- docker-compose.yml --- #

version: "3"

networks:
 gitea:
   external: false

services:
 server:
   image: gitea/gitea:latest
   container_name: gitea
   environment:
     - USER_UID=1000
     - USER_GID=1000
   restart: always
   networks:
     - gitea
   volumes:
     - /home/<usernam>/gitea:/data
     - /etc/timezone:/etc/timezone:ro
     - /etc/localtime:/etc/localtime:ro
   ports:
     - "3000:3000"
     - "222:22"

# --- docker-compose.yml --- #
```

## Execution

```bash
sudo docker-compose up -d
```

## Configuration

```html
http://<IP-ADDRESS>:3000
```