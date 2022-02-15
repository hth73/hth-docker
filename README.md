# My docker playground collection

At the moment I am learning docker, Dockerfile and docker-compose and this repository serves me as a kind of kownledge base.

<img src="https://img.shields.io/badge/-Docker-2496ED?logo=docker&logoColor=white&style=flat" /> <img src="https://img.shields.io/badge/-Dockerfile-2496ED?logo=docker&logoColor=white&style=flat" /> <img src="https://img.shields.io/badge/-docker%20compose-2496ED?logo=docker&logoColor=white&style=flat" />

---

## Table of content

* [Gitea Server](gitea/)
* [Apache-Tomcat Server](tomcat/)

---

## Docker Basics

* https://hub.docker.com
* https://labs.play-with-docker.com

Standardization
- Each container always has a precisely defined initial state
- Containers have defined interfaces
    - ports for Network 
    - Volumes for files and directories
- The application runs in the container with all dependencies

Four Basic terms
- Dockerfile = Building instructions for image 
- Image = Complete application with all dependencies
- Registry = Central library for images (E.g. Dockerhub)
- Container = Running application

## Docker image layer

When we run the docker build command, docker builds one layer for each instruction in the dockerfile. These image layers are read only layers. When we run the docker run command, docker builds container layer, which are read/write layers.

*Example Dockerfile*

```dockerfile
FROM ubuntu
RUN apt update
RUN apt install apache2 -y
```

```
+==============================================================================+
| Docker layer        | Shell commands          | Layer Type      | Access     |
+==============================================================================+
| docker image layer  | apt install curl -y     | Container Layer | Read/Write |
+------------------------------------------------------------------------------+
|                                                                              |
+------------------------------------------------------------------------------+
|                     | Dockerfile commands     |                              |
+------------------------------------------------------------------------------+
| docker third layer  | apt install apache2 -y  | Image Layer     | Read only  |
+------------------------------------------------------------------------------+
| docker second layer | apt update              | Image Layer     | Read only  |
+------------------------------------------------------------------------------+
| docker first layer  | ubuntu                  | Image Layer     | Read only  |
+------------------------------------------------------------------------------+
```

## Install Docker

```shell
## Check Docker prerequisites
##
curl https://raw.githubusercontent.com/moby/moby/master/contrib/check-config.sh | sh
```

```shell
## Install Docker on Ubuntu/Mint
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
## Docker basic commands

```shell
## search and download a docker image (Dockerhub)
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

## Example
## root@8908eecb4a01:/# apt update && apt install curl
## Exit container without deleting or terminating it
STRG + p q
docker ps -a 

## the container still running
## CONTAINER ID IMAGE  COMMAND CREATED       STATUS
## 8908eecb4a01 ubuntu "bash"  5 minutes ago Up 2 minutes ...

## docker image with custom name
docker run --name myubu -it ubuntu
docker start myubu
docker stats myubu # docker container state
docker top myubu
```
## Create docker image (a quick way for testing)

```shell
## create docker images
##
docker run -it -d ubuntu
docker ps
docker attach 0abed4ec0c29

# root@0abed4ec0c29:/# apt update && apt dist-upgrade -y && apt install apache2 -y
# root@0abed4ec0c29:/# /etc/init.d/apache2 status
#  * apache2 is not running
# root@0abed4ec0c29:/# /etc/init.d/apache2 start 
# * apache2 is running

STRG + p q

# create new image
docker commit 0abed4ec0c29 hth/apache-test:1.0

docker images
# REPOSITORY        TAG       IMAGE ID       CREATED         SIZE
# hth/apache-test   1.0       bad1e4d5a266   5 seconds ago   275MB
# ubuntu            latest    54c9d81cbb44   6 days ago      72.8MB

docker run -it -d -p 8080:80 hth/apache-test:1.0
docker ps

# CONTAINER ID IMAGE               COMMAND CREATED        STATUS        PORTS
# cbf7a40c9069 hth/apache-test:1.0 "bash"  18 seconds ago Up 17 seconds 0.0.0.0:8080->80/tcp, :::8080->80/tcp ...

http://localhost:8080 ## Apache service is not running, website is not reachable.

docker ps
docker commit --change='ENTRYPOINT ["apachectl", "-DFOREGROUND"]' cbf7a40c9069 hth/apache-test:1.1
# docker commit --change='CMD ["apachectl", "-DFOREGROUND"]' cbf7a40c9069 hth/apache-test:1.1

docker images
# REPOSITORY        TAG       IMAGE ID       CREATED          SIZE
# hth/apache-test   1.1       d324457c3e8b   4 seconds ago    275MB
# hth/apache-test   1.0       bad1e4d5a266   25 minutes ago   275MB
# ubuntu            latest    54c9d81cbb44   6 days ago       72.8MB

docker ps
docker stop cbf7a40c9069
docker run -it -d -p 8080:80 hth/apache-test:1.1

docker ps
# CONTAINER ID IMAGE               COMMAND                CREATED       STATUS       PORTS
# 09c9fd07ae1f hth/apache-test:1.1 "apachectl -DFOREGRO…" 4 seconds ago Up 3 seconds 0.0.0.0:8080->80/tcp, :::8080->80/tcp ...

http://localhost:8080 ## Apache service is running, website is reachable.
```

## Create docker image with Dockerfile (best practice)

```shell
mkdir -p ~/dockerimg/apache2 && cd ~/dockerimg/apache2
vi Dockerfile
```

```dockerfile
FROM ubuntu
MAINTAINER hth <email@domain.de>

## Skip prompts
ARG DEBIAN_FRONTEND=noninteractive

## Update packages
RUN apt update; apt dist-upgrade -y; apt autoremove -y

## Install Apache2 Webserver
RUN apt install apache2 vim curl net-tools -y

## Set entrypoint
ENTRYPOINT apachectl -D FOREGROUND
```

```shell
## docker build
##
docker build -t hth/apache-test:1.2 .

docker run -it -d -p 8080:80 hth/apache-test:1.2
```

## Delete docker image/container/system

```shell
## delete docker image
##
docker images
docker image remove httpd:2.4
docker rmi ubuntu
docker rmi d65c4d6a3580
docker rmi 612866ff4869 e19e33310e49 abe0cd4b2ebc

docker images -f dangling=true ## remove all dangling images
docker image prune ## remove all dangling images
docker image prune -a ## remove all not associated with any container
docker rmi $(docker images -q -f dangling=true) ## remove all dangling images

## delete docker container
##
docker ps -a
docker rm 0fd99ee0cb61 ## remove a single container
docker rm 0fd99ee0cb61 0fd99ee0cb61 ## remove multiple containers
docker stop 0fd99ee0cb61
docker rm -f 0fd99ee0cb61
docker rm $(docker ps -qa --filter "status=exited")

docker stop $(docker ps -a -q) ## stop all containers
docker container prune ## interactively remove all stopped containers
docker rm $(docker ps -qa)

## remove docker volumes
##
docker volume ls 
docker volume rm volume_ID ## remove a single volume 
docker volume rm volume_ID1 volume_ID2 ## remove multiple volumes

docker volume rm -f volume_ID ## force remove
docker volume rm $(docker volume ls  -q --filter dangling=true)
docker volume prune

## Remove Unused or Dangling Images, Containers, Volumes, and Networks
##
docker system prune
docker system prune --volumes
```