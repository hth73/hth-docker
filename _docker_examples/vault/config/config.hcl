ui = true
disable_mlock = "true"

storage "raft" {
  path    = "/vault/data"
  node_id = "vault1"
}

listener "tcp" {
  address = "[::]:8200"
  tls_disable = "false"
  tls_cert_file = "/certs/vault.htdom.local.crt"
  tls_key_file  = "/certs/vault.htdom.local.key"
}

api_addr = "https://vault.htdom.local:8200"
cluster_addr = "https://vault.htdom.local:8201"

