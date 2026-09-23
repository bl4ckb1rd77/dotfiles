#!/usr/bin/env bash
set -e

NAMESPACE="dev-datenhaus-index"
CLUSTER_NAME="playground-opensearch-cluster"
KEY_BITS=4096

# Assumes rootCA.crt and rootCA.key are present in current directory

echo "=== 1. Admin Client Certificate (4096 Bit RSA) ==="
openssl genrsa -out admin.key ${KEY_BITS}

cat <<EOF > admin_ext.cnf
[ req ]
default_bits       = ${KEY_BITS}
distinguished_name = req_distinguished_name
prompt             = no

[ req_distinguished_name ]
CN = admin
OU = ${NAMESPACE}

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
EOF

openssl req -new -key admin.key -out admin.csr -config admin_ext.cnf
openssl x509 -req -in admin.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial \
    -out admin.crt -days 730 -sha256 -extfile admin_ext.cnf -extensions v3_req


echo "=== 2. HTTP Certificate (4096 Bit RSA) ==="
openssl genrsa -out http.key ${KEY_BITS}

cat <<EOF > http_ext.cnf
[ req ]
default_bits       = ${KEY_BITS}
distinguished_name = req_distinguished_name
req_extensions     = v3_req
prompt             = no

[ req_distinguished_name ]
CN = ${CLUSTER_NAME}
OU = ${NAMESPACE}

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = localhost
IP.1  = 127.0.0.1
DNS.2 = ${CLUSTER_NAME}
DNS.3 = ${CLUSTER_NAME}.${NAMESPACE}
DNS.4 = ${CLUSTER_NAME}.${NAMESPACE}.svc
DNS.5 = ${CLUSTER_NAME}.${NAMESPACE}.svc.cluster.local
DNS.6 = *.${CLUSTER_NAME}
DNS.7 = *.${CLUSTER_NAME}.${NAMESPACE}.svc.cluster.local
DNS.8 = *.${NAMESPACE}.svc.cluster.local
EOF

openssl req -new -key http.key -out http.csr -config http_ext.cnf
openssl x509 -req -in http.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial \
    -out http.crt -days 730 -sha256 -extfile http_ext.cnf -extensions v3_req


echo "=== 3. Transport Certificates per Node (4096 Bit RSA) ==="
NODES=(
  "playground-opensearch-cluster-coordinator-0"
  "playground-opensearch-cluster-coordinator-1"
  "playground-opensearch-cluster-coordinator-2"
  "playground-opensearch-cluster-data-0"
  "playground-opensearch-cluster-data-1"
  "playground-opensearch-cluster-data-2"
  "playground-opensearch-cluster-masters-0"
  "playground-opensearch-cluster-masters-1"
  "playground-opensearch-cluster-masters-2"
)

for NODE in "${NODES[@]}"; do
  echo "--> Generating 4096 Bit Transport Cert for ${NODE}"
  
  openssl genrsa -out "${NODE}.key" ${KEY_BITS}

  cat <<EOF > "${NODE}_ext.cnf"
[ req ]
default_bits       = ${KEY_BITS}
distinguished_name = req_distinguished_name
req_extensions     = v3_req
prompt             = no

[ req_distinguished_name ]
CN = ${NODE}
OU = ${NAMESPACE}

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = localhost
IP.1  = 127.0.0.1
DNS.2 = ${NODE}
DNS.3 = ${NODE}.${NAMESPACE}
DNS.4 = ${NODE}.${NAMESPACE}.svc
DNS.5 = ${NODE}.${NAMESPACE}.svc.cluster.local
DNS.6 = ${CLUSTER_NAME}
DNS.7 = ${CLUSTER_NAME}.${NAMESPACE}.svc.cluster.local
DNS.8 = *.${NAMESPACE}.svc.cluster.local
EOF

  openssl req -new -key "${NODE}.key" -out "${NODE}.csr" -config "${NODE}_ext.cnf"
  openssl x509 -req -in "${NODE}.csr" -CA rootCA.crt -CAkey rootCA.key -CAcreateserial \
      -out "${NODE}.crt" -days 730 -sha256 -extfile "${NODE}_ext.cnf" -extensions v3_req

  rm -f "${NODE}_ext.cnf" "${NODE}.csr"
done

rm -f admin_ext.cnf admin.csr http_ext.cnf http.csr
echo "=== Done! All 4096-bit certificates successfully generated ==="