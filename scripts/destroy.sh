#!/usr/bin/env bash
# scripts/destroy.sh — Limpieza TOTAL de entorno SNO (Terraform + Ignitions + auth)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TERRAFORM_DIR="${PROJECT_ROOT}/terraform"
GENERATED_DIR="${PROJECT_ROOT}/generated"
AUTH_DIR="${PROJECT_ROOT}/auth"

TERRAFORM_BIN="${TERRAFORM_BIN:-terraform}"

echo "=============================================="
echo "     DESTRUYENDO CLÚSTER OKD 4.x SNO"
echo "=============================================="

###############################################################
# 1) Terraform destroy
###############################################################
if ! command -v "$TERRAFORM_BIN" &>/dev/null; then
    echo "⚠ ADVERTENCIA: Terraform no está instalado, se omite destroy"
else
    if [[ -d "$TERRAFORM_DIR" ]]; then
        echo "[✔] Ejecutando terraform destroy..."
        "$TERRAFORM_BIN" -chdir="$TERRAFORM_DIR" destroy -auto-approve || true

        echo "[✔] Limpiando estado de Terraform..."
        rm -rf "${TERRAFORM_DIR}/.terraform" || true
        rm -f "${TERRAFORM_DIR}/terraform.tfstate" || true
        rm -f "${TERRAFORM_DIR}/terraform.tfstate.backup" || true
    else
        echo "⚠ ADVERTENCIA: No existe directorio Terraform → $TERRAFORM_DIR"
    fi
fi

###############################################################
# 2) Eliminar generated/
###############################################################
if [[ -d "$GENERATED_DIR" ]]; then
    rm -rf "$GENERATED_DIR"
    echo "[✔] Carpeta generated/ eliminada"
else
    echo "⚠ generated/ no existe (OK)"
fi

###############################################################
# 3) Eliminar symlink auth/
###############################################################
if [[ -L "$AUTH_DIR" || -d "$AUTH_DIR" ]]; then
    rm -rf "$AUTH_DIR"
    echo "[✔] auth/ eliminado"
else
    echo "⚠ auth/ no existe (OK)"
fi

###############################################################
# 4) Archivos de openshift-install
###############################################################
echo "[✔] Eliminando archivos de openshift-install..."

rm -f "${PROJECT_ROOT}/.openshift_install.log"* || true
rm -f "${PROJECT_ROOT}/.openshift_install_state.json"* || true
rm -f "${PROJECT_ROOT}/.openshift_install.lock"* || true

rm -f "${PROJECT_ROOT}/metadata.json" || true
rm -f "${PROJECT_ROOT}/terraform.tfvars.json" || true

###############################################################
# 5) Eliminar cualquier Ignition residual (*.ign)
###############################################################
echo "[✔] Eliminando ignitions (*.ign)..."
find "$PROJECT_ROOT" -name "*.ign" -type f -exec rm -f {} \; 2>/dev/null || true

###############################################################
# 6) Cache del instalador
###############################################################
rm -rf ~/.cache/openshift-install || true
echo "[✔] Cache local de openshift-install eliminada"

###############################################################
# 7) Archivos adicionales de instalaciones previas
###############################################################
echo "[✔] Eliminando restos adicionales..."

rm -rf "${PROJECT_ROOT}/install-dir" || true
rm -rf "${PROJECT_ROOT}/kubeconfig" || true
rm -rf "${PROJECT_ROOT}/manifests" || true
rm -rf "${PROJECT_ROOT}/tls" || true
rm -rf "${PROJECT_ROOT}/downloads" || true

echo "=============================================="
echo "   ✔ TODO LIMPIO — CLÚSTER SNO ELIMINADO"
echo "=============================================="