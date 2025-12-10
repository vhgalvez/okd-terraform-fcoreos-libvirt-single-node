#!/usr/bin/env bash
# scripts/deploy.sh

set -euo pipefail

PROJECT_ROOT="/opt/okd-terraform-fcoreos-libvirt-single-node"
SCRIPT_DIR="${PROJECT_ROOT}/scripts"

INSTALL_DIR="${PROJECT_ROOT}/install-config"
GENERATED_DIR="${PROJECT_ROOT}/generated"
IGNITION_DIR="${GENERATED_DIR}/ignition"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"
OPENSHIFT_INSTALL_BIN="/opt/bin/openshift-install"

echo "=============================================="
echo "      DEPLOY AUTOMÁTICO OKD 4.x SNO"
echo "=============================================="

mkdir -p "$GENERATED_DIR"
mkdir -p "$IGNITION_DIR"

# 0) Validaciones
if [[ ! -x "$OPENSHIFT_INSTALL_BIN" ]]; then
    echo "❌ ERROR: No existe openshift-install en $OPENSHIFT_INSTALL_BIN"
    exit 1
fi

if [[ ! -f "${INSTALL_DIR}/install-config.yaml" ]]; then
    echo "❌ ERROR: Falta install-config/install-config.yaml"
    exit 1
fi

# 1) Limpieza ligera
rm -f "${GENERATED_DIR}"/*.ign || true
rm -f "${IGNITION_DIR}"/*.ign || true

rm -f "${PROJECT_ROOT}"/.openshift_install.log* || true
rm -f "${PROJECT_ROOT}"/.openshift_install_state.json* || true
rm -f "${PROJECT_ROOT}"/.openshift_install.lock* || true

# 2) Copiar install-config
cp -f "${INSTALL_DIR}/install-config.yaml" "${GENERATED_DIR}/"

# 3) Generar Ignition
"$OPENSHIFT_INSTALL_BIN" create ignition-configs --dir="$GENERATED_DIR"

# 4) Mover ignitions
mv -f "${GENERATED_DIR}"/*.ign "$IGNITION_DIR/"

# 5) Symlink auth
cd "$PROJECT_ROOT"
rm -rf auth || true
ln -s generated/auth auth

# 6) Terraform
terraform -chdir="$TERRAFORM_DIR" init -input=false
terraform -chdir="$TERRAFORM_DIR" apply -auto-approve

echo "=============================================="
echo " Deploy finalizado correctamente"
echo "=============================================="
