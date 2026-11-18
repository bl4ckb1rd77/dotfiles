#!/usr/bin/env bash

TASK_FILE="$HOME/.tasks.log"
touch "$TASK_FILE"

NOW=$(date "+%Y-%m-%d %H:%M")

# Prüfen, ob eine Zeile ein leeres End-Feld hat (" |  | ")
active_line=$(grep -n " |  | " "$TASK_FILE" | tail -n 1)

if [ -n "$active_line" ]; then
    # --- FALL A: Es läuft bereits ein Task ---
    line_num=$(echo "$active_line" | cut -d: -f1)
    content=$(echo "$active_line" | cut -d: -f2-)
    
    start_time=$(echo "$content" | awk -F ' \\| ' '{print $1}')
    task_name=$(echo "$content" | awk -F ' \\| ' '{print $3}')

    options="⏹ Beenden: $task_name (läuft seit $start_time)"
    selected=$(echo -e "$options" | rofi -dmenu -p "Aktiver Task")

    if [[ "$selected" == "⏹ Beenden:"* ]]; then
        # Endzeitstempel in genau dieser Zeile ergänzen
        sed -i "${line_num}s/ |  | / | ${NOW} | /" "$TASK_FILE"
    fi
else
    # --- FALL B: Kein aktiver Task -> Starten erlaubt ---
    # Zeigt den Start-Button + die letzten 10 abgeschlossenen Tasks (neueste oben)
    history=$(tac "$TASK_FILE" | head -n 10)
    options="▶ Neuen Task starten...\n----------------------------------------\n$history"

    selected=$(echo -e "$options" | rofi -dmenu -p "Task-Tracker")

    if [[ "$selected" == "▶ Neuen Task starten..." ]]; then
        new_task=$(rofi -dmenu -p "Aufgabe" -lines 0)
        # Pipes im Text vorsichtshalber ersetzen, um das Format nicht zu brechen
        new_task="${new_task//|/-}"
        if [ -n "$new_task" ]; then
            echo "${NOW} |  | ${new_task}" >> "$TASK_FILE"
        fi
    fi
fi