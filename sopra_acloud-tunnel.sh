#!/usr/bin/env bash

###
# Version 1.4
# mit SSL Verify unf Skip für Sopra (missing AKI in Root)
# und switch to port 443 - i sopra netzwerk wird port 22 geblockt.
# also kein ssh portforwarding
#

set -uo pipefail

# --- PARAMETER PARSING ---
USE_NERD_FONTS="false"
for arg in "${@:-}"; do
    case "$arg" in
        --nf|-nf)
            USE_NERD_FONTS="true"
            ;;
    esac
done

# --- CONFIGURATION ---
BASTION_TOOLS="ocid1.bastion.oc19.eu-frankfurt-2.amaaaaaaatrirsaapy5mbr2vnxjcx6d7uiilrujjtg4yv2wgnstlykrfexlq"
BASTION_ARGO="ocid1.bastion.oc19.eu-frankfurt-2.amaaaaaaatrirsaalwg32xpie4fr7ypsjosjxuz7hpipikmekhg6ibet6mpa"
SSH_KEY="$HOME/.ssh/id_ed25519"
SSH_PUB_KEY="$HOME/.ssh/id_ed25519.pub"
COMPANY_CA_PATH="$HOME/.oci/cooperate-ca.crt"
CA_BUNDLE=""
TLS_SKIP=""

# Timeouts & Intervalle
SESSION_TIMEOUT=90
TUNNEL_TIMEOUT=15
POLL_INTERVAL=2
TUNNEL_ATTEMPTS=3
TUNNEL_RETRY_DELAY=2

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

if [[ "$USE_NERD_FONTS" == "true" ]]; then
    ICONS=("󰆍" "󰊤" "󱏒" "󰏔" "󰀋")
else
    ICONS=("[SSH ]" "[GIT ]" "[INGR]" "[NEXT]" "[KEYC]")
fi

