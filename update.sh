#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  Coaching Dashboard — Weekly Update Script
#  Usage (baseline, grades only):
#    ./update.sh ~/Downloads/grades-file.csv 2026-03-13
#  Usage (weekly, both files):
#    ./update.sh ~/Downloads/grades-file.csv ~/Downloads/tracker-file.csv 2026-03-18
# ─────────────────────────────────────────────────────────────

set -e

if [ $# -eq 2 ]; then
  GRADES_CSV="$1"
  TRACKER_CSV=""
  WEEK_DATE="$2"
elif [ $# -eq 3 ]; then
  GRADES_CSV="$1"
  TRACKER_CSV="$2"
  WEEK_DATE="$3"
else
  echo ""
  echo "❌  Wrong number of arguments."
  echo "  Baseline:  ./update.sh ~/Downloads/grades-file.csv YYYY-MM-DD"
  echo "  Weekly:    ./update.sh ~/Downloads/grades-file.csv ~/Downloads/tracker-file.csv YYYY-MM-DD"
  exit 1
fi

if [ ! -f "$GRADES_CSV" ]; then
  echo "❌  Grades file not found: $GRADES_CSV"
  exit 1
fi

if [ -n "$TRACKER_CSV" ] && [ ! -f "$TRACKER_CSV" ]; then
  echo "❌  Tracker file not found: $TRACKER_CSV"
  exit 1
fi

echo ""
echo "📂  Grades file:  $GRADES_CSV"
[ -n "$TRACKER_CSV" ] && echo "📂  Tracker file: $TRACKER_CSV" || echo "📂  Tracker file: (baseline mode — volume not tracked)"
echo "📅  Week:         $WEEK_DATE"

python3 - << PYEOF
import csv, json, os, re
from collections import defaultdict, Counter
from datetime import datetime

grades_csv  = "$GRADES_CSV"
tracker_csv = "$TRACKER_CSV"
week_date   = "$WEEK_DATE"
hist_file   = os.path.join("data", "history.json")

os.makedirs("data", exist_ok=True)

# ── Name merge map (duplicates → canonical name) ─────────────
MERGE_MAP = {
    "soaham":                    "Soaham Sharma",
    "maryann":                   "Maryann Chidume",
    "vidhi vashish":             "Vidhi Vashishth",
    "aleksandra wrega (alex)":   "Aleksandra Wrega",
    "srboljub kovacevic":        "Srba Kovacevic",
}

def canonical(name):
    name = name.strip()
    key = name.lower().strip()
    return MERGE_MAP.get(key, name)

# ── Load history ─────────────────────────────────────────────
if os.path.exists(hist_file):
    with open(hist_file) as f:
        history = json.load(f)
else:
    history = []

history = [h for h in history if h.get("week") != week_date]

# ── Parse grades CSV ─────────────────────────────────────────
def n(v):
    try: return int(v or 0)
    except: return 0

with open(grades_csv, encoding="utf-8") as f:
    grade_rows = list(csv.DictReader(f))

# Merge duplicate coaches
merged = defaultdict(lambda: {"analyzed":0,"pass":0,"fail":0,"passPct":0})
for r in grade_rows:
    name = canonical(r.get("Coach","").strip())
    if not name: continue
    merged[name]["analyzed"] += n(r.get("CallsAnalyzed"))
    merged[name]["pass"]     += n(r.get("PassCalls"))
    merged[name]["fail"]     += n(r.get("FailCalls"))

for name, g in merged.items():
    g["passPct"] = round((g["pass"] / g["analyzed"] * 100) if g["analyzed"] else 0, 1)

# ── Parse tracker CSV (optional) ────────────────────────────
tracker_by_coach = Counter()
daily = []

if tracker_csv:
    with open(tracker_csv, encoding="utf-8") as f:
        tracker_rows = list(csv.DictReader(f))

    tracker_by_date = Counter()
    for r in tracker_rows:
        coach = canonical(r.get("Name of Coach","").strip())
        date  = r.get("Date","").strip()
        if coach: tracker_by_coach[coach] += 1
        if date:  tracker_by_date[date]   += 1

    def parse_date(s):
        for fmt in ("%m/%d/%Y", "%Y-%m-%d", "%m/%d/%y"):
            try: return datetime.strptime(s.strip(), fmt).strftime("%Y-%m-%d")
            except: continue
        return s.strip()

    daily = [{"date": parse_date(d), "calls": c}
             for d, c in sorted(tracker_by_date.items(), key=lambda x: parse_date(x[0]))]

# ── Build coach list ─────────────────────────────────────────
coaches = []
for name, g in sorted(merged.items()):
    total = tracker_by_coach.get(name, g["analyzed"]) if tracker_csv else g["analyzed"]
    coaches.append({
        "coach":    name,
        "total":    total,
        "analyzed": g["analyzed"],
        "pass":     g["pass"],
        "fail":     g["fail"],
        "passPct":  int(g["passPct"]),
        "baseline": not bool(tracker_csv)
    })

# ── Totals ───────────────────────────────────────────────────
total_calls = sum(c["total"]    for c in coaches)
analyzed    = sum(c["analyzed"] for c in coaches)
passes      = sum(c["pass"]     for c in coaches)
fails       = sum(c["fail"]     for c in coaches)
pass_pct    = round((passes / analyzed * 100) if analyzed else 0, 1)

history.append({
    "week":     week_date,
    "baseline": not bool(tracker_csv),
    "total":    total_calls,
    "analyzed": analyzed,
    "pass":     passes,
    "fail":     fails,
    "passPct":  pass_pct,
    "coaches":  coaches,
    "daily":    daily
})

history.sort(key=lambda h: h["week"])

with open(hist_file, "w") as f:
    json.dump(history, f, indent=2)

mode = "BASELINE" if not tracker_csv else "WEEKLY"
print(f"✅  [{mode}] Week {week_date}: {total_calls} calls, {analyzed} analyzed, {pass_pct}% pass rate")
print(f"📊  Total weeks in history: {len(history)}")
print(f"👥  Coaches loaded: {len(coaches)}")
PYEOF

# ── Embed history into dashboard HTML ────────────────────────
python3 - << PYEOF
import json, re, os

with open("data/history.json") as f:
    history = json.load(f)

with open("index.html") as f:
    html = f.read()

new_data = "const HISTORY_DATA = " + json.dumps(history) + ";"
html = re.sub(r'const HISTORY_DATA = \[.*?\];', new_data, html, flags=re.DOTALL)

with open("index.html", "w") as f:
    f.write(html)

print(f"✅  Dashboard updated with {len(history)} week(s) of data")
PYEOF

# ── Push to GitHub ────────────────────────────────────────────
echo ""
echo "🚀  Pushing to GitHub..."
git add index.html data/history.json
git commit -m "Update: $WEEK_DATE"
git push

echo ""
echo "✅  Done! Refresh https://fiorellamendez.github.io/Coaching-dashboard in 1-2 minutes."
echo ""
