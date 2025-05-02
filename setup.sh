#!/bin/bash

# ================================================================
# Script de despliegue automático con Minikube + Docker Desktop
# Autor: Tu Nombre
# Descripción: Automatiza el montaje de un sitio web estático en Minikube.
# ================================================================

set -euo pipefail

# === COLORES ===
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

# === VARIABLES ===
REPO_URL="https://github.com/Estanislao-Tello/web-estatica.git"
MOUNT_PATH="/mnt/web"
TMP_DIR="$(mktemp -d -t webrepo-XXXX)"
WEB_DIR="$HOME/Documents/k8s-web/web-mount"

# === FUNCIONES ===

verificar_dependencias() {
    echo -e "\n== Verificando dependencias necesarias =="
    for cmd in docker kubectl minikube git; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "${RED}[ERROR] $cmd no está instalado.${RESET}"
            exit 1
        else
            echo -e "${GREEN}[OK] $cmd está instalado.${RESET}"
        fi
    done
}

esperar_docker() {
    echo -e "\n== Verificando si Docker está activo =="
    for _ in {1..10}; do
        if docker info &>/dev/null; then
            echo -e "${GREEN}[OK] Docker está activo.${RESET}"
            return
        fi
        echo -e "${YELLOW}Esperando que Docker se inicie...${RESET}"
        sleep 6
    done
    echo -e "${RED}[ERROR] Docker no se inició correctamente.${RESET}"
    exit 1
}

manejar_minikube_existente() {
    if minikube status | grep -q "Running"; then
        echo -e "${YELLOW}[ADVERTENCIA] Ya existe una instancia de Minikube.${RESET}"
        echo -e "→ Montaje actual: $(minikube mount --list 2>/dev/null | head -n 1)"
        
        read -rp "¿Querés eliminar la instancia actual de Minikube y continuar? (s/n): " respuesta
        if [[ "$respuesta" =~ ^[Ss]$ ]]; then
            echo -e "${YELLOW}→ Eliminando instancia existente...${RESET}"
            minikube delete
        else
            echo -e "${RED}[ERROR] Abortando para evitar conflictos.${RESET}"
            exit 1
        fi
    fi
}

clonar_sitio_web() {
    echo -e "\n== Clonando sitio web desde GitHub =="
    if ! git clone "$REPO_URL" "$TMP_DIR"; then
        echo -e "${RED}[ERROR] Fallo al clonar el repositorio del sitio web.${RESET}"
        exit 1
    fi
    mkdir -p "$WEB_DIR"
    cp -r "$TMP_DIR"/* "$WEB_DIR"
    echo -e "${GREEN}[OK] Sitio web copiado a $WEB_DIR${RESET}"
}

iniciar_minikube() {
    echo -e "\n== Iniciando Minikube =="
    minikube start --driver=docker
}

montar_volumen() {
    echo -e "\n== Montando volumen local en Minikube =="
    nohup minikube mount "$WEB_DIR":"$MOUNT_PATH" > /dev/null 2>&1 &
    echo -e "${GREEN}[OK] Volumen montado en $MOUNT_PATH${RESET}"
}

desplegar_aplicacion() {
    echo -e "\n== Aplicando manifiestos de Kubernetes =="
    kubectl apply -f ./volumen
    kubectl apply -f ./deploy
    kubectl apply -f ./service
}

esperar_pod_running() {
    echo -e "\n== Esperando a que el pod esté en estado Running =="
    until kubectl get pods | grep nginx | grep -q Running; do
        echo -e "${YELLOW}Esperando pod...${RESET}"
        sleep 5
    done
    echo -e "${GREEN}[OK] Pod en estado Running${RESET}"
}

abrir_navegador() {
    echo -e "\n== Exponiendo aplicación web =="
    minikube service web-service
}

limpiar() {
    rm -rf "$TMP_DIR"
}

# === EJECUCIÓN SECUENCIAL ===
verificar_dependencias
esperar_docker
manejar_minikube_existente
clonar_sitio_web
iniciar_minikube
montar_volumen
desplegar_aplicacion
esperar_pod_running
abrir_navegador
Limpiar

