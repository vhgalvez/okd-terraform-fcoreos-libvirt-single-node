#!/usr/bin/env bash
# scripts/deploy.sh - Script para desplegar un clúster OKD 4.x SNO (Single Node OpenShift) utilizando Terraform.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

INSTALL_DIR="${PROJECT_ROOT}/install-config"
GENERATED_DIR="${PROJECT_ROOT}/generated"
IGNITION_DIR="${GENERATED_DIR}/ignition"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"
OPENSHIFT_INSTALL_BIN="/opt/bin/openshift-install"

echo "=============================================="
echo "      DEPLOY OKD 4.x SNO — FINAL"
echo "=============================================="

mkdir -p "$GENERATED_DIR"
mkdir -p "$IGNITION_DIR"

# Validaciones
if [[ ! -x "$OPENSHIFT_INSTALL_BIN" ]]; then
  echo "❌ ERROR: No existe openshift-install en $OPENSHIFT_INSTALL_BIN"
  exit 1
fi

if [[ ! -f "${INSTALL_DIR}/install-config.yaml" ]]; then
  echo "❌ ERROR: Falta install-config.yaml"
  exit 1
fi

# Limpieza previa
rm -f "${GENERATED_DIR}"/*.ign || true
rm -f "${IGNITION_DIR}"/*.ign || true
rm -rf "${GENERATED_DIR}/auth" || true

rm -f "${PROJECT_ROOT}/.openshift_install.log"* || true
rm -f "${PROJECT_ROOT}/.openshift_install_state.json"* || true
rm -f "${PROJECT_ROOT}/.openshift_install.lock"* || true

# Copiar install-config
cp -f "${INSTALL_DIR}/install-config.yaml" "${GENERATED_DIR}/"

# ===== GENERAR IGNITION SNO REAL =====
echo "✔ Generando Ignition SNO (Bootstrap-in-place)"

"${OPENSHIFT_INSTALL_BIN}" create single-node-ignition-config --dir="${GENERATED_DIR}"

# mover ignitions
mv -f "${GENERATED_DIR}/master.ign" "${IGNITION_DIR}/master.ign"

# auth symlink
cd "$PROJECT_ROOT"
rm -rf auth || true
ln -s generated/auth auth

# Terraform deploy
terraform -chdir="$TERRAFORM_DIR" init -input=false
terraform -chdir="$TERRAFORM_DIR" apply -auto-approve

echo "=============================================="
echo "   ✔ SNO INSTALADO CORRECTAMENTE"
echo "=============================================="
