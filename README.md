# My docker playground collection

At the moment I am learning docker, Dockerfile and docker-compose and this repository serves me as a kind of kownledge base.

<img src="https://img.shields.io/badge/-Docker-2496ED?logo=docker&logoColor=white&style=flat" />

---

### Table of content

* [Gitea Git Server](gitea/)

---

### Docker basics

```shell
## Docker Vorraussetzungen überprüfen
##
curl https://raw.githubusercontent.com/moby/moby/master/contrib/check-config.sh | sh
```

```shell
## Installing Docker on Ubuntu/Mint
##
sudo apt update && apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common 
curl -fsSL https://get.docker.com | sh

sudo usermod -aG docker hth

sudo systectl start docker
sudo systectl status docker

docker run hello-world
docker info
docker version
```