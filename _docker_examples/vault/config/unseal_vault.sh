#!/usr/bin/env bash
set -e

# get unseal-keys from gopass
key1=$(gopass gitstore/vault.htdom.local/unseal-key-1)
key2=$(gopass gitstore/vault.htdom.local/unseal-key-2)
key3=$(gopass gitstore/vault.htdom.local/unseal-key-3)

vault operator unseal -tls-skip-verify ${key1}
vault operator unseal -tls-skip-verify ${key2}
vault operator unseal -tls-skip-verify ${key3}

clear

