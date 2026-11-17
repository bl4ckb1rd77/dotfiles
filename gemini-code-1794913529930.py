import json
import re
import urllib.parse
import requests

# --- KONFIGURATION ---
JSON_FILE = "security_export.json"
CONFLUENCE_URL = "https://deine-confluence-domain.intern/wiki"
SPACE_KEY = "DEIN_SPACE_KEY"
PAGE_TITLE = "Titel deiner Seite"
PAT_TOKEN = "dein_personal_access_token_hier"


def get_xray_critical_and_high_identifiers(file_path):
  """Liest den Xray-Export ein, filtert Critical & High,

  und nutzt .id als Fallback, falls keine CVEs vorhanden sind.
  """
  with open(file_path, "r", encoding="utf-8") as f:
    data = json.load(f)

  identifiers = set()

  for item in data.get("data", []):
    severity = item.get("severity")

    # Filter: Nur Critical und High
    if severity in ["Critical", "High"]:
      more_details = (
          item.get("component_versions", {}).get("more_details", {})
      )
      cves = more_details.get("cves", [])

      cve_found = False
      for cve_entry in cves:
        cve_name = cve_entry.get("cve")
        if cve_name:
          identifiers.add(cve_name)
          cve_found = True

      # Fallback: Wenn keine CVE vorhanden ist, nimm die XRAY-ID
      if not cve_found:
        item_id = item.get("id")
        if item_id:
          identifiers.add(item_id)

  return identifiers


def get_confluence_page_html():
  """Lädt den body_html der Confluence-Seite via PAT-Token."""
  encoded_title = urllib.parse.quote(PAGE_TITLE)
  url = f"{CONFLUENCE_URL}/rest/api/content?spaceKey={SPACE_KEY}&title={encoded_title}&expand=body.storage"

  headers = {
      "Authorization": f"Bearer {PAT_TOKEN}",
      "Accept": "application/json",
  }

  try:
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
      data = response.json()

      # Unterstützt sowohl Listen- als auch Einzelobjekt-Antworten der API
      if "results" in data:
        results = data.get("results", [])
        if not results:
          print(
              f"❌ Keine Seite mit dem Titel '{PAGE_TITLE}' im Space"
              f" '{SPACE_KEY}' gefunden."
          )
          return None
        return results[0]["body"]["storage"]["value"]
      elif "body" in data:
        return data["body"]["storage"]["value"]

    else:
      print(f"Fehler von Confluence API: Statuscode {response.status_code}")
  except Exception as e:
    print(f"Verbindungsfehler zur Confluence-API: {e}")

  return None


def main():
  print("1. Analysiere Xray-JSON (Critical & High mit Fallback auf XRAY-IDs)...")
  xray_items = get_xray_critical_and_high_identifiers(JSON_FILE)
  print(f"Gefundene relevante Xray-Einträge: {len(xray_items)}")

  print("2. Lade Confluence-Daten...")
  body_html = get_confluence_page_html()
  if not body_html:
    return

  # 3. Extrahiere sowohl CVEs als auch XRAY-IDs aus der Confluence-Seite
  found_cves = set(re.findall(r"CVE-\d{4}-\d{4,7}", body_html))
  found_xray_ids = set(re.findall(r"XRAY-\d+", body_html))

  # Kombiniere beide zu einer Confluence-Referenzmenge
  confluence_identifiers = found_cves.union(found_xray_ids)
  print(f"Bereits auf der Confluence-Seite gefundene IDs: {len(confluence_identifiers)}")

  print("\n--- ERGEBNIS: FEHLENDE EINTRÄGE ---")
  # Mengen-Subtraktion: Alles was in Xray ist, aber nicht auf Confluence steht
  missing_items = xray_items - confluence_identifiers

  if missing_items:
    print(
        f"⚠️ Folgende {len(missing_items)} Critical/High Einträge fehlen auf"
        " der Confluence-Seite:"
    )
    for item in sorted(missing_items):
      print(f" - {item}")
  else:
    print("✅ Alle Critical/High Einträge aus Xray sind bereits auf Confluence vorhanden!")


if __name__ == "__main__":
  main()