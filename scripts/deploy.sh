#!/usr/bin/env bash
# scripts/deploy.sh — SNO REAL OKD 4.x deploy (Terraform + Ignition + auth symlink)
set -euo pipefail

###############################################
# RUTAS BASE
###############################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

INSTALL_DIR="${PROJECT_ROOT}/install-config"
GENERATED_DIR="${PROJECT_ROOT}/generated"
IGNITION_DIR="${GENERATED_DIR}/ignition"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"

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

# Validar Terraform
if ! command -v terraform &>/dev/null; then
    echo "❌ ERROR: Terraform no está instalado o no está en el PATH."
    exit 1
fi

# Validar install-config
if [[ ! -f "${INSTALL_DIR}/install-config.yaml" ]]; then
    echo "❌ ERROR: Falta install-config.yaml en ${INSTALL_DIR}/"
    exit 1
fi

###############################################
# CREAR ESTRUCTURA DE CARPETAS
###############################################
echo "📁 Creando estructura interna…"
mkdir -p "$GENERATED_DIR"
mkdir -p "$IGNITION_DIR"

###############################################
# LIMPIEZA LIGERA (NO destruye Terraform state)
###############################################
echo "🧹 Limpiando restos anteriores…"

rm -f "${GENERATED_DIR}"/*.ign 2>/dev/null || true
rm -f "${IGNITION_DIR}"/*.ign 2>/dev/null || true

rm -f "${PROJECT_ROOT}"/.openshift_install.log*        2>/dev/null || true
rm -f "${PROJECT_ROOT}"/.openshift_install_state.json* 2>/dev/null || true
rm -f "${PROJECT_ROOT}"/.openshift_install.lock*       2>/dev/null || true

rm -f "${PROJECT_ROOT}/metadata.json" 2>/dev/null || true

###############################################
# COPIA install-config.yaml
###############################################
echo "📄 Copiando install-config.yaml a generated/"
cp -f "${INSTALL_DIR}/install-config.yaml" "${GENERATED_DIR}/install-config.yaml"

###############################################
# GENERAR IGNITION DEL SNO (bootstrap-in-place)
###############################################
echo "⚙️ Generando Ignition (SNO bootstrap-in-place)…"

"$OPENSHIFT_INSTALL_BIN_DETECTED" create single-node-ignition-config --dir="$GENERATED_DIR"

IGN_FILE="${GENERATED_DIR}/bootstrap-in-place-for-live-iso.ign"

if [[ ! -f "$IGN_FILE" ]]; then
    echo "❌ ERROR: No se generó la Ignition"
    exit 1
fi

echo "✔ Ignition generada: $IGN_FILE"

echo "[+] Moviendo Ignition a ${IGNITION_DIR}/sno.ign"
cp -f "$IGN_FILE" "${IGNITION_DIR}/sno.ign"

###############################################
# SYMLINK auth → generated/auth
###############################################
echo "🔗 Verificando symlink auth → generated/auth"

if [[ -L "${PROJECT_ROOT}/auth" ]]; then
    echo "✔ Symlink ya existe"
elif [[ -d "${PROJECT_ROOT}/auth" ]]; then
    echo "⚠ auth existe como directorio — eliminando"
    rm -rf "${PROJECT_ROOT}/auth"
    ln -s generated/auth auth
    echo "✔ Symlink recreado"
else
    ln -s generated/auth auth
    echo "✔ Symlink creado"
fi

###############################################
# EJECUTAR TERRAFORM
###############################################
echo "🚀 Terraform init…"
terraform -chdir="$TERRAFORM_DIR" init -input=false

TFVARS=()
[[ -f "${TERRAFORM_DIR}/terraform.tfvars" ]] && TFVARS+=( -var-file="terraform.tfvars" )

echo "🚀 Terraform apply…"
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
