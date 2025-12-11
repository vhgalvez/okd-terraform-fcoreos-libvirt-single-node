#!/usr/bin/env bash
#
# scripts/configure_and_check.sh
# Configura kubeconfig + verifica DNS, API y kubelet
#

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GEN="$ROOT/generated"
KCFG="$HOME/.kube/config"

echo "======================================================"
echo "   CONFIGURANDO KUBECONFIG + VERIFICACIONES OKD SNO"
echo "======================================================"

###############################################################################
# 1) CONFIGURAR KUBECONFIG
###############################################################################
echo "[1/4] 🔧 Configurando kubeconfig…"

if [[ ! -f "$GEN/auth/kubeconfig" ]]; then
    echo "❌ ERROR: No se encontró: $GEN/auth/kubeconfig"
    echo "   → Corre openshift-install o deploy.sh antes."
    exit 1
fi

mkdir -p "$HOME/.kube"

cp "$GEN/auth/kubeconfig" "$KCFG"
chmod 600 "$KCFG"

echo "✔ kubeconfig configurado en $KCFG"


###############################################################################
# 2) VERIFICAR DNS (api / api-int)
###############################################################################
echo
echo "[2/4] 🌐 Verificando DNS…"

NAME=$(yq e '.metadata.name' "$ROOT/install-config/install-config.yaml")
DOMAIN=$(yq e '.baseDomain' "$ROOT/install-config/install-config.yaml")

API="api.$NAME.$DOMAIN"
API_INT="api-int.$NAME.$DOMAIN"

echo "→ dig $API"
dig "$API" || echo "⚠ No responde DNS externo para $API"

echo
echo "→ dig $API_INT"
dig "$API_INT" || echo "⚠ No responde DNS api-int"


###############################################################################
# 3) VERIFICAR API (oc whoami)
###############################################################################
echo
echo "[3/4] 🔌 Verificando acceso API del cluster…"

if oc whoami >/dev/null 2>&1; then
    echo "✔ API OK → usuario: $(oc whoami)"
else
    echo "❌ ERROR: No se puede conectar a la API"
    echo "   - Revisa si la VM SNO está encendida"
    echo "   - Revisa si kubelet levantó la API"
    echo "   - Revisa logs: journalctl -u kubelet -f"
    exit 1
fi


###############################################################################
# 4) VERIFICAR KUBELET
###############################################################################
echo
echo "[4/4] 🐞 Verificando estado de kubelet…"

if systemctl is-active --quiet kubelet; then
    echo "✔ kubelet activo"
else
    echo "❌ kubelet no está activo"
    echo "   → journalctl -u kubelet -b -n 50"
    exit 1
fi

echo
echo "→ Últimas 20 líneas de kubelet:"
sudo journalctl -u kubelet -n 20 || true


echo
echo "======================================================"
echo "   ✔ KUBECONFIG + DNS + API + KUBELET → TODO OK"
echo "======================================================"