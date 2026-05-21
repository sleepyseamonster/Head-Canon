#!/usr/bin/env bash

set -euo pipefail

IDENTITY_NAME="${HEAD_CANON_LOCAL_CODESIGN_IDENTITY:-HeadCanon Local Signing}"
KEYCHAIN_PATH="${HOME}/Library/Keychains/login.keychain-db"
TMP_DIR="$(mktemp -d)"
PASS_PHRASE="$(uuidgen | tr '[:upper:]' '[:lower:]')"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

if security find-identity -v -p codesigning 2>/dev/null | grep -Fq "\"$IDENTITY_NAME\""; then
  echo "Using existing code-signing identity: $IDENTITY_NAME" >&2
  exit 0
fi

cat > "$TMP_DIR/openssl.cnf" <<EOF
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = codesign_ext

[ dn ]
CN = ${IDENTITY_NAME}
O = HeadCanon Local Development
C = US

[ codesign_ext ]
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature
extendedKeyUsage = codeSigning
subjectKeyIdentifier = hash
EOF

openssl req \
  -new \
  -newkey rsa:2048 \
  -nodes \
  -x509 \
  -days 3650 \
  -keyout "$TMP_DIR/headcanon-local.key" \
  -out "$TMP_DIR/headcanon-local.crt" \
  -config "$TMP_DIR/openssl.cnf" \
  >/dev/null 2>&1

openssl pkcs12 \
  -legacy \
  -export \
  -inkey "$TMP_DIR/headcanon-local.key" \
  -in "$TMP_DIR/headcanon-local.crt" \
  -out "$TMP_DIR/headcanon-local.p12" \
  -passout "pass:${PASS_PHRASE}" \
  >/dev/null 2>&1

security import \
  "$TMP_DIR/headcanon-local.p12" \
  -k "$KEYCHAIN_PATH" \
  -P "$PASS_PHRASE" \
  -x \
  -T /usr/bin/codesign \
  -T /usr/bin/security \
  >/dev/null

security add-trusted-cert \
  -r trustAsRoot \
  -p codeSign \
  -k "$KEYCHAIN_PATH" \
  "$TMP_DIR/headcanon-local.crt" \
  >/dev/null

if ! security find-identity -v -p codesigning 2>/dev/null | grep -Fq "\"$IDENTITY_NAME\""; then
  echo "Failed to register a usable code-signing identity named: $IDENTITY_NAME" >&2
  exit 1
fi

echo "Created local code-signing identity: $IDENTITY_NAME" >&2
