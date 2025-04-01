#git #forgejo #forgejo-runner #githubactions #mend-renovate

Um den ganzen Code lokal hosten zu können, wurde auf einem Raspberry Pi der als Docker-Host dient, ein Forgejo Git Server + Forgejo-Runner mit Caddy als Reverse Proxy installiert.
Damit alle betriebenen Docker Container auch immer schön "Up to date" bleiben, wurde der Mend Renovate Bot für das "hth/docker" Repository hinzugefügt. 
Um den Renovate Bot täglich laufen zu lassen, benötigte es noch eine Pipeline die als GitHub Actions in Forgejo Git Server ausgeführt wird. 
Hier wird im Hintergrund ein Renovate Docker Image gebaut und in eine lokale Docker Registry abgelegt, der Renovate Bot bedient sich dem lokalen Renovate Docker Image und erstellt bei Bedarf einen Merge Request mit allen Änderungen.

Meine lokale Spieldomäne heißt **"htdom.local"**. Alle Services sind mit einem Zertifikat abgesichert. In dieser Umgebung kommt das Root-CA und Server Zertifikat(e) von Caddy Service.
Um im Web Browser keinen Zertifikats Warnmeldungen zu bekomme, wurde das Caddy Root-CA Zertifikat in dem Browser seinen Zertifikats-Store importiert.

>[!note] https://git.htdom.local

![[forgejo.jpg|460x230]]

