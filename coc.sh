#!/usr/bin/env bash
set -e

NAMESPACE="dev-datenhaus-index"
CLUSTER_NAME="playground-opensearch-cluster"
KEY_BITS=4096

# Pools und ihre jeweilige Replica-Anzahl (0-indexed)
# Format: "POOL_NAME:REPLICA_COUNT"
POOLS=(
  "masters:3"
  "coordinator:3"
  "data:3"
  # Später einfach erweiterbar, z.B.:
  # "data-az1:3"
  # "data-az2:3"
)

# 1. Admin Client Certificate
echo "=== 1. Admin Client Certificate ==="
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


# 2. HTTP Certificate (REST / Probes)
echo "=== 2. HTTP Certificate ==="
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


# 3. Dynamische Transport-Zertifikate pro Pool & Replica
echo "=== 3. Transport Certificates per Pool & Replica ==="

for ITEM in "${POOLS[@]}"; do
  POOL_NAME="${ITEM%%:*}"
  REPLICAS="${ITEM##*:}"
  
  POOL_ENDPOINT="${CLUSTER_NAME}-${POOL_NAME}"

  for (( i=0; i<REPLICAS; i++ )); do
    NODE_NAME="${CLUSTER_NAME}-${POOL_NAME}-${i}"
    
    echo "--> Generating Cert for ${NODE_NAME} (Pool: ${POOL_NAME})"
    openssl genrsa -out "${NODE_NAME}.key" ${KEY_BITS}

    cat <<EOF > "${NODE_NAME}_ext.cnf"
[ req ]
default_bits       = ${KEY_BITS}
distinguished_name = req_distinguished_name
req_extensions     = v3_req
prompt             = no

[ req_distinguished_name ]
CN = ${NODE_NAME}
OU = ${NAMESPACE}

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[ alt_names ]
# Loopback (Zwingend für K8s 1.34 Probes)
DNS.1 = localhost
IP.1  = 127.0.0.1

# Node Pod Hostnames
DNS.2 = ${NODE_NAME}
DNS.3 = ${NODE_NAME}.${NAMESPACE}
DNS.4 = ${NODE_NAME}.${NAMESPACE}.svc
DNS.5 = ${NODE_NAME}.${NAMESPACE}.svc.cluster.local

# Cluster Discovery Endpoint
DNS.6 = ${CLUSTER_NAME}
DNS.7 = ${CLUSTER_NAME}.${NAMESPACE}.svc.cluster.local

# Pool-spezifischer Service Endpoint
DNS.8  = ${POOL_ENDPOINT}
DNS.9  = ${POOL_ENDPOINT}.${NAMESPACE}
DNS.10 = ${POOL_ENDPOINT}.${NAMESPACE}.svc
DNS.11 = ${POOL_ENDPOINT}.${NAMESPACE}.svc.cluster.local

# Pool Wildcards
DNS.12 = *.${POOL_ENDPOINT}
DNS.13 = *.${POOL_ENDPOINT}.${NAMESPACE}.svc.cluster.local
DNS.14 = *.${NAMESPACE}.svc.cluster.local
EOF

    openssl req -new -key "${NODE_NAME}.key" -out "${NODE_NAME}.csr" -config "${NODE_NAME}_ext.cnf"
    openssl x509 -req -in "${NODE_NAME}.csr" -CA rootCA.crt -CAkey rootCA.key -CAcreateserial \
        -out "${NODE_NAME}.crt" -days 730 -sha256 -extfile "${NODE_NAME}_ext.cnf" -extensions v3_req

    rm -f "${NODE_NAME}_ext.cnf" "${NODE_NAME}.csr"
  done
done

# Aufräumen
rm -f admin_ext.cnf admin.csr http_ext.cnf http.csr

echo "=== Fertig! Alle Zertifikate voll-dynamisch generiert. ==="