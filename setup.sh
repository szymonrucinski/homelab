#!/usr/bin/env bash
#
# setup.sh - Initialize the docker-homelab repository
#
# Usage:  chmod +x setup.sh && ./setup.sh
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== docker-homelab setup ==="
echo ""

# ── 1. Init git repo if needed ─────────────────────────────────────────────
if [[ ! -d "$REPO_DIR/.git" ]]; then
    echo "[1/4] Initializing git repository..."
    git -C "$REPO_DIR" init
else
    echo "[1/4] Git repository already initialized."
fi

# ── 2. Configure git hooks path ────────────────────────────────────────────
echo "[2/4] Configuring pre-commit hook..."
git -C "$REPO_DIR" config core.hooksPath .githooks
chmod +x "$REPO_DIR/.githooks/pre-commit"

# ── 3. Create .env files from examples ─────────────────────────────────────
echo "[3/4] Creating .env files from templates (if missing)..."
created=0
for example in $(find "$REPO_DIR" -name '.env.example' -type f); do
    envfile="$(dirname "$example")/.env"
    if [[ ! -f "$envfile" ]]; then
        cp "$example" "$envfile"
        echo "       Created: ${envfile#$REPO_DIR/}"
        created=$((created + 1))
    fi
done
if [[ $created -eq 0 ]]; then
    echo "       All .env files already exist."
else
    echo "       Created $created .env file(s). Edit them with your actual values."
fi

# ── 4. Verify hook works ──────────────────────────────────────────────────
echo "[4/4] Verifying pre-commit hook..."
if [[ -x "$REPO_DIR/.githooks/pre-commit" ]]; then
    echo "       Pre-commit hook is installed and executable."
else
    echo "       WARNING: Pre-commit hook is not executable."
fi

echo ""
echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo "  1. Edit each stack's .env file with your actual values"
echo "  2. Run 'git add -A && git commit -m \"initial commit\"' to test the hook"
echo "  3. The pre-commit hook will block any secrets from being committed"
echo ""
echo "Stack directories:"
for d in arr-stack immich ai-stack jellyfin jellyfin-auto-collections glances portainer autoheal; do
    if [[ -d "$REPO_DIR/$d" ]]; then
        env_status="(no .env needed)"
        if [[ -f "$REPO_DIR/$d/.env.example" ]]; then
            if [[ -f "$REPO_DIR/$d/.env" ]]; then
                env_status="(.env ready)"
            else
                env_status="(.env MISSING - run setup again)"
            fi
        fi
        echo "  $d/ $env_status"
    fi
done
