# Coaching QC Dashboard — Setup & Weekly Guide

---

## ONE-TIME SETUP (do this once, takes ~10 minutes)

### Step 1 — Install Git (if you don't have it)
Open Terminal (press Cmd+Space, type "Terminal", hit Enter) and run:
```
git --version
```
If you see a version number, you're good. If not, it will prompt you to install it — click Install.

---

### Step 2 — Create your GitHub repository
1. Go to https://github.com and sign in
2. Click the **+** button (top right) → **New repository**
3. Name it: `coaching-dashboard`
4. Set it to **Public** (required for free GitHub Pages)
5. Click **Create repository**
6. Copy the repository URL — it looks like:
   `https://github.com/YOUR-USERNAME/coaching-dashboard.git`

---

### Step 3 — Set up the folder on your Mac
Open Terminal and run these commands one by one
(replace YOUR-USERNAME with your actual GitHub username):

```bash
cd ~/Desktop
mkdir coaching-dashboard
cd coaching-dashboard
git init
git remote add origin https://github.com/YOUR-USERNAME/coaching-dashboard.git
mkdir data
touch data/history.json
echo "[]" > data/history.json
```

---

### Step 4 — Copy the dashboard files
Copy these two files into your `coaching-dashboard` folder on the Desktop:
- `index.html`
- `update.sh`

Then in Terminal, make the update script runnable:
```bash
cd ~/Desktop/coaching-dashboard
chmod +x update.sh
```

---

### Step 5 — Push to GitHub for the first time
```bash
cd ~/Desktop/coaching-dashboard
git add .
git commit -m "Initial setup"
git push -u origin main
```
> If it asks for your GitHub username and password, enter them.
> For the password, use a GitHub **Personal Access Token** (not your regular password).
> To create one: GitHub → Settings → Developer Settings → Personal Access Tokens → Generate new token → check "repo" → copy it.

---

### Step 6 — Enable GitHub Pages
1. Go to your repository on GitHub
2. Click **Settings** (top menu)
3. Scroll down to **Pages** (left sidebar)
4. Under "Source", select **main** branch, folder **/ (root)**
5. Click **Save**
6. After 1–2 minutes, your dashboard is live at:
   `https://YOUR-USERNAME.github.io/coaching-dashboard`

**Share this link with your manager.** They bookmark it once and always see the latest data.

---

## EVERY WEEK (takes 2 minutes)

### Step 1 — Export your CSV
Export it as usual. Note the file path (e.g. `~/Downloads/coach-dashboard-2026-03-11.csv`)

### Step 2 — Run the update script
Open Terminal and run:
```bash
cd ~/Desktop/coaching-dashboard
./update.sh ~/Downloads/coach-dashboard-2026-03-11.csv 2026-03-11
```
Replace the filename and date with the actual ones each week.

### Step 3 — Done!
The script automatically:
- Reads your new CSV
- Adds it to the historical record
- Updates the dashboard HTML
- Pushes everything to GitHub

Your manager refreshes the page and sees the new data within 1–2 minutes.

---

## WHAT YOUR MANAGER SEES

- **Overview tab** — KPI cards with week-over-week trend arrows, result breakdown charts, coach table
- **Trends tab** — Pass/fail over time, weekly volume, per-coach trend lines (visible after 2+ weeks)
- **Coach Detail tab** — Individual coach stats + their personal pass rate trend over time

---

## TROUBLESHOOTING

**"Permission denied" when running update.sh**
```bash
chmod +x update.sh
```

**"git push" asks for password every time**
Set up a credential helper:
```bash
git config --global credential.helper osxkeychain
```

**Dashboard not updating after push**
GitHub Pages can take 1–3 minutes to refresh. Hard-refresh the page with Cmd+Shift+R.

**Wrong date entered by mistake**
Just re-run the script with the correct date — it safely overwrites that week's entry.
