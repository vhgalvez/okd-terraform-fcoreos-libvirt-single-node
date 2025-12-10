#!/usr/bin/env bash
# scripts/deploy.sh — SNO REAL OKD 4.x

set -euo pipefail

# ------------------------------------------
# Rutas del proyecto
# ------------------------------------------
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

# ------------------------------------------
# Crear directorios
# ------------------------------------------
mkdir -p "$GENERATED_DIR"
mkdir -p "$IGNITION_DIR"

# ------------------------------------------
# Validaciones
# ------------------------------------------
if [[ ! -x "$OPENSHIFT_INSTALL_BIN" ]]; then
    echo "❌ ERROR: No existe openshift-install en $OPENSHIFT_INSTALL_BIN"
    exit 1
fi

if [[ ! -f "${INSTALL_DIR}/install-config.yaml" ]]; then
    echo "❌ ERROR: Falta install-config.yaml en install-config/"
    exit 1
fi

# ------------------------------------------
# Limpieza previa
# ------------------------------------------
echo "🧹 Limpiando archivos previos…"

rm -f "${GENERATED_DIR}"/*.ign || true
rm -f "${IGNITION_DIR}"/*.ign || true
rm -rf "${GENERATED_DIR}/auth" || true

rm -f "${PROJECT_ROOT}/.openshift_install."* || true
rm -f "${PROJECT_ROOT}/metadata.json" || true

# ------------------------------------------
# Copiar install-config.yaml
# ------------------------------------------
echo "📄 Copiando install-config.yaml…"
cp -f "${INSTALL_DIR}/install-config.yaml" "${GENERATED_DIR}/"

# ------------------------------------------
# Generar Ignition SNO
# ------------------------------------------
echo "⚙️  Generando Ignition para SNO (single-node)…"

if ! "$OPENSHIFT_INSTALL_BIN" create single-node-ignition-config --dir="${GENERATED_DIR}"; then
    echo "❌ ERROR: Falló la generación de ignition SNO"
    exit 1
fi

# Verificar que master.ign exista
if [[ ! -f "${GENERATED_DIR}/master.ign" ]]; then
    echo "❌ ERROR: No se generó master.ign"
    exit 1
fi

echo "✔ Ignition generada correctamente"

# ------------------------------------------
# Mover ignitions
# ------------------------------------------
mv -f "${GENERATED_DIR}/master.ign" "${IGNITION_DIR}/master.ign"

# ------------------------------------------
# Symlink auth
# ------------------------------------------
echo "🔗 Creando symlink auth/ → generated/auth"

cd "$PROJECT_ROOT"
rm -rf auth || true
ln -s generated/auth auth

# ------------------------------------------
# Terraform
# ------------------------------------------
echo "🚀 Lanzando Terraform…"

terraform -chdir="$TERRAFORM_DIR" init -input=false
terraform -chdir="$TERRAFORM_DIR" apply -auto-approve

echo "=============================================="
echo "  ✔ DESPLIEGUE SNO COMPLETADO CORRECTAMENTE"
echo "=============================================="