SPINNER_FRAMES=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
SPINNER_LENGTH=${#SPINNER_FRAMES[@]}

STATUS_CON="${YELLOW}[CON]${NC}"
STATUS_EST="${GREEN}[EST]${NC}"
STATUS_ERR="${RED}[ERR]${NC}"
STATUS_OFF="${BLUE}[OFF]${NC}"

# --- PRE-FLIGHT CHECKS ---
echo -e "${BOLD}Führe Systemprüfungen durch...${NC}"

OCI_CONFIG="$HOME/.oci/config"
if [[ ! -f "$OCI_CONFIG" ]]; then
    echo -e "${RED}Fehler:${NC} Die Datei '$OCI_CONFIG' existiert nicht!"
    exit 1
fi

MISSING_KEYS=()
for key in "tenancy" "user" "fingerprint" "key_file" "region"; do
    if ! grep -q "^[[:space:]]*${key}[[:space:]]*=" "$OCI_CONFIG"; then
        MISSING_KEYS+=("$key")
    fi
done

if (( ${#MISSING_KEYS[@]} > 0 )); then
    echo -e "${RED}Fehler:${NC} Folgende Schlüssel fehlen in deiner OCI-Config ($OCI_CONFIG):"
    for m_key in "${MISSING_KEYS[@]}"; do
        echo -e "  - $m_key"
    done
    exit 1
fi

# --- Netzwerkumgebung via SSL-Zertifikat prüfen ---
echo -e "  Prüfe Netzwerkumgebung..."

# Wir fragen den Issuer (Aussteller) von google.com ab.
SSL_ISSUER=$(timeout 3 openssl s_client -connect login.eu-frankfurt-2.oraclecloud.eu:443 -servername oraclecloud.eu 2>/dev/null </dev/null \
    | openssl x509 -noout -issuer 2>/dev/null || true)
if [[ -n "$SSL_ISSUER" && "$SSL_ISSUER" =~ "O=SOPRA STERIA" ]]; then
    echo -e "  ${YELLOW}Firmennetzwerk erkannt${NC} (SSL-Interception aktiv)."
    if [[ -f "$COMPANY_CA_PATH" ]]; then
        if timeout 3 openssl s_client \
            -connect bastion.eu-frankfurt-2.oci.oraclecloud.eu:443 \
            -servername bastion.eu-frankfurt-2.oci.oraclecloud.eu \
            -CAfile "$COMPANY_CA_PATH" \
            -verify_return_error \
            -brief </dev/null >/dev/null 2>&1; then
            TLS_SKIP="env REQUESTS_CA_BUNDLE= CURL_CA_BUNDLE="
        else
            echo "SSL-Verifizierung ist fehlgeschlagen! (Returncode > 0)"
            exit 1
        fi
        CA_BUNDLE="--cert-bundle $COMPANY_CA_PATH"
        echo -e "  ${GREEN}󰄬${NC} SSL-Zertifikate für OCI-CLI geladen."
    else
        echo -e "  ${RED}WARNUNG:${NC} Firmennetzwerk erkannt, aber CA-Zertifikat unter '$COMPANY_CA_PATH' fehlt!"
        exit 1
    fi
else
    echo -e "  ${GREEN}󰄬${NC} Direktes Internet / Privates Netzwerk erkannt (keine SSL-Interception)."
fi

echo -e "  ${GREEN}󰄬${NC} Vorbereitung abgeschlossen.\n"

# --- GLOBALE ARRAYS & TMP DIR ---
TMP_DIR=$(mktemp -d)
NAMES=("deploy-server-ssh" "tunnel-gitlab" "tunnel-ingress" "tunnel-nexus" "tunnel-keycloak")
BASTIONS=("$BASTION_TOOLS" "$BASTION_TOOLS" "$BASTION_ARGO" "$BASTION_TOOLS" "$BASTION_ARGO")
IPS=("10.3.0.55" "10.3.0.50" "10.1.2.7" "10.3.0.33" "10.1.2.75")
T_PORTS=("22" "443" "443" "443" "443")
L_PORTS=("2222" "9433" "8443" "8453" "8463")

cleanup() {
    echo -ne "\033[?25h" 
    echo ""
    echo "Fahre Tunnel herunter..."

    for i in {0..3}; do
        if [[ -f "$TMP_DIR/pid_$i" ]]; then
            local pid
            pid=$(cat "$TMP_DIR/pid_$i")
            [[ -n "$pid" ]] && kill "$pid" 2>/dev/null || true
        fi
        if [[ -f "$TMP_DIR/session_$i" ]]; then
            local session_id
            session_id=$(cat "$TMP_DIR/session_$i")
            [[ -z "$session_id" ]] && continue
            $TLS_SKIP oci $CA_BUNDLE bastion session delete --session-id "$session_id" --force >/dev/null 2>&1 || true
        fi
    done
    rm -rf "$TMP_DIR"
    echo "Fertig."
}

trap 'cleanup; exit 0' INT TERM
trap cleanup EXIT

create_session() {
    local idx="$1"
    local session_id
    
    # Fehlerstrom der OCI-CLI in eine Logdatei umleiten
    session_id=$($TLS_SKIP oci $CA_BUNDLE bastion session create-port-forwarding \
        --bastion-id "${BASTIONS[$idx]}" \
        --display-name "${NAMES[$idx]}" \
        --target-private-ip "${IPS[$idx]}" \
        --target-port "${T_PORTS[$idx]}" \
        --ssh-public-key-file "$SSH_PUB_KEY" \
        --query 'data.id' \
        --raw-output 2>"$TMP_DIR/oci_err_$idx")

    if [[ -z "$session_id" ]]; then
        echo "ERR" > "$TMP_DIR/status_$idx"
        return 1
    fi
    echo "$session_id" > "$TMP_DIR/session_$idx"

    local waited=0
    while (( waited < SESSION_TIMEOUT )); do
        local state
        state=$($TLS_SKIP oci $CA_BUNDLE bastion session get --session-id "$session_id" --query 'data."lifecycle-state"' --raw-output 2>/dev/null)
        case "$state" in
            ACTIVE)
                return 0
                ;;
            DELETED|FAILED)
                echo "ERR" > "$TMP_DIR/status_$idx"
                return 1
                ;;
        esac
        sleep "$POLL_INTERVAL"
        (( waited += POLL_INTERVAL ))
    done
    echo "ERR" > "$TMP_DIR/status_$idx"
    return 1
}

open_tunnel() {
    local idx="$1"
    local local_port="${L_PORTS[$idx]}"
    local session_id
    session_id=$(cat "$TMP_DIR/session_$idx")

    local ssh_cmd
    ssh_cmd=$($TLS_SKIP oci $CA_BUNDLE bastion session get --session-id "$session_id" --query 'data."ssh-metadata".command' --raw-output 2>/dev/null)

    if [[ -z "$ssh_cmd" ]]; then
        echo "ERR" > "$TMP_DIR/status_$idx"
        return 1
    fi
    ssh_cmd=${ssh_cmd//<privateKey>/$SSH_KEY}
    ssh_cmd=${ssh_cmd//<localPort>/$local_port}
    # ssh_cmd=${ssh_cmd//-p 22/-p 443}

    local full_cmd="$ssh_cmd -v -o IdentitiesOnly=yes -o ServerAliveInterval=30 -o ExitOnForwardFailure=yes -o StrictHostKeyChecking=accept-new"

    # Bastion Sync-Wartezeit
    sleep 5

    for (( attempt = 1; attempt <= TUNNEL_ATTEMPTS; attempt++ )); do
        # Jede SSH-Instanz schreibt ihr eigenes Logfile im TMP_DIR
        eval "$full_cmd" >/dev/null 2>"$TMP_DIR/ssh_err_$idx" &
        local pid=$!
        
        sleep 1.5

        local waited=0
        local success=false
        while (( waited < TUNNEL_TIMEOUT )); do
            if ! kill -0 "$pid" 2>/dev/null; then
                break
            fi
            
            # Port-Check über die Bash
            if (echo > /dev/tcp/127.0.0.1/"$local_port") >/dev/null 2>&1; then
                success=true
                break
            fi
            sleep 1
            (( waited += 1 ))
        done

        if [[ "$success" == "true" ]]; then
            echo "$pid" > "$TMP_DIR/pid_$idx"
            echo "EST" > "$TMP_DIR/status_$idx"
            return 0
        fi
        
        kill "$pid" 2>/dev/null || true
        (( attempt < TUNNEL_ATTEMPTS )) && sleep "$TUNNEL_RETRY_DELAY"
    done
    echo "ERR" > "$TMP_DIR/status_$idx"
    return 1
}

start_tunnel_async() {
    local idx="$1"
    echo "CON" > "$TMP_DIR/status_$idx"
    if create_session "$idx"; then
        open_tunnel "$idx"
    fi
}

# --- MAIN RENDER LOOP ---
echo -e "${BOLD}Starte OCI Bastion Tunnel-Infrastruktur...${NC}\n"
echo -ne "\033[?25l" 

for i in {0..4}; do
    echo "OFF" > "$TMP_DIR/status_$i"
done

# Parallel im Hintergrund starten
JOB_PIDS=()
start_tunnel_async 0 & JOB_PIDS+=($!)
start_tunnel_async 1 & JOB_PIDS+=($!)
start_tunnel_async 2 & JOB_PIDS+=($!)
start_tunnel_async 3 & JOB_PIDS+=($!)
start_tunnel_async 4 & JOB_PIDS+=($!)

frame_idx=0
while true; do
    SPINNER="${SPINNER_FRAMES[$frame_idx]}"

    for i in {0..4}; do
        status=$(cat "$TMP_DIR/status_$i" 2>/dev/null || echo "OFF")
        line_prefix="  "
        line_status=$STATUS_OFF

        case "$status" in
            CON)
                line_prefix="${YELLOW}${SPINNER}${NC} "
                line_status=$STATUS_CON
                ;;
            EST)
                line_prefix="  "
                line_status=$STATUS_EST
                if [[ -f "$TMP_DIR/pid_$i" ]]; then
                    pid_val=$(cat "$TMP_DIR/pid_$i")
                    if ! kill -0 "$pid_val" 2>/dev/null; then
                        line_status=$STATUS_ERR
                        echo "ERR" > "$TMP_DIR/status_$i"
                    fi
                fi
                ;;
            ERR)
                line_prefix="  "
                line_status=$STATUS_ERR
                ;;
        esac

        display_name="${NAMES[$i]} (${L_PORTS[$i]})"
        if [[ "$USE_NERD_FONTS" == "true" ]]; then
            printf "%b %b  %-34s %b\033[K\n" "$line_prefix" "${ICONS[$i]}" "$display_name" "$line_status"
        else
            printf "%b %-7s %-34s %b\033[K\n" "$line_prefix" "${ICONS[$i]}" "$display_name" "$line_status"
        fi

    done

 # Prüfen, ob noch irgendein Tunnel im Aufbau (CON) oder im Initialzustand (OFF) ist
    still_connecting=0

    for i in {0..4}; do
        s=$(cat "$TMP_DIR/status_$i" 2>/dev/null || echo "OFF")
        if [[ "$s" == "CON" || "$s" == "OFF" ]]; then
            still_connecting=$((still_connecting + 1))
        fi
    done

    # Erst wenn kein Tunnel mehr auf "CON" oder "OFF" steht, brechen wir die UI ab
    if (( still_connecting == 0 )); then
        break
    fi

    echo -ne "\033[4A"
    frame_idx=$(( (frame_idx + 1) % SPINNER_LENGTH ))
    sleep 0.1
done

echo -ne "\033[?25h" 
echo -e "\n${BOLD}Alle Tunnel verarbeitet.${NC}"

# --- FEHLERANALYSE UND AUSGABE ---
HAS_ERRORS=false
for i in {0..4}; do
    status=$(cat "$TMP_DIR/status_$i" 2>/dev/null || echo "OFF")
    if [[ "$status" == "ERR" ]]; then
        HAS_ERRORS=true
        echo -e "\n${RED}${BOLD}Fehlerdetails für ${NAMES[$i]}:${NC}"
        
        # 1. Fall: Fehler trat beim Erstellen der OCI Bastion Session auf
        if [[ -f "$TMP_DIR/oci_err_$i" && -s "$TMP_DIR/oci_err_$i" ]]; then
            echo -e "  ${YELLOW}[OCI API Error]:${NC}"
            sed 's/^/    /' "$TMP_DIR/oci_err_$i"
        fi

        # 2. Fall: Fehler trat beim SSH-Tunnelaufbau auf
        if [[ -f "$TMP_DIR/ssh_err_$i" && -s "$TMP_DIR/ssh_err_$i" ]]; then
            echo -e "  ${YELLOW}[SSH Connection Error] (Die letzten 8 Zeilen):${NC}"
            tail -n 8 "$TMP_DIR/ssh_err_$i" | sed 's/^/    /'
        fi
    fi
done

# Prüfen, ob mindestens ein Tunnel erfolgreich steht
TUNNEL_OK=false
for i in {0..4}; do
    s=$(cat "$TMP_DIR/status_$i" 2>/dev/null || echo "OFF")
    if [[ "$s" == "EST" ]]; then
        TUNNEL_OK=true
    fi
done

if [[ "$TUNNEL_OK" == "true" ]]; then
    echo -e "\n${GREEN}${BOLD}Tunnels erfolgreich aufgebaut!${NC}"

    echo -e "Verbindungen stehen auf den Ports: ${BLUE}${L_PORTS[*]}${NC}"
    echo -e "Überwachung läuft... Beenden mit ${YELLOW}Strg+C${NC}.\n"

    # --- KUGELSICHERE ÜBERWACHUNGSSCHLEIFE ---
    while true; do
        active_tunnels=0
        
        for i in {0..3}; do
            # Nur überwachen, was auch erfolgreich gestartet wurde
            status=$(cat "$TMP_DIR/status_$i" 2>/dev/null || echo "OFF")
            if [[ "$status" == "EST" ]]; then
                if [[ -f "$TMP_DIR/pid_$i" ]]; then
                    pid_val=$(cat "$TMP_DIR/pid_$i")
                    # Prüfen, ob die echte SSH-PID noch im System existiert
                    if kill -0 "$pid_val" 2>/dev/null; then
                        (( active_tunnels++ ))
                    else
                        # Tunnel ist im Hintergrund weggestorben
                        echo -e "${RED}[WARN]${NC} Tunnel für ${NAMES[$i]} (Port ${L_PORTS[$i]}) wurde unerwartet beendet!"
                        echo "ERR" > "$TMP_DIR/status_$i"

                    fi
                fi
            fi
        done

        # Wenn kein einziger Tunnel mehr lebt, können wir das Skript beenden
        if (( active_tunnels == 0 )); then

            echo -e "\n${RED}Alle aktiven Tunnel wurden beendet.${NC}"
            break
        fi

        sleep 2
    done
else
    if [[ "$HAS_ERRORS" == "false" ]]; then
        echo -e "\n${RED}Keine Tunnel erfolgreich aufgebaut.${NC}"
    fi
fi
