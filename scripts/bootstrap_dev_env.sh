#!/usr/bin/env bash
###############################################################################
#  SuperAgi Fork • All-in-One Dev Environment Bootstrap
#  Compatible: Ubuntu 22.04 / 24.04 (x86_64 & ARM64)
###############################################################################
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
NODE_MAJOR="20"
PYTHON_PKGS_HF=(transformers datasets tokenizers huggingface_hub accelerate peft sentencepiece protobuf tqdm scikit-learn scipy)
PYTHON_PKGS_DEV=(virtualenv requests fastapi django numpy pandas matplotlib seaborn scikit-learn torch==2.3.* tensorflow==2.19.* pytest coverage pylint black isort mypy openai boto3 python-dotenv cryptography)
NODE_GLOBAL_PKGS=(typescript ts-node eslint prettier nodemon webpack cross-env npm-check-updates yarn)
CLOUD_SDKS=(aws azure gcloud gh)
INSTALL_HF=true INSTALL_DB=true INSTALL_CLOUD_CLI=true
function log(){ printf "\e[1;34m[INFO]\e[0m %s\n" "$*"; }
function warn(){ printf "\e[1;33m[WARN]\e[0m %s\n" "$*"; }
function die(){ printf "\e[1;31m[FAIL]\e[0m %s\n" "$*"; exit 1; }
trap 'die "line $LINENO: $BASH_COMMAND exited $?"' ERR
# --- Stage 1: base packages --------------------------------------------------
if (( EUID != 0 )); then die "Run with sudo"; fi
apt-get update -y
apt-get install -y --no-install-recommends build-essential curl wget git unzip zip \
  ca-certificates software-properties-common python3 python3-pip python3-venv \
  python3-dev docker.io docker-compose redis sqlite3 gnupg lsb-release apt-transport-https
# Node LTS
if ! command -v node >/dev/null; then curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash -; apt-get install -y nodejs; fi
# Python
python3 -m pip install --upgrade --no-cache-dir pip
python3 -m pip install --no-cache-dir "${PYTHON_PKGS_DEV[@]}"
$INSTALL_HF && python3 -m pip install --no-cache-dir "${PYTHON_PKGS_HF[@]}"
# Node tooling
npm install -g "${NODE_GLOBAL_PKGS[@]}"
# MySQL (blocked from auto-start)
if $INSTALL_DB; then
  install -m 755 /dev/null /usr/sbin/policy-rc.d; echo "exit 101" >/usr/sbin/policy-rc.d
  wget -q https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb
  dpkg -i mysql-apt-config_0.8.29-1_all.deb; apt-get update -y; apt-get install -y mysql-server
  rm -f mysql-apt-config_0.8.29-1_all.deb /usr/sbin/policy-rc.d
fi
# Cloud CLIs
if $INSTALL_CLOUD_CLI; then
  [[ ! $(command -v aws)    ]] && { curl -sSLo /tmp/awscli.zip https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip; unzip -qq /tmp/awscli.zip -d /tmp; /tmp/aws/install -i /usr/local/aws-cli -b /usr/local/bin; }
  [[ ! $(command -v gcloud) ]] && { curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg; echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list; apt-get update -y; apt-get install -y google-cloud-sdk; }
  [[ ! $(command -v az)     ]] && curl -sL https://aka.ms/InstallAzureCLIDeb | bash
  [[ ! $(command -v gh)     ]] && apt-get install -y gh
fi
apt-get clean && rm -rf /var/lib/apt/lists/*
log "🎉 Dev environment ready"