---
* [[#Ordner-Struktur]]
	* [[#~/docker/forgejo/config/app.ini]]
	* [[#~/docker/caddy/config/Caddyfile]]
	* [[#~/docker/.env]]
	* [[#~/docker/docker-compose.yaml]]
* [[#Forgejo-Runner installieren und registrieren]]
* [[#Renovate-Bot integrieren]]
	* [[#config.js]]
	* [[#renovate.json]]
* [[#GitHub Actions integrieren für renovate-Bot]]
	* [[#.forgejo/workflows/renovate.yaml]]
	* [[#.forgejo/workflows/show_variables.yaml]]

---
#### Ordner-Struktur 
```bash
sudo vi /etc/hosts
# <Docker-Host IP-Adresse> git.htdom.local

mkdir -p ~/docker/forgejo/config
mkdir -p /opt/forgejo/data

mkdir -p ~/docker/caddy/config
mkdir -p /opt/caddy/data
```
#### ~/docker/forgejo/config/app.ini
```html
APP_NAME = HTH
RUN_MODE = prod
APP_SLOGAN = Beyond coding. We Forge.
RUN_USER = git
WORK_PATH = /data/gitea

[repository]
ROOT = /data/git/repositories
USE_COMPAT_SSH_URI = true

[repository.local]
LOCAL_COPY_PATH = /data/gitea/tmp/local-repo

[repository.upload]
TEMP_PATH = /data/gitea/uploads

[server]
APP_DATA_PATH = /data/gitea
DOMAIN = git.htdom.local
SSH_DOMAIN = git.htdom.local
HTTP_PORT = 3000
ROOT_URL = https://git.htdom.local:3030/
DISABLE_SSH = false
SSH_PORT = 2222
SSH_LISTEN_PORT = 22
LFS_START_SERVER = true
LFS_JWT_SECRET = agQkPia9-l44UnxsyMWcVcLElVGLyXl8ZCjHSZ5iTEY
OFFLINE_MODE = true

[database]
PATH = /data/gitea/gitea.db
DB_TYPE = sqlite3
HOST = localhost:3306
NAME = gitea
USER = root
PASSWD = 
LOG_SQL = false
SCHEMA = 
SSL_MODE = disable

[indexer]
ISSUE_INDEXER_PATH = /data/gitea/indexers/issues.bleve

[session]
PROVIDER_CONFIG = /data/gitea/sessions
PROVIDER = file

[picture]
AVATAR_UPLOAD_PATH = /data/gitea/avatars
REPOSITORY_AVATAR_UPLOAD_PATH = /data/gitea/repo-avatars

[attachment]
PATH = /data/gitea/attachments

[log]
MODE = console
LEVEL = info
ROOT_PATH = /data/gitea/log

[security]
INSTALL_LOCK = true
SECRET_KEY = 
REVERSE_PROXY_LIMIT = 1
REVERSE_PROXY_TRUSTED_PROXIES = *
INTERNAL_TOKEN = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYmYiOjE3MjY0MjQxMjV9.ppxIwh28rw0qZUUIjcWNTDWbcJEGaQHqdwW3vY5bsB4
PASSWORD_HASH_ALGO = pbkdf2_hi

[service]
DISABLE_REGISTRATION = true
REQUIRE_SIGNIN_VIEW = false
REGISTER_EMAIL_CONFIRM = false
ENABLE_NOTIFY_MAIL = false
ALLOW_ONLY_EXTERNAL_REGISTRATION = false
ENABLE_CAPTCHA = false
DEFAULT_KEEP_EMAIL_PRIVATE = false
DEFAULT_ALLOW_CREATE_ORGANIZATION = true
DEFAULT_ENABLE_TIMETRACKING = true
NO_REPLY_ADDRESS = noreply.localhost

[lfs]
PATH = /data/git/lfs

[mailer]
ENABLED = false

[openid]
ENABLE_OPENID_SIGNIN = true
ENABLE_OPENID_SIGNUP = true

[cron.update_checker]
ENABLED = true

[repository.pull-request]
DEFAULT_MERGE_STYLE = merge

[repository.signing]
DEFAULT_TRUST_MODEL = committer

[oauth2]
JWT_SECRET = WCtbssptNQWh_seknFnim4r-Ge2XDdMltCbhMKH-RXw
```
#### ~/docker/caddy/config/Caddyfile
```html
git.htdom.local {
  reverse_proxy http://git.htdom.local:3000
  tls internal
}
```
####  ~/docker/.env
```bash
FQDN=htdom.local
```
#### ~/docker/docker-compose.yaml
```yaml
---
networks:
  homenet:
    name: homenet
    driver: bridge

services:
  forgejo:
    image: codeberg.org/forgejo/forgejo:10.0.3
    container_name: git
    hostname: git.${FQDN}
    environment:
      - USER_UID=1000
      - USER_GID=1000
    restart: always
    volumes:
      - "/opt/forgejo/data:/data"
      - "/etc/timezone:/etc/timezone:ro"
      - "/etc/localtime:/etc/localtime:ro"
    networks:
      - homenet
    ports:
      - "3000:3000"
      - "2222:22"

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

>[!note] Caddy Root CA Zertifikat in dem Browser seinen Zertifikats Store importieren - /opt/caddy/data/caddy/pki/authorities/local/root.crt
#### Forgejo-Runner installieren und registrieren
```bash
# --------------------------------------------------
# Install forgejo-runner
# --------------------------------------------------
cd /tmp
VERSION="$(curl --silent -qI https://code.forgejo.org/forgejo/runner/releases/latest | awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}')"
# ${VERSION} = v6.3.1
# ${VERSION#v} = 6.3.1

wget -O forgejo-runner https://code.forgejo.org/forgejo/runner/releases/download/${VERSION}/forgejo-runner-${VERSION#v}-linux-arm64
chmod +x forgejo-runner
sudo cp forgejo-runner /usr/local/bin/forgejo-runner 
sudo chmod +x /usr/local/bin/forgejo-runner

forgejo-runner -v    
# forgejo-runner version v6.3.1

# --------------------------------------------------
# Runner registration token
# --------------------------------------------------
forgejo -> site-administration -> actions -> runners
Runner registration token: CTPixgzT3IhN8kHN4lliyFdpibjebsPUFhmsVU0t

# --------------------------------------------------
# Wichtig!!
# In das Home Verzeichnis wechseln, bevor der runner registriert wird. 
# Hier wird eine ~/.runner Datei angelegt die für den Start des Service benötigt wird!
# --------------------------------------------------
cd ~

# forgejo-runner generate-config > config.yml
forgejo-runner register --instance "https://git.htdom.local" --token "CTPixgzT3IhN8kHN4lliyFdpibjebsPUFhmsVU0t" --name "$(hostname -f)" --labels "docker" --no-interactive

# --------------------------------------------------
# forgejo-runner.service
# --------------------------------------------------
sudo vi /etc/systemd/system/forgejo-runner.service

[Unit]
Description=Forgejo Runner
After=network.target

[Service]
User=hth
Group=hth
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
WorkingDirectory=/home/hth
ExecStart=/usr/local/bin/forgejo-runner daemon
Restart=on-failure

[Install]
WantedBy=multi-user.target

sudo systemctl daemon-reload
sudo systemctl enable --now forgejo-runner.service
sudo systemctl status forgejo-runner.service
```
#### Renovate-Bot integrieren
Um den Renovate Bot in Git zu integrieren, wurde ein neues Repository mit dem Namen "**hth/renovate-config**" angelegt mit folgender globalen Konfigurationsdatei "**config.js**".
Zusätzlich waren noch ein paar Vorbereitungen am Git Server selbst zu tätigen.

```bash
## Benutzer anlegen mit dem Namen "Renovate Bot" und irgendeiner E-Mail Adresse
## PAT - Personal Access Token für Renovate Benutzer erstellen (user/read, repo/read and write, org/read, issue/read and write)
## Den Renovate Bot Benutzer allen Repos als Collaborators mit Write Rechten hinzufügen.

Forgejo API Browser Endpoint: https://git.htdom.local/api/swagger

# Zugriff mit dem Renovate Benutzer testen
PAT="c06c0938245b46a66b5ace570e74feb6b50949e2" 
curl -sk -H "Authorization: token ${PAT}" "https://git.htdom.local/api/v1/user" | jq -r '.'
# {
#   "id": 2,
#   "login": "renovate",
#   "login_name": "",
#   "source_id": 0,
#   "full_name": "Renovate Bot",
#   "email": "hellemon@live.de",
#   "avatar_url": "https://git.htdom.local/avatars/17563fdf630a4a7f401874369a6234d901a9aeb2355d52b57f6e07f80af40f83",
#   "html_url": "https://git.htdom.local/renovate",
#   "language": "en-US",
#   "is_admin": false,
#   "last_login": "2025-02-28T10:56:49+01:00",
#   "created": "2025-02-28T10:39:20+01:00",
# ...
#   "username": "renovate"
# }

curl -sk -H "Authorization: token ${PAT}" "https://git.htdom.local/api/v1/repos/hth/docker" | jq -r '.'
curl -sk -X GET -H "Authorization: token ${PAT}" "https://git.htdom.local/api/v1/repos/hth/docker/actions/runs" | jq -r '.'
```
##### config.js
```json
module.exports = {
  "endpoint": "https://git.htdom.local/api/v1",
  "gitAuthor": "Renovate Bot <hth@htdom.local>",
  "platform": "gitea",
  "onboardingConfigFileName": "renovate.json",
  "autodiscover": true,
  "optimizeForDisabled": true,
};
```

Im Haupt Repository (hth/docker) das später überwacht werden soll, wurde eine "**renovate.json**" Datei mit folgenden Inhalt angelegt.
##### renovate.json
```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "timezone": "Europe/Berlin",
  "automerge": true,
  "automergeType": "branch",
  "prCreation": "always",
  "packageRules": [
    {
      "matchUpdateTypes": ["minor", "patch"],
      "automerge": true
    },
    {
      "matchManagers": ["docker-compose"],
      "enabled": true,
      "matchPackageNames": ["*"]
    },
    {
      "matchDatasources": ["docker"],
      "matchPackageNames": ["renovate/renovate"],
      "registryUrls": ["http://registry.htdom.local"],
      "automerge": false
    },
    {
      "matchManagers": ["github-actions"],
      "enabled": true
    }
  ]
}
```
#### GitHub Actions integrieren für renovate-Bot
```bash
mkdir -p ~/docker/.forgejo/workflows

## Personal Access Token (PAT) für Renovate Benutzer im Repository als Secret anlegen Settings --> Actions --> Secrets
## RENOVATE_TOKEN=c06c0938245b46a66b5ace570e74feb6b50949e2
```

Im Repository "**hth/docker**" findet man den Punkt "**Actions**" dort kann man nun beide hinzugefügte Actions manuell ausführen.
Eine Action wurde nur erstellt, um mir alle Forgejo Variablen auszugeben zu lassen, die man so in den GitHub Actions verwendet könnte.
Die Renovate Action wird täglich um 00:00 Uhr ausgeführt und eröffnet einen Merge Request, sobald er Änderungen findet.
Hier in den Actions kommt das selbstgebaute Renovate Docker Image zu Einsatz, das hier beschreiben ist. [[registry.htdom.local]]
Ich habe das Renovate Docker Image nur auf die Major Version (39) beschränkt, da hier fast alle zwei/drei Tage im Patch Level ein Update erfolgte. 
Und ich nicht jeden Tag 1,2 GB runterladen wollte. Im Live Betrieb würde ich aber immer, ein Major.Minor.Patch in der Version angeben.
##### .forgejo/workflows/renovate.yaml
```yaml
name: renovate-bot

on:
  workflow_dispatch:
  schedule:
    - cron: "@daily"

jobs:
  renovate:
    runs-on: docker
    container: registry.htdom.local/renovate/renovate:39

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Checkout Renovate Config
        uses: actions/checkout@v4
        with:
          repository: "hth/renovate-config"
          ref: "master"
          path: "renovate-config"
          token: ${{ secrets.RENOVATE_TOKEN }}

      - name: Run Renovate
        run: renovate
        env:
          RENOVATE_CONFIG_FILE: "renovate-config/config.js"
          LOG_LEVEL: "debug"
          RENOVATE_TOKEN: ${{ secrets.RENOVATE_TOKEN }}
```
##### .forgejo/workflows/show_variables.yaml
```yaml
name: Show Environment Variables

on:
  workflow_dispatch:

jobs:
  show-vars:
    runs-on: docker
    container: registry.htdom.local/renovate/renovate:39
    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Show environment variables
        run: |
          echo "Displaying all environment variables:"
          printenv
```

