#!/usr/bin/env bash
# scripts/deploy.sh — SNO REAL OKD 4.x deploy (Terraform + Ignition + auth symlink)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

mkdir -p "${PROJECT_ROOT}/generated"
mkdir -p "${PROJECT_ROOT}/generated/ignition"

INSTALL_DIR="${PROJECT_ROOT}/install-config"
GENERATED_DIR="${PROJECT_ROOT}/generated"
IGNITION_DIR="${GENERATED_DIR}/ignition}"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"

# ================================
#  Valor por defecto SEGURO
#  (no falla con sudo ni con -u)
# ================================
: "${OPENSHIFT_INSTALL_BIN:=/opt/bin/openshift-install}"

###############################################
# DETECCIÓN AUTOMÁTICA DE openshift-install
###############################################
POSSIBLE_INSTALLERS=(
    "$OPENSHIFT_INSTALL_BIN"
    "/usr/local/bin/openshift-install"
    "/opt/bin/openshift-install"
    "/usr/bin/openshift-install"
    "$SCRIPT_DIR/bin/openshift-install"
)

OPENSHIFT_INSTALL_BIN_DETECTED=""
for p in "${POSSIBLE_INSTALLERS[@]}"; do
    if [[ -x "$p" ]]; then
        OPENSHIFT_INSTALL_BIN_DETECTED="$p"
        break
    fi
done

if [[ -z "$OPENSHIFT_INSTALL_BIN_DETECTED" ]]; then
    echo "❌ ERROR: No se encontró openshift-install."
    echo "   Exporta manualmente:"
    echo "   OPENSHIFT_INSTALL_BIN=/ruta/openshift-install ./scripts/deploy.sh"
    exit 1
fi

echo "✔ Usando openshift-install: $OPENSHIFT_INSTALL_BIN_DETECTED"

###############################################
# VALIDACIONES
###############################################
if ! command -v terraform &>/dev/null; then
    echo "❌ ERROR: Terraform no está instalado."
    exit 1
fi

if [[ ! -f "${INSTALL_DIR}/install-config.yaml" ]]; then
    echo "❌ ERROR: FALTA install-config.yaml en ${INSTALL_DIR}/"
    exit 1
fi

###############################################
# LIMPIEZA LIGERA
###############################################
echo "🧹 Limpieza ligera…"

rm -f "${GENERATED_DIR}"/*.ign || true
rm -f "${IGNITION_DIR}"/*.ign || true
rm -f "${PROJECT_ROOT}"/.openshift_install* || true
rm -f "${PROJECT_ROOT}/metadata.json" || true

###############################################
# COPIAR CONFIG
###############################################
echo "📄 Copiando install-config.yaml…"
cp -f "${INSTALL_DIR}/install-config.yaml" "${GENERATED_DIR}/install-config.yaml"

###############################################
# GENERAR IGNITION SNO
###############################################
echo "⚙️ Generando Ignition SNO…"

"$OPENSHIFT_INSTALL_BIN_DETECTED" create single-node-ignition-config --dir="$GENERATED_DIR"

IGN_FILE="${GENERATED_DIR}/bootstrap-in-place-for-live-iso.ign"
if [[ ! -f "$IGN_FILE" ]]; then
    echo "❌ ERROR: No se generó la Ignition."
    exit 1
fi

echo "✔ Ignition generada: $IGN_FILE"
mkdir -p "$IGNITION_DIR"
cp -f "$IGN_FILE" "${IGNITION_DIR}/sno.ign"

###############################################
# SYMLINK auth
###############################################
echo "🔗 Verificando auth…"

if [[ -L auth ]]; then
    echo "✔ auth es symlink"
else
    rm -rf auth || true
    ln -s generated/auth auth
    echo "✔ Symlink auth → generated/auth creado"
fi

###############################################
# TERRAFORM
###############################################
echo "🚀 Ejecutando Terraform…"
terraform -chdir="$TERRAFORM_DIR" init -input=false

TFVARS=()
[[ -f "${TERRAFORM_DIR}/terraform.tfvars" ]] && TFVARS+=(-var-file="terraform.tfvars")

terraform -chdir="$TERRAFORM_DIR" apply -auto-approve "${TFVARS[@]}"

###############################################
# OUTPUTS
###############################################
echo "=============================================="
echo "   ✔ INFRAESTRUCTURA SNO CREADA"
echo "=============================================="

terraform -chdir="$TERRAFORM_DIR" output || true

echo
echo "Comandos recomendados:"
echo "  ${OPENSHIFT_INSTALL_BIN_DETECTED} wait-for bootstrap-complete --dir=generated --log-level=info"
echo "  ${OPENSHIFT_INSTALL_BIN_DETECTED} wait-for install-complete   --dir=generated --log-level=info"
echo
echo "export KUBECONFIG=\$(pwd)/auth/kubeconfig"
echo "oc get nodes"
echo
echo "🎉 SNO OKD desplegado con éxito."
