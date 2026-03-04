#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  Coaching Dashboard — Weekly Update Script
#  Usage: ./update.sh path/to/your-file.csv "2026-03-04"
# ─────────────────────────────────────────────────────────────

set -e

CSV_FILE="$1"
WEEK_DATE="$2"

# ── Validate inputs ──────────────────────────────────────────
if [ -z "$CSV_FILE" ] || [ -z "$WEEK_DATE" ]; then
  echo ""
  echo "❌  Missing arguments."
  echo ""
  echo "    Usage: ./update.sh path/to/your-file.csv YYYY-MM-DD"
  echo "    Example: ./update.sh ~/Downloads/coach-dashboard-2026-03-04.csv 2026-03-04"
  echo ""
  exit 1
fi

if [ ! -f "$CSV_FILE" ]; then
  echo "❌  File not found: $CSV_FILE"
  exit 1
fi

echo ""
echo "📂  Reading: $CSV_FILE"
echo "📅  Week:    $WEEK_DATE"

# ── Append new week to history using Python ──────────────────
python3 - << PYEOF
import csv, json, os, sys
from datetime import datetime

csv_file  = "$CSV_FILE"
week_date = "$WEEK_DATE"
hist_file = os.path.join(os.path.dirname(os.path.abspath("$0")), "data", "history.json")

os.makedirs(os.path.dirname(hist_file), exist_ok=True)

# Load existing history
if os.path.exists(hist_file):
    with open(hist_file) as f:
        history = json.load(f)
else:
    history = []

# Remove any existing entry for this week (so re-runs are safe)
history = [h for h in history if h.get("week") != week_date]

# Parse new CSV
with open(csv_file, encoding="utf-8") as f:
    rows = list(csv.DictReader(f))

def n(v):
    try: return int(v or 0)
    except: return 0

coaches = []
for r in rows:
    coaches.append({
        "coach":    r.get("Coach","").strip(),
        "total":    n(r.get("TotalCalls")),
        "analyzed": n(r.get("CallsAnalyzed")),
        "pass":     n(r.get("PassCalls")),
        "needs":    n(r.get("NeedsImprovementCalls")),
        "fail":     n(r.get("FailCalls")),
        "passPct":  n(r.get("PassPct")),
    })

total     = sum(c["total"]    for c in coaches)
analyzed  = sum(c["analyzed"] for c in coaches)
passes    = sum(c["pass"]     for c in coaches)
needs     = sum(c["needs"]    for c in coaches)
fails     = sum(c["fail"]     for c in coaches)
pass_pct  = round((passes / analyzed * 100) if analyzed else 0, 1)

history.append({
    "week":     week_date,
    "total":    total,
    "analyzed": analyzed,
    "pass":     passes,
    "needs":    needs,
    "fail":     fails,
    "passPct":  pass_pct,
    "coaches":  coaches
})

# Sort by week date
history.sort(key=lambda h: h["week"])

with open(hist_file, "w") as f:
    json.dump(history, f, indent=2)

print(f"✅  Added week {week_date}: {total} calls, {analyzed} analyzed, {pass_pct}% pass rate")
print(f"📊  Total weeks in history: {len(history)}")
PYEOF

# ── Embed history.json into the dashboard HTML ───────────────
python3 - << PYEOF
import json, re, os

hist_file  = os.path.join("data", "history.json")
html_file  = "index.html"

with open(hist_file) as f:
    history = json.load(f)

with open(html_file) as f:
    html = f.read()

# Replace the HISTORY_DATA placeholder
new_data = "const HISTORY_DATA = " + json.dumps(history) + ";"
html = re.sub(r'const HISTORY_DATA = \[.*?\];', new_data, html, flags=re.DOTALL)

with open(html_file, "w") as f:
    f.write(html)

print(f"✅  Dashboard updated with {len(history)} week(s) of data")
PYEOF

# ── Push to GitHub ───────────────────────────────────────────
echo ""
echo "🚀  Pushing to GitHub..."
git add index.html data/history.json
git commit -m "Weekly update: $WEEK_DATE"
git push

echo ""
echo "✅  Done! Your dashboard is live."
echo "    It may take 1–2 minutes for GitHub Pages to refresh."
echo ""
