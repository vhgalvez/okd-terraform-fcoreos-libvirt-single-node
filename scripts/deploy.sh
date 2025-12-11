#!/usr/bin/env bash
# scripts/deploy.sh — SNO REAL OKD 4.x

set -euo pipefail

###############################################
# RUTAS BÁSICAS
###############################################
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

INSTALL_DIR="${PROJECT_ROOT}/install-config"
GENERATED_DIR="${PROJECT_ROOT}/generated"
IGNITION_DIR="${GENERATED_DIR}/ignition"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"

# Permite sobreescribir la ruta con:
#   OPENSHIFT_INSTALL_BIN=/ruta/openshift-install ./scripts/deploy.sh
OPENSHIFT_INSTALL_BIN="${OPENSHIFT_INSTALL_BIN:-openshift-install}"
TERRAFORM_BIN="${TERRAFORM_BIN:-terraform}"

echo "=============================================="
echo "     DEPLOY OKD 4.x SNO — MODO CORRECTO"
echo "=============================================="

###############################################
# VALIDACIONES
###############################################

# Validar openshift-install
if ! command -v "$OPENSHIFT_INSTALL_BIN" &>/dev/null; then
    echo "❌ ERROR: no se encontró 'openshift-install'."
    echo "   Ruta esperada/actual: $OPENSHIFT_INSTALL_BIN"
    echo "   Solución:"
    echo "     - Añádelo al PATH o"
    echo "     - Ejecuta: OPENSHIFT_INSTALL_BIN=/ruta/openshift-install ./scripts/deploy.sh"
    exit 1
fi

# Validar terraform
if ! command -v "$TERRAFORM_BIN" &>/dev/null; then
    echo "❌ ERROR: no se encontró 'terraform' en el PATH."
    echo "   Instálalo e inténtalo de nuevo."
    exit 1
fi

# Validar install-config.yaml
if [[ ! -f "${INSTALL_DIR}/install-config.yaml" ]]; then
    echo "❌ ERROR: falta install-config.yaml en: ${INSTALL_DIR}/"
    echo "   Debes crear: ${INSTALL_DIR}/install-config.yaml"
    exit 1
fi

###############################################
# PREPARAR DIRECTORIOS
###############################################
mkdir -p "$GENERATED_DIR"
mkdir -p "$IGNITION_DIR"

###############################################
# LIMPIEZA PREVIA
###############################################
echo "🧹 Limpiando archivos previos…"

# Ignitions antiguas
rm -f "${GENERATED_DIR}"/*.ign || true
rm -f "${IGNITION_DIR}"/*.ign || true

# Auth antigua
rm -rf "${GENERATED_DIR}/auth" || true

# Archivos internos de openshift-install
rm -f "${PROJECT_ROOT}/.openshift_install"* || true
rm -f "${PROJECT_ROOT}/metadata.json" || true

###############################################
# COPIAR install-config.yaml A generated/
###############################################
echo "📄 Copiando install-config.yaml a generated/…"
cp -f "${INSTALL_DIR}/install-config.yaml" "${GENERATED_DIR}/"

###############################################
# GENERAR IGNITION SNO (bootstrap-in-place)
###############################################
echo "⚙️  Generando Ignition para SNO (single-node)…"
echo "    Directorio de trabajo: ${GENERATED_DIR}"
echo

"$OPENSHIFT_INSTALL_BIN" create single-node-ignition-config --dir="${GENERATED_DIR}"

IGN_FILE="${GENERATED_DIR}/bootstrap-in-place-for-live-iso.ign"

if [[ ! -f "$IGN_FILE" ]]; then
    echo "❌ ERROR: no se generó ${IGN_FILE}"
    echo "   Revisa la salida de 'openshift-install' justo arriba."
    exit 1
fi

echo "✔ Ignition generada correctamente:"
echo "   ${IGN_FILE}"

# Copiar Ignition al directorio que usa Terraform
cp -f "$IGN_FILE" "${IGNITION_DIR}/sno.ign"
echo "✔ Ignition copiada a: ${IGNITION_DIR}/sno.ign"

###############################################
# CREAR SYMLINK auth -> generated/auth
###############################################
cd "$PROJECT_ROOT"
rm -rf auth || true
ln -s generated/auth auth

echo "🔐 Credenciales del cluster:"
echo "   - auth/kubeadmin-password"
echo "   - auth/kubeconfig"
echo

###############################################
# DESPLIEGUE CON TERRAFORM
###############################################
echo "🚀 Lanzando Terraform (infra SNO en libvirt)…"

"$TERRAFORM_BIN" -chdir="$TERRAFORM_DIR" init -input=false
"$TERRAFORM_BIN" -chdir="$TERRAFORM_DIR" apply -auto-approve

echo
echo "=============================================="
echo "  ✔ INFRAESTRUCTURA SNO CREADA CON TERRAFORM"
echo "=============================================="
echo
echo "Ahora toca esperar a que el cluster termine de arrancar."
echo "Comandos recomendados desde el directorio del proyecto:"
echo
echo "  # Esperar a que termine el bootstrap:"
echo "  ${OPENSHIFT_INSTALL_BIN} wait-for bootstrap-complete \\"
echo "      --dir=generated --log-level=info"
echo
echo "  # Cuando el bootstrap complete, esperar instalación total:"
echo "  ${OPENSHIFT_INSTALL_BIN} wait-for install-complete \\"
echo "      --dir=generated --log-level=info"
echo
echo "  # Para usar oc directamente:"
echo "  export KUBECONFIG=\$(pwd)/auth/kubeconfig"
echo "  oc get nodes"
echo
echo "✅ Si esos pasos pasan, tienes tu SNO OKD 4.x completamente funcional."