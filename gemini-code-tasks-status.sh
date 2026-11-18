#!/usr/bin/env bash

TASK_FILE="$HOME/.tasks.log"

[ ! -f "$TASK_FILE" ] && echo "⏸ Frei" && exit 0

# Zeile mit leerem End-Feld suchen
active_line=$(grep " |  | " "$TASK_FILE" | tail -n 1)

if [ -n "$active_line" ]; then
    start_str=$(echo "$active_line" | awk -F ' \\| ' '{print $1}')
    task_name=$(echo "$active_line" | awk -F ' \\| ' '{print $3}')

    # Zeitdifferenz in Minuten berechnen
    start_sec=$(date -d "$start_str" +%s 2>/dev/null)
    now_sec=$(date +%s)
    diff_min=$(( (now_sec - start_sec) / 60 ))

    hours=$(( diff_min / 60 ))
    mins=$(( diff_min % 60 ))

    # Laufzeit formatieren (z. B. 01:25h)
    printf "⏱ %02d:%02dh | %s\n" "$hours" "$mins" "$task_name"
else
    echo "⏸ Frei"
fi