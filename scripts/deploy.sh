#!/usr/bin/env bash
# scripts/deploy.sh — SNO REAL OKD 4.x

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

INSTALL_DIR="${PROJECT_ROOT}/install-config"
GENERATED_DIR="${PROJECT_ROOT}/generated"
IGNITION_DIR="${GENERATED_DIR}/ignition"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"

OPENSHIFT_INSTALL_BIN="/opt/bin/openshift-install"

echo "=============================================="
echo "     DEPLOY OKD 4.x SNO — MODO CORRECTO"
echo "=============================================="

mkdir -p "$GENERATED_DIR"
mkdir -p "$IGNITION_DIR"

# Validaciones
if [[ ! -x "$OPENSHIFT_INSTALL_BIN" ]]; then
    echo "❌ ERROR: No existe openshift-install en $OPENSHIFT_INSTALL_BIN"
    exit 1
fi

if [[ ! -f "${INSTALL_DIR}/install-config.yaml" ]]; then
    echo "❌ ERROR: Falta install-config.yaml en install-config/"
    exit 1
fi

# Limpieza previa
echo "🧹 Limpiando archivos previos…"
rm -f "${GENERATED_DIR}"/*.ign || true
rm -f "${IGNITION_DIR}"/*.ign || true
rm -rf "${GENERATED_DIR}/auth" || true

rm -f "${PROJECT_ROOT}/.openshift_install"* || true
rm -f "${PROJECT_ROOT}/metadata.json" || true

# Copiar install-config.yaml
echo "📄 Copiando install-config.yaml…"
cp -f "${INSTALL_DIR}/install-config.yaml" "${GENERATED_DIR}/"

# -----------------------------------------------------
# GENERAR IGNITION DE SINGLE NODE OPENSHIFT (SNO REAL)
# -----------------------------------------------------
echo "⚙️  Generando Ignition para SNO (single-node)…"

"$OPENSHIFT_INSTALL_BIN" create single-node-ignition-config --dir="${GENERATED_DIR}"

IGN_FILE="${GENERATED_DIR}/bootstrap-in-place-for-live-iso.ign"

if [[ ! -f "$IGN_FILE" ]]; then
    echo "❌ ERROR: No se generó bootstrap-in-place-for-live-iso.ign"
    exit 1
fi

echo "✔ Ignition generada correctamente: bootstrap-in-place-for-live-iso.ign"

# Mover Ignition al directorio final
cp -f "$IGN_FILE" "${IGNITION_DIR}/sno.ign"

# Crear symlink auth
cd "$PROJECT_ROOT"
rm -rf auth || true
ln -s generated/auth auth

# Terraform deploy
echo "🚀 Lanzando Terraform…"
terraform -chdir="$TERRAFORM_DIR" init -input=false
terraform -chdir="$TERRAFORM_DIR" apply -auto-approve

echo "=============================================="
echo "  ✔ DESPLIEGUE SNO COMPLETADO CORRECTAMENTE"
echo "=============================================="
