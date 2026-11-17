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

# Die Komponente, nach der in Spalte 4 (betroffene komponente) gefiltert werden soll
TARGET_COMPONENT = "deine-ziel-komponente"


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


def get_identifiers_from_confluence_table(body_html, target_component):
  """Parst die Confluence-Tabellen, filtert nach Spalte 4 (Komponente)

  und extrahiert daraus CVEs und XRAY-IDs.
  """
  confluence_identifiers = set()

  # 1. Finde alle Tabellenzeilen (<tr>...</tr>) im HTML
  rows = re.findall(r"<tr[^>]*>(.*?)</tr>", body_html, re.DOTALL | re.IGNORECASE)

  for row in rows:
    # 2. Finde alle Zellen (<td> oder <th>) innerhalb dieser Zeile
    cells = re.findall(
        r"<t[dh][^>]*>(.*?)</t[dh]>", row, re.DOTALL | re.IGNORECASE
    )

    # Wir brauchen mindestens 5 Spalten, damit Index 4 (betroffene komponente) existiert
    if len(cells) >= 5:
      # HTML-Tags aus den Zellen entfernen für reinen Text
      cleaned_cells = [re.sub(r"<[^>]+>", "", cell).strip() for cell in cells]

      cve_cell = cleaned_cells[0]  # Spalte 0: CVE / ID
      component_cell = cleaned_cells[4]  # Spalte 4: betroffene komponente

      # Prüfen, ob die gesuchte Komponente in dieser Zeile übereinstimmt
      if target_component.lower() in component_cell.lower():
        # Extrahiere CVEs und XRAY-IDs aus der ersten Spalte
        found_cves = re.findall(r"CVE-\d{4}-\d{4,7}", cve_cell)
        found_xray = re.findall(r"XRAY-\d+", cve_cell)

        for cve in found_cves:
          confluence_identifiers.add(cve)
        for xray in found_xray:
          confluence_identifiers.add(xray)

  return confluence_identifiers


def main():
  print("1. Analysiere Xray-JSON (Critical & High mit Fallback)...")
  xray_items = get_xray_critical_and_high_identifiers(JSON_FILE)
  print(f"Gefundene relevante Xray-Einträge gesamt: {len(xray_items)}")

  print("2. Lade Confluence-Daten...")
  body_html = get_confluence_page_html()
  if not body_html:
    return

  print(f"3. Filtere Confluence-Tabelle nach Komponente: '{TARGET_COMPONENT}'...")
  confluence_identifiers = get_identifiers_from_confluence_table(
      body_html, TARGET_COMPONENT
  )
  print(
      "Bereits in Confluence für diese Komponente dokumentierte Einträge:"
      f" {len(confluence_identifiers)}"
  )

  print("\n--- ERGEBNIS: FEHLENDE EINTRÄGE ---")
  missing_items = xray_items - confluence_identifiers

  if missing_items:
    print(
        f"⚠️ Folgende {len(missing_items)} Critical/High Einträge fehlen für"
        f" Komponente '{TARGET_COMPONENT}' auf Confluence:"
    )
    for item in sorted(missing_items):
      print(f" - {item}")
  else:
    print(
        "✅ Alle Critical/High Einträge für diese Komponente sind bereits auf"
        " Confluence vorhanden!"
    )


if __name__ == "__main__":
  main()