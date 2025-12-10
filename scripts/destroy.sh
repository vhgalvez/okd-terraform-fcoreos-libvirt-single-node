#!/usr/bin/env bash
# scripts/destroy.sh
# Limpieza TOTAL del entorno OKD SNO (Terraform + openshift-install + Ignitions)

set -euo pipefail

# -----------------------------------------------
# Detectar rutas del proyecto
# -----------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TERRAFORM_DIR="${PROJECT_ROOT}/terraform"
GENERATED_DIR="${PROJECT_ROOT}/generated"

echo "=============================================="
echo "      DESTRUYENDO CLÚSTER OKD 4.x SNO"
echo "=============================================="

# -----------------------------------------------
# 1) Terraform destroy
# -----------------------------------------------
if [[ -d "$TERRAFORM_DIR" ]]; then
    echo "[✔] Ejecutando terraform destroy..."
    terraform -chdir="$TERRAFORM_DIR" destroy -auto-approve || true

    # Borrar también la carpeta .terraform y el estado
    echo "[✔] Limpiando estado de Terraform..."
    rm -rf "${TERRAFORM_DIR}/.terraform" || true
    rm -f "${TERRAFORM_DIR}/terraform.tfstate" || true
    rm -f "${TERRAFORM_DIR}/terraform.tfstate.backup" || true
else
    echo "⚠ ADVERTENCIA: No existe el directorio Terraform → $TERRAFORM_DIR"
fi

# -----------------------------------------------
# 2) Eliminar carpeta generated/
# -----------------------------------------------
if [[ -d "$GENERATED_DIR" ]]; then
    rm -rf "$GENERATED_DIR"
    echo "[✔] Carpeta generated/ eliminada"
else
    echo "⚠ generated/ no existe (OK)"
fi

# -----------------------------------------------
# 3) Eliminar archivos residuales de openshift-install
# -----------------------------------------------
echo "[✔] Eliminando archivos ocultos de openshift-install..."
rm -f "${PROJECT_ROOT}/.openshift_install.log"* || true
rm -f "${PROJECT_ROOT}/.openshift_install_state.json"* || true
rm -f "${PROJECT_ROOT}/.openshift_install.lock"* || true

rm -f "${PROJECT_ROOT}/metadata.json" || true
rm -f "${PROJECT_ROOT}/terraform.tfvars.json" || true

# -----------------------------------------------
# 4) Borrar TODAS las Ignitions del proyecto
# -----------------------------------------------
echo "[✔] Eliminando ignitions (*.ign) del proyecto..."
find "$PROJECT_ROOT" -name "*.ign" -type f -exec rm -f {} \; 2>/dev/null || true

# -----------------------------------------------
# 5) auth/ (tokens y kubeconfig)
# -----------------------------------------------
rm -rf "${PROJECT_ROOT}/auth" || true
echo "[✔] auth/ eliminado"

# -----------------------------------------------
# 6) Cache local de openshift-install
# -----------------------------------------------
rm -rf ~/.cache/openshift-install || true
echo "[✔] Cache local de openshift-install eliminada"

# -----------------------------------------------
# 7) Limpieza de directorios residuales por si acaso
# -----------------------------------------------
echo "[✔] Eliminando restos adicionales..."
rm -rf "${PROJECT_ROOT}/install-dir" || true
rm -rf "${PROJECT_ROOT}/kubeconfig" || true
rm -rf "${PROJECT_ROOT}/manifests" || true

echo "=============================================="
echo "   ✔ TODO LIMPIO — CLÚSTER SNO ELIMINADO"
echo "=============================================="