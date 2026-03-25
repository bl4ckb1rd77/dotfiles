Das ist ein sehr guter Schritt für eine saubere Vault-Struktur. Wenn du mehrere Teams oder Projekte auf einem Vault-Server hast, ist ein Prefix wie cw-tech-pki Gold wert, um Namenskollisionen zu vermeiden.

Hier sind die angepassten Befehle, bei denen wir den Standardpfad pki durch deinen spezifischen Pfad ersetzen.

1. PKI unter dem spezifischen Pfad einrichten
Der -path Parameter beim Aktivieren ist hier entscheidend.

Bash

# 1. PKI Secrets Engine an deinem Wunschpfad aktivieren
vault secrets enable -path=cw-tech-pki pki

# 2. Maximale Laufzeit für diesen spezifischen Mount setzen
vault secrets tune -max-lease-ttl=87600h cw-tech-pki

# 3. Root-Zertifikat generieren (Pfad beginnt jetzt mit cw-tech-pki)
vault write cw-tech-pki/root/generate/internal \
    common_name="CW-Tech Opensearch Root CA" \
    ttl=87600h \
    organization="CW-Tech"
2. Die Rolle im neuen Pfad erstellen
Jeder Aufruf muss nun über den neuen Mount-Point erfolgen.

Bash

vault write cw-tech-pki/roles/opensearch-dev-role \
    allow_any_name=true \
    enforce_hostnames=false \
    max_ttl="720h" \
    generate_lease=true \
    organization="CW-Tech" \
    ou="dev-opensearch-cluster" \
    key_usage="DigitalSignature,KeyEncipherment" \
    ext_key_usage="ServerAuth,ClientAuth"
3. Angepasste Policy
Hier ist es besonders wichtig, den Pfad exakt so anzugeben, wie er in Vault gemountet wurde.

Bash

vault policy write os-policy-dev - <<EOF
# Zugriff auf die Zertifikatsausstellung im cw-tech-pki Mount
path "cw-tech-pki/issue/opensearch-dev-role" {
  capabilities = ["update"]
}

# Zugriff auf das CA-Zertifikat zum Validieren
path "cw-tech-pki/cert/ca" {
  capabilities = ["read"]
}
EOF
4. Kubernetes Auth Role
Die Auth-Rolle selbst ändert sich kaum, sie zeigt lediglich auf die aktualisierte Policy.

Bash

vault write auth/kubernetes/role/os-auth-role-dev \
    bound_service_account_names="*" \
    bound_service_account_namespaces="dev-datenbank-info" \
    token_policies="os-policy-dev" \
    token_ttl="1h"
Was du jetzt in deinem Helm-Chart / der values.yaml ändern musst
Damit der Vault Secrets Operator (VSO) die Zertifikate findet, musst du in deiner Konfiguration den mount Parameter anpassen. Deine values.yaml sollte nun so aussehen:

YAML

# values.yaml
vault:
  authRef: "vault-auth-dev"
  pkiMount: "cw-tech-pki" # <--- Hier dein neuer Pfad!
  roles:
    admin: "opensearch-dev-role"
    transport: "opensearch-dev-role" # Falls du die gleiche Rolle nutzt
Ein kleiner "Pro-Tipp" für den Test
Wenn du prüfen willst, ob der Pfad korrekt funktioniert, kannst du vorab manuell ein Test-Zertifikat anfordern:

Bash

vault write cw-tech-pki/issue/opensearch-dev-role common_name="test-cert"
Wenn Vault dir hier ein JSON mit certificate, private_key und issuing_ca zurückgibt, ist der Weg frei für dein Helm Chart!
