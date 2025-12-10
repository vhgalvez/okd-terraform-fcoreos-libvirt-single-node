#!/usr/bin/env bash
# scripts/destroy.sh

set -euo pipefail

# -----------------------------------------------
# Detectar automáticamente el directorio del proyecto
# -----------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TERRAFORM_DIR="${PROJECT_ROOT}/terraform"
GENERATED_DIR="${PROJECT_ROOT}/generated"

echo "=============================================="
echo "    DESTRUYENDO CLÚSTER OKD 4.x SNO"
echo "=============================================="

# -----------------------------------------------
# 1) Terraform destroy
# -----------------------------------------------
if [[ -d "$TERRAFORM_DIR" ]]; then
    echo "[✔] Ejecutando terraform destroy..."
    terraform -chdir="$TERRAFORM_DIR" destroy -auto-approve || true
else
    echo "⚠ ADVERTENCIA: No existe el directorio Terraform:"
    echo "  → $TERRAFORM_DIR"
fi

# -----------------------------------------------
# 2) Eliminar carpeta generated
# -----------------------------------------------
if [[ -d "$GENERATED_DIR" ]]; then
    rm -rf "$GENERATED_DIR"
    echo "[✔] Carpeta generated eliminada"
else
    echo "⚠ generated/ no existe (OK)"
fi

# -----------------------------------------------
# 3) Logs internos de openshift-install
# -----------------------------------------------
rm -f "${PROJECT_ROOT}"/.openshift_install.log* || true
rm -f "${PROJECT_ROOT}"/.openshift_install_state.json* || true
rm -f "${PROJECT_ROOT}"/.openshift_install.lock* || true
echo "[✔] Logs internos eliminados"

# -----------------------------------------------
# 4) Ignitions en todo el proyecto
# -----------------------------------------------
find "$PROJECT_ROOT" -name "*.ign" -exec rm -f {} \; 2>/dev/null || true
echo "[✔] Ignitions eliminadas"

# -----------------------------------------------
# 5) auth/ (symlink o carpeta)
# -----------------------------------------------
rm -rf "${PROJECT_ROOT}/auth" || true
echo "[✔] auth eliminado"

# -----------------------------------------------
# 6) Cache openshift-install
# -----------------------------------------------
rm -rf ~/.cache/openshift-install || true
echo "[✔] Cache eliminada"

echo "=============================================="
echo "     TODO LIMPIO — CLÚSTER ELIMINADO"
echo "=============================================="
