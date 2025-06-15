#!/bin/bash
set -ex

# Ensure Python3, pip and virtualenv are installed
sudo apt-get update
sudo apt-get install -y python3 python3-pip virtualenv

# Create and activate virtual environment
if [ ! -d "venv" ]; then
    virtualenv venv
fi
source venv/bin/activate

# Upgrade packaging tools
pip install --upgrade pip setuptools wheel

INSTALL_FALLBACK=0
if [ -f requirements.txt ]; then
    if ! pip install -r requirements.txt; then
        INSTALL_FALLBACK=1
    fi
else
    INSTALL_FALLBACK=1
fi

if [ "$INSTALL_FALLBACK" -eq 1 ]; then
    pip install sqlalchemy fastapi fastapi-jwt-auth
fi

# Verify package installations
python - <<'PYEOF'
import importlib, sys
packages = {
    'sqlalchemy': 'sqlalchemy',
    'fastapi': 'fastapi',
    'fastapi_jwt_auth': 'fastapi-jwt-auth'
}

for module, pkg in packages.items():
    try:
        importlib.import_module(module)
        print(f"{pkg} installed and importable")
    except Exception as e:
        print(f"Failed to import {pkg}: {e}")
        sys.exit(1)
PYEOF

# Run tests
CRITICAL=0
if ! pytest -vv --maxfail=5 tests/unit_tests; then
    echo "Pytest reported failures"
    CRITICAL=1
fi
python -m unittest discover -v || true

# Network reachability tests
for domain in awscli.amazonaws.com packages.cloud.google.com aka.ms pypi.org github.com; do
    if ping -c 1 -W 1 "$domain" >/dev/null 2>&1; then
        echo "$domain reachable"
    else
        echo "$domain not reachable"
    fi
done

if [ $CRITICAL -eq 0 ]; then
    echo "setup_and_debug.sh complete. No critical issues found."
else
    echo "setup_and_debug.sh complete. Critical issues were found."
fi
