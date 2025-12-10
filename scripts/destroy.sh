#!/usr/bin/env bash
# scripts/destroy.sh

set -euo pipefail

PROJECT_ROOT="/opt/okd-terraform-fcoreos-libvirt-single-node"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"
GENERATED_DIR="${PROJECT_ROOT}/generated"

echo "=============================================="
echo "    DESTRUYENDO CLÚSTER OKD 4.x SNO"
echo "=============================================="

# Terraform destroy
terraform -chdir="$TERRAFORM_DIR" destroy -auto-approve || true

# Carpetas generadas
rm -rf "$GENERATED_DIR"

# Logs internos de openshift-install
rm -f "${PROJECT_ROOT}"/.openshift_install.* || true

# Ignitions
find "$PROJECT_ROOT" -name "*.ign" -exec rm -f {} \;

# auth/
rm -rf "${PROJECT_ROOT}/auth"

# Cache
rm -rf ~/.cache/openshift-install

echo "=============================================="
echo "     TODO LIMPIO — CLÚSTER ELIMINADO"
echo "=============================================="
