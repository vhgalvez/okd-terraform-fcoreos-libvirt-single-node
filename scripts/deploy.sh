#!/usr/bin/env bash
# scripts/destroy.sh — Limpieza TOTAL del entorno SNO (Terraform + archivos + auth)
set -euo pipefail

###############################################
# RUTAS
###############################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

TERRAFORM_DIR="${PROJECT_ROOT}/terraform"
GENERATED_DIR="${PROJECT_ROOT}/generated"
AUTH_DIR="${PROJECT_ROOT}/auth"

TERRAFORM_BIN="${TERRAFORM_BIN:-terraform}"

echo "=============================================="
echo "     DESTRUYENDO CLÚSTER OKD 4.x — SNO"
echo "=============================================="

###############################################
# 1) Terraform destroy + limpieza de estado
###############################################
if command -v "$TERRAFORM_BIN" &>/dev/null; then
    if [[ -d "$TERRAFORM_DIR" ]]; then
        echo "🚨 Ejecutando terraform destroy..."
        "$TERRAFORM_BIN" -chdir="$TERRAFORM_DIR" destroy -auto-approve || true

        echo "🧹 Limpiando artefactos Terraform..."
        rm -rf "${TERRAFORM_DIR}/.terraform" || true
        rm -f "${TERRAFORM_DIR}/terraform.tfstate" || true
        rm -f "${TERRAFORM_DIR}/terraform.tfstate.backup" || true
    else
        echo "⚠ No existe directorio Terraform: $TERRAFORM_DIR"
    fi
else
    echo "⚠ Terraform no está instalado, saltando destroy"
fi

###############################################
# 2) Eliminar generated/
###############################################
if [[ -d "$GENERATED_DIR" ]]; then
    rm -rf "$GENERATED_DIR"
    echo "✔ Carpeta generated/ eliminada"
else
    echo "⚠ generated/ no existe"
fi

###############################################
# 3) Eliminar auth/ (directorio o symlink)
###############################################
if [[ -L "$AUTH_DIR" || -d "$AUTH_DIR" ]]; then
    rm -rf "$AUTH_DIR"
    echo "✔ auth/ eliminado"
else
    echo "⚠ auth/ no existe"
fi

###############################################
# 4) Archivos internos de openshift-install
###############################################
echo "🧨 Eliminando archivos internos del instalador..."

rm -f "${PROJECT_ROOT}/.openshift_install.log"*        || true
rm -f "${PROJECT_ROOT}/.openshift_install_state.json"* || true
rm -f "${PROJECT_ROOT}/.openshift_install.lock"*       || true

rm -f "${PROJECT_ROOT}/metadata.json"                  || true
rm -f "${PROJECT_ROOT}/terraform.tfvars.json"          || true

###############################################
# 5) Eliminar ignitions (*.ign)
###############################################
echo "🗑 Eliminando ignitions (*.ign)..."
find "$PROJECT_ROOT" -type f -name "*.ign" -delete 2>/dev/null || true

###############################################
# 6) Cache local del instalador
###############################################
echo "🧹 Eliminando cache local de openshift-install..."
rm -rf ~/.cache/openshift-install 2>/dev/null || true

###############################################
# 7) Otros restos posibles
###############################################
echo "🪓 Eliminando restos posibles de instalaciones previas..."

rm -rf "${PROJECT_ROOT}/install-dir" || true
rm -rf "${PROJECT_ROOT}/manifests"   || true
rm -rf "${PROJECT_ROOT}/tls"         || true
rm -rf "${PROJECT_ROOT}/downloads"   || true
rm -rf "${PROJECT_ROOT}/kubeconfig"  || true

echo "=============================================="
echo "   ✔ TODO LIMPIO — SNO ELIMINADO CORRECTAMENTE"
echo "=============================================="