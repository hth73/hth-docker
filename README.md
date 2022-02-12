# My docker playground collection

At the moment I am learning docker, Dockerfile and docker-compose and this repository serves me as a kind of kownledge base.

<img src="https://img.shields.io/badge/-Docker-2496ED?logo=docker&logoColor=white&style=flat" />

---

### Table of content

* [Gitea Git Server](gitea/)

---

### Docker Basics

* https://hub.docker.com
* https://labs.play-with-docker.com

Standardisierung
- Jeder Container hat immer einen präzisen Ausgangszustand
- Container haben definierte Schnittstellen
    - Ports für Netzwerk 
    - Volumes für Dateien und Verzeichnisse
- Im Container läuft die Applikation mit allen Abhängigkeiten

Vier Grundbegriffe
- Dockerfile = Bauanleitung für Image 
- Image = eingepackte Applikation
- Registry = Zentrale Bibliothek für Images
- Container = laufende Applikation

```shell
## Docker Vorraussetzungen überprüfen
##
curl https://raw.githubusercontent.com/moby/moby/master/contrib/check-config.sh | sh
```

```shell
## Installing Docker on Ubuntu/Mint
##
sudo apt update && apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent \
software-properties-common 
curl -fsSL https://get.docker.com | sh

sudo usermod -aG docker hth

sudo systectl start docker
sudo systectl enable docker
sudo systectl status docker

docker run hello-world
docker info
docker version
```

```shell
## search and download a docker image
##
docker search ubuntu
docker pull ubuntu
```

```shell
## Run a Docker Container
##
docker run ubuntu cat /etc/issue
docker ps -a

## CONTAINER ID IMAGE  COMMAND          CREATED       STATUS                     
## 2fbfcdabd132 ubuntu "cat /etc/issue" 9 seconds ago Exited (0) ...

docker run -it ubuntu # STRG + D
docker ps -a

## CONTAINER ID IMAGE  COMMAND CREATED        STATUS
## 8908eecb4a01 ubuntu "bash"  15 seconds ago Exited (0) ...

docker start 8908eecb4a01
docker ps -a

## CONTAINER ID IMAGE  COMMAND CREATED            STATUS
## 8908eecb4a01 ubuntu "bash"  About a minute ago Up 1 second ...

docker stop 8908eecb4a01
docker ps -a

## CONTAINER ID IMAGE  COMMAND CREATED        STATUS
## 8908eecb4a01 ubuntu "bash"  15 seconds ago Exited (0) ...

docker start 8908eecb4a01
docker attach 8908eecb4a01

## Beispiel
## root@8908eecb4a01:/# apt update && apt install curl
## Exit Container ohne das er gelöscht oder beendet wird
STRG + p q
docker ps -a 

## Der Container läuft weiter
## CONTAINER ID IMAGE  COMMAND CREATED       STATUS
## 8908eecb4a01 ubuntu "bash"  5 minutes ago Up 2 minutes ...

## Docker Image benahmen
docker run --name myubu -it ubuntu
docker start myubu
docker stats myubu # Auslastung des docker Containers
docker top myubu
```