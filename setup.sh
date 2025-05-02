#!/bin/bash

# ================================================================
# Script de despliegue automático con Minikube + Docker Desktop
# Autor: Tu Nombre
# Descripción: Automatiza el montaje de un sitio web estático en Minikube.
# ================================================================

#!/bin/bash

# ==================================================================================
# Script de despliegue automático con Minikube + Docker Desktop + Kubernetes
# Autor: Tu Nombre
# Descripción: Automatiza el montaje de un sitio web estático en Minikube.
# ==================================================================================

set -euo pipefail

# === COLORES ===
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

# === CONFIGURACIÓN ===
WEB_REPO="https://github.com/emilianor2/static-website"  # Repositorio de la página web
K8S_REPO="https://github.com/emilianor2/manifiestos"     # Repositorio de los manifiestos
BASE_DIR="${1:-$HOME/Documentos/k8s-web}"                # Directorio base, por defecto $HOME/Documentos/k8s-web
WEB_MOUNT_DIR="${BASE_DIR}/web-mount"                     # Directorio donde se montará el sitio web
K8S_DIR="${BASE_DIR}/k8s-manifests"                       # Directorio para los manifiestos
TMP_CLONE_DIR="$(mktemp -d)"                              # Directorio temporal para clonar los repositorios
MOUNT_STRING="${WEB_MOUNT_DIR}:/mnt/web"                  # Cadena de montaje

# === FUNCIONES ===

# Función para mostrar mensajes de éxito
log_ok() {
    echo -e "${GREEN}[OK] $1${RESET}"
}

# Función para mostrar mensajes de error
log_error() {
    echo -e "${RED}[ERROR] $1${RESET}"
}

# Función para mostrar mensajes informativos
log_info() {
    echo -e "\n== $1 =="
}

# Función para verificar si los comandos necesarios están instalados
check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 no está instalado."
        read -p "¿Querés intentar instalar $1 automáticamente? (s/n): " resp
        if [[ "$resp" == "s" ]]; then
            case "$1" in
                docker)
                    echo "→ Instalalo manualmente desde: https://docs.docker.com/get-docker/"
                    ;;
                kubectl)
                    echo "→ Instalalo manualmente desde: https://kubernetes.io/docs/tasks/tools/"
                    ;;
                minikube)
                    echo "→ Instalalo manualmente desde: https://minikube.sigs.k8s.io/docs/start/"
                    ;;
            esac
        fi
        exit 1
    else
        log_ok "$1 está instalado."
    fi
}

# Función para esperar que el pod esté en estado "Running"
wait_for_pod_running() {
    local label=$1
    echo "Esperando que el pod '$label' esté en estado 'Running'..."
    for _ in {1..30}; do
        status=$(kubectl get pod -l app="$label" -o jsonpath="{.items[0].status.phase}" 2>/dev/null || echo "Pending")
        if [[ "$status" == "Running" ]]; then
            log_ok "El pod '$label' está en ejecución."
            return
        fi
        sleep 10
    done
    log_error "El pod '$label' no se puso en ejecución a tiempo."
    exit 1
}

# === INICIO DEL SCRIPT ===

log_info "Verificando dependencias necesarias"
check_command docker
check_command kubectl
check_command minikube
check_command git

log_info "Verificando si Docker está activo"
if ! docker info &>/dev/null; then
    log_error "Docker no está activo. Intentando iniciar..."
    nohup systemctl --user start docker-desktop &>/dev/null &
    sleep 60
    if ! docker info &>/dev/null; then
        log_error "Docker sigue sin estar activo. Iniciá Docker Desktop manualmente."
        exit 1
    fi
    log_ok "Docker Desktop iniciado correctamente."
else
    log_ok "Docker está activo."
fi

log_info "Verificando estado de Minikube"
if minikube status &>/dev/null; then
    log_error "⚠️ Ya existe una instancia de Minikube."
    echo "→ Montaje actual: ${MOUNT_STRING}"
    read -p "¿Querés borrar y reiniciar Minikube desde cero? (s/n): " confirm
    if [[ "$confirm" == "s" ]]; then
        log_info "Borrando instancia previa de Minikube"
        minikube delete
    else
        log_error "Abortando para evitar conflictos."
        exit 1
    fi
fi

log_info "Preparando estructura de carpetas"
mkdir -p "$WEB_MOUNT_DIR"
rm -rf "$K8S_DIR"

log_info "Clonando repositorios desde GitHub"

# Clonando el repositorio de la página web
if ! git clone "$WEB_REPO" "$TMP_CLONE_DIR/web"; then
    log_error "Fallo al clonar el repositorio del sitio web."
    exit 1
fi
cp -r "$TMP_CLONE_DIR/web"/* "$WEB_MOUNT_DIR"
rm -rf "$TMP_CLONE_DIR/web"

# Clonando el repositorio de los manifiestos
if ! git clone "$K8S_REPO" "$K8S_DIR"; then
    log_error "Fallo al clonar el repositorio de manifiestos."
    exit 1
fi

log_info "Iniciando Minikube con montaje de volumen local"
minikube start --mount --mount-string="${MOUNT_STRING}"

log_info "Aplicando manifiestos de Kubernetes"
find "$K8S_DIR" -type f -name "*.yaml" | while read -r yaml_file; do
    echo -e "${GREEN}→ Aplicando: $yaml_file${RESET}"
    kubectl apply -f "$yaml_file"
done

wait_for_pod_running "nginx"  # Esperar que el pod nginx esté corriendo

log_info "Abriendo el servicio en el navegador"
minikube service nginx-service

echo -e "\n${GREEN}✅ ¡Listo! Sitio desplegado correctamente usando Minikube y Docker Desktop.${RESET}"

