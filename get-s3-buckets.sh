#!/bin/bash

VRA_HOST="aria.ihre-domain.internal"

# Temporäre Datei für die gesammelten Daten
OUTPUT_FILE="all_buckets_combined.tsv"
> "$OUTPUT_FILE"

# Funktion für den Durchlauf pro Projekt/User
process_project() {
    local proj_name="$1"
    local svc_u="$2"
    local svc_p="$3"

    echo "------------------------------------------------------------------"
    echo "Verarbeite Projekt: $proj_name..."
    echo "------------------------------------------------------------------"

    # 1. Refresh Token holen (mit dem fixierten JSON-Payload und dem *-d@* Trick, falls nötig, oder direkt mit sauberen Quotes)
    local login_payload
    login_payload=$(jq -n --arg u "$svc_u" --arg p "$svc_p" '{username: $u, password: $p}')
    
    local refresh_res
    refresh_res=$(curl -s -k -X POST "https://$VRA_HOST/csp/gateway/am/api/login" \
      -H "Content-Type: application/json" \
      -d "$login_payload")
    
    local refresh_token
    refresh_token=$(echo "$refresh_res" | jq -r '.refresh_token' | tr -d '[:space:]')

    if [ -z "$refresh_token" ] || [ "$refresh_token" = "null" ]; then
        echo "[$proj_name] Fehler beim Login! Überspringe Projekt."
        return
    fi

    # 2. Access Token über den IaaS-Login holen (mit dem funktionierenden JSON-Trick)
    local iaas_payload
    iaas_payload=$(jq -n --arg rt "$refresh_token" '{refreshToken: $rt}')

    local token_res
    token_res=$(curl -s -k -X POST "https://$VRA_HOST/iaas/api/login" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      -d "$iaas_payload")

    local access_token
    access_token=$(echo "$token_res" | jq -r '.token' | tr -d '[:space:]')

    if [ -z "$access_token" ] || [ -z "$access_token" = "null" ]; then
        echo "[$proj_name] Fehler beim IaaS-Login! Überspringe Projekt."
        return
    fi

    echo "[$proj_name] Erfolgreich eingeloggt. Hole Ressourcen-Liste..."

    # 3. Ressourcen abrufen und Deployment-IDs extrahieren
    local resources_res
    resources_res=$(curl -s -k -X GET "https://$VRA_HOST/deployment/api/resources?resourceType=Custom.S3.bucket" \
      -H "Accept: application/json" \
      -H "Authorization: Bearer $access_token")

    # Alle Deployment-IDs einsammeln (Duplikate rausfiltern falls nötig)
    local deployment_ids
    deployment_ids=$(echo "$resources_res" | jq -r '.content[]? | .deploymentId' | grep -v 'null' | sort -u)

    if [ -z "$deployment_ids" ]; then
        echo "[$proj_name] Keine Deployments gefunden."
        return
    fi

    # 4. Über jede Deployment-ID iterieren und userEvents abfragen
    for dep_id in $deployment_ids; do
        local events_res
        events_res=$(curl -s -k -X GET "https://$VRA_HOST/deployment/api/deployments/$dep_id/userEvents" \
          -H "Accept: application/json" \
          -H "Authorization: Bearer $access_token")

        # Daten pro Event extrahieren und als TSV ausgeben
        # Felder: DeploymentID, Name, BlockSize, ServerSideEncryption, NetworkZone, TransferBucket
        echo "$events_res" | jq -r --arg did "$dep_id" '.content[]? | [
            $did,
            (.inputs.bucketname // .name // "N/A"),
            (.inputs.blockSize // "N/A"),
            (.inputs.serversideEncryption // "false"),
            (.inputs.networkZone // "N/A"),
            (.inputs.transferBucket // "N/A")
        ] | @tsv' >> "$OUTPUT_FILE"
    done

    echo "[$proj_name] Fertig."
}

# --- Hier deine 2 Projekt-User eintragen ---
process_project "Projekt-1" "mein_user_1" "mein_pass_1"
process_project "Projekt-2" "mein_user_2" "mein_pass_2"

echo ""
echo "=================================================================="
echo "Alle Daten gesammelt! Erstelle Confluence Markdown-Tabelle..."
echo "=================================================================="

# Markdown-Kopf ausgeben
echo "| Deployment-ID | Bucket-Name | Block-Größe | SSE (Verschlüsselung) | Netzwerk-Zone | Transfer-Bucket |"
echo "|---|---|---|---|---|---|"

# Aus der gesammelten Datei eine schöne Markdown-Tabelle machen
if [ -s "$OUTPUT_FILE" ]; then
    awk -F'\t' '{print "| " $1 " | " $2 " | " $3 " | " $4 " | " $5 " | " $6 " |"}' "$OUTPUT_FILE"
else
    echo "Keine Daten gefunden."
fi