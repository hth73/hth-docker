# oidc.htdom.local

Um sich an Grafana über OpenID Connect und Passkey anmelden zu können wurde dieser Service installiert.

> https://oidc.htdom.local/login

<a href="images/pocket_id.jpg" target="_blank"><img src="images/pocket_id.jpg" alt="Pocket ID Login" title="Pocket ID Login" width="460" height="230" /></a>

---
#### Inhaltsverzeichnis

* [Ordner-Struktur](#ordner-struktur---top-of-page)
  * [~/docker/docker-compose.yaml](#dockerdocker-composeyaml---top-of-page)
  * [~/docker/caddy/config/Caddyfile](#dockercaddyconfigcaddyfile---top-of-page)
* [Pocket-ID Konfiguration](#pocket-id-konfiguration---top-of-page)
* [~/docker/grafana/config/grafana.ini](#dockergrafanaconfiggrafanaini---top-of-page)
* [OIDC API Abfragen](#oidc-api-abfragen---top-of-page)
---

#### Ordner-Struktur - [Top of Page](#inhaltsverzeichnis)
```bash
sudo vi /etc/hosts
# <Docker-Host IP-Adresse> oidc.htdom.local

mkdir -p /opt/pocketid/data
```

#### ~/docker/docker-compose.yaml - [Top of Page](#inhaltsverzeichnis)
```yaml
  oidc:
    image: ghcr.io/pocket-id/pocket-id:v0.44
    container_name: oidc
    hostname: oidc.${FQDN}
    user: root
    restart: always
    volumes:
      - "/opt/pocketid/data:/app/backend/data"
    environment:
      PUBLIC_APP_URL: "https://oidc.htdom.local"
      ALLOWED_ORIGINS: "https://oidc.htdom.local"
      TRUST_PROXY: "true"
      PORT: "3002"
      APP_NAME: "HTH OIDC"
    ports:
      - 3002:80
```

#### ~/docker/caddy/config/Caddyfile - [Top of Page](#inhaltsverzeichnis)
```yaml
oidc.htdom.local {
  tls internal
  reverse_proxy http://oidc.htdom.local:3002 {
    header_up Host {host}
    header_up X-Forwarded-Proto {scheme}
    header_up X-Forwarded-For {remote}
  }
}
```

#### Pocket-ID Konfiguration - [Top of Page](#inhaltsverzeichnis)

Nach dem ersten start des Pocket ID Containers, schließt man das Setup ab. https://oidc.htdom.local/login/setup
Hier richtet man sich den ersten Admin Benutzer ein und hinterlegt einen Passkey für die Anmeldung. Danach kann man sich abmelden und die Anmeldung mit dem Passkey testen

Dann legt man sich weitere Benutzer an, diese bekommen nach dem erstellen einen "Login Code"
Sieht wie folgt aus "https://oidc.htdom.local/lc/0hkn4mNDx6TRC4N0" Diese URL ist dann für 1 Stunde gültig.
Damit kann sich der Benutzer nun anmelden und ebenfalls einen Passkey einrichten.

Um das OAuth für Grafana zu konfigurieren, wurden nun drei neue "**User Groups**" angelegt und die Gruppen den Benutzern zugewiesen.

> [User Groups]
> - grafana-admin  
> - grafana-editor  
> - grafana-viewer

Auch wurde ein neuer "**OIDC Client**" angelegt.
> [OIDC Client]  
> - grafana-auth - Callback URLs: https://grafana.htdom.local/login/generic_oauth

Folgende Information bekommt man nach der Anlage des OIDC Clients, diese nutzen wir um das OAuth in der "**grafana.ini**" zu konfigurieren.

>[OIDC Client Information]  
Client ID: 2582785a-bc7e-4445-b1f7-0d8cf3053be4  
Client secret: xxx  
Authorization URL: https://oidc.htdom.local/authorize  
OIDC Discovery URL: https://oidc.htdom.local/.well-known/openid-configuration  
Token URL: https://oidc.htdom.local/api/oidc/token  
Userinfo URL: https://oidc.htdom.local/api/oidc/userinfo  
Logout URL: https://oidc.htdom.local/api/oidc/end-session  
Certificate URL: https://oidc.htdom.local/.well-known/jwks.json  
PKCE: Disabled

#### ~/docker/grafana/config/grafana.ini - [Top of Page](#inhaltsverzeichnis)
```html
[auth]
  disable_login_form = false
  oauth_auto_login = false
  login_cookie_name = grafana_session
  oauth_state_cookie_max_age = 60
  enable_login_token = true
  oauth_allow_insecure_email_lookup=true
...

[auth.generic_oauth]
  enabled = true
  name = HTH-OIDC-OAuth
  allow_sign_up = true
  use_pkce = true
  client_id = 2582785a-bc7e-4445-b1f7-0d8cf3053be4
  client_secret = xxx
  scopes = openid email profile groups
  email_attribute_path = email
  login_attribute_path = preferred_username
  name_attribute_path = name
  auth_url = https://oidc.htdom.local/authorize
  token_url = https://oidc.htdom.local/api/oidc/token
  api_url = https://oidc.htdom.local/api/oidc/userinfo
  tls_skip_verify_insecure = true
  skip_org_role_sync = false
  allow_assign_grafana_admin = true
  role_attribute_strict = true
  role_attribute_path = contains(groups[*], 'grafana-admin') && 'Admin' || contains(groups[*], 'grafana-editor') && 'Editor' || 'Viewer'
```

#### OIDC API Abfragen - [Top of Page](#inhaltsverzeichnis)
```bash
## Für den Admin wurde in der UI ein API Token für ein paar Stunden angelegt, mit diesen können wir die API abfragen.
##
API-Key = iT7cNNgMPKAXx5xwZu5lVgulDBGxS1RT

## JSON Web Key Set (JWKS)
##
curl -sk -L 'https://oidc.htdom.local/.well-known/jwks.json' -H 'Accept: application/json' | jq -r '.'
# {
#   "keys": [
#     {
#       "alg": "RS256",
#       "e": "AQAB",
#       "kid": "nwPgodMraGo",
#       "kty": "RSA",
#       "n": "uWl....................................q0w",
#       "use": "sig"
#     }
#   ]
# }

## Alle OIDC Endpunkte anzeigen lassen
##
curl -sk -L 'https://oidc.htdom.local/.well-known/openid-configuration' -H 'Accept: */*' | jq -r '.'
# {
#   "authorization_endpoint": "https://oidc.htdom.local/authorize",
#   "claims_supported": [
#     "sub",
#     "given_name",
#     "family_name",
#     "name",
#     "email",
#     "email_verified",
#     "preferred_username",
#     "picture",
#     "groups"
#   ],
#   "end_session_endpoint": "https://oidc.htdom.local/api/oidc/end-session",
#   "grant_types_supported": [
#     "authorization_code",
#     "refresh_token"
#   ],
#   "id_token_signing_alg_values_supported": [
#     "RS256"
#   ],
#   "issuer": "https://oidc.htdom.local",
#   "jwks_uri": "https://oidc.htdom.local/.well-known/jwks.json",
#   "response_types_supported": [
#     "code",
#     "id_token"
#   ],
#   "scopes_supported": [
#     "openid",
#     "profile",
#     "email",
#     "groups"
#   ],
#   "subject_types_supported": [
#     "public"
#   ],
#   "token_endpoint": "https://oidc.htdom.local/api/oidc/token",
#   "userinfo_endpoint": "https://oidc.htdom.local/api/oidc/userinfo"
# }

## Alle API Keys anzeigen lassen
##
curl -sk -H 'X-Api-Key: iT7cNNgMPKAXx5xwZu5lVgulDBGxS1RT' -X GET 'https://oidc.htdom.local/api/api-keys' -H 'Accept: */*' | jq -r '.'
# {
#   "data": [
#     {
#       "id": "c280ba87-80bc-40b3-b454-6e84c606c494",
#       "name": "admin",
#       "description": "",
#       "expiresAt": "2025-04-28T22:00:00Z",
#       "lastUsedAt": "2025-03-29T12:09:56Z",
#       "createdAt": "2025-03-29T11:56:26Z"
#     }
#   ],
#   "pagination": {
#     "totalPages": 1,
#     "totalItems": 1,
#     "currentPage": 1,
#     "itemsPerPage": 20
#   }
# }

## Alle Benutzer anzeigen lassen
##
curl -sk -H 'X-Api-Key: iT7cNNgMPKAXx5xwZu5lVgulDBGxS1RT' -L 'https://oidc.htdom.local/api/users' -H 'Accept: */*' | jq -r '.'
# {
#   "data": [
#     {
#       "id": "b23a48b8-6cbf-46f9-ba83-d03e8a8d6cc2",
#       "username": "admin",
#       "email": "admin@htdom.local",
#       "firstName": "Admin",
#       "lastName": "Pocket-ID",
#       "isAdmin": true,
#       "locale": null,
#       "customClaims": [],
#       "userGroups": [],
#       "ldapId": null
#     },
#     {
#       "id": "8da8e913-6b4e-411a-8495-70a7a1546207",
#       "username": "hth",
#       "email": "hth@htdom.local",
#       "firstName": "Helmut",
#       "lastName": "Thurnhofer",
#       "isAdmin": true,
#       "locale": null,
#       "customClaims": [],
#       "userGroups": [],
#       "ldapId": null
#     }
#   ],
#   "pagination": {
#     "totalPages": 1,
#     "totalItems": 2,
#     "currentPage": 1,
#     "itemsPerPage": 20
#   }
# }

## Benutzer IDs anzeigen lassen
##
curl -sk -H 'X-Api-Key: iT7cNNgMPKAXx5xwZu5lVgulDBGxS1RT' -L 'https://oidc.htdom.local/api/users' -H 'Accept: */*' | jq -r '.data[] | "\(.id) \(.username)"'
# b23a48b8-6cbf-46f9-ba83-d03e8a8d6cc2 admin
# 8da8e913-6b4e-411a-8495-70a7a1546207 hth

## Einen Access Token für einen bestimmten Benutzer mit Ablaufdatum anlegen
##
curl -sk -H 'X-Api-Key: iT7cNNgMPKAXx5xwZu5lVgulDBGxS1RT' -L 'https://oidc.htdom.local/api/users/:id/one-time-access-token' \
-H 'Content-Type: application/json' \
-H 'Accept: */*' \
-d '{
  "expiresAt": "2025-04-30T22:00:00Z",
  "userId": "8da8e913-6b4e-411a-8495-70a7a1546207"
}'
# {"token":"rjzinf7V55IAtZ3S"}

## Benutzerinformationen abfragen mit API und Access Token
##
curl -sk -H 'X-Api-Key: iT7cNNgMPKAXx5xwZu5lVgulDBGxS1RT' -H 'Authorization: Bearer rjzinf7V55IAtZ3S' \
-L 'https://oidc.htdom.local/api/users/8da8e913-6b4e-411a-8495-70a7a1546207' \
-H 'Accept: */*' | jq -r '.'
# {
#   "id": "8da8e913-6b4e-411a-8495-70a7a1546207",
#   "username": "hth",
#   "email": "hth@htdom.local",
#   "firstName": "Helmut",
#   "lastName": "Thurnhofer",
#   "isAdmin": true,
#   "locale": null,
#   "customClaims": [],
#   "userGroups": [
#     {
#       "id": "97d5e202-7749-4d1d-bf23-17ea79ed0834",
#       "friendlyName": "grafana-admin",
#       "name": "grafana-admin",
#       "customClaims": [],
#       "ldapId": null,
#       "createdAt": "2025-03-28T12:30:03Z"
#     }
#   ],
#   "ldapId": null
# }

curl -sk -X POST https://oidc.htdom.local/api/oidc/token \
  -d "client_id=2582785a-bc7e-4445-b1f7-0d8cf3053be4" \
  -d "client_secret=YvjkGbMchdu3iBXuoTBRUAeIFkIJwYvj" \
  -d "grant_type=authorization_code" \
  -d "code=iT7cNNgMPKAXx5xwZu5lVgulDBGxS1RT" \
  -d "redirect_uri=https://grafana.htdom.local/login/generic_oauth"
```
