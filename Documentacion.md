
# 🌐 Entorno Local con Minikube para Servir Sitio Web Estático usando NGINX + Kubernetes

Este proyecto despliega una versión estática personalizada de una página web en un entorno local utilizando **Kubernetes sobre Minikube**. La página se sirve a través de **NGINX**, utilizando un **volumen persistente (PV/PVC)** que monta el contenido directamente desde el sistema de archivos local del host.

---

## 📦 Estructura de los Repositorios
### 📁 Repositorio `static-website` 

pagina-web/

├── index.html

├── style.css

└── assets

    └── cv.pdf
    
### 📁 Repositorio `manifiestos`
manifiestos/
├── deployment/

│   └── nginx-deployment.yaml         # Deployment que levanta el contenedor NGINX

├── service/

│   └── nginx-service.yaml            # Service tipo NodePort para exponer la app

├── volumen/

│   ├── pv.yaml                       # PersistentVolume usando hostPath

│   └── pvc.yaml                      # PersistentVolumeClaim vinculado al PV

└── Documentacion.md                         # Este archivo 🙂

---

## 🧰 Requisitos

Antes de comenzar, asegurate de tener instalado:

- [x] **Git**
- [x] **Minikube**
- [x] **kubectl**
- [x] Un navegador web

> 💡 Si usás Ubuntu, podés instalar Minikube y kubectl desde la terminal. 

---

## 🚀 Paso a Paso

### 1️⃣ Clonar repositorios

Primero cloná los dos repos:

#### a. Repositorio de la página web

git clone https://github.com/emilianor2/static-website.git 

Personalizá el archivo `index.html` y asegurate de tenerlo listo en tu máquina local. Por ejemplo:


/home/emilianor/Escritorio/Cloud/


#### b. Repositorio de manifiestos Kubernetes


git clone https://github.com/emilianor2/manifiestos.git


---

### 2️⃣ Iniciar Minikube con el montaje del volumen

Como vamos a usar el contenido local de tu PC, necesitamos que **Minikube tenga acceso a esa carpeta**.


minikube start --mount --mount-string="/home/emilianor/Escritorio/Cloud/static-website:/mnt/web"




Esto monta tu carpeta de contenido en la máquina virtual de Minikube bajo `/mnt/web`.

---

### 3️⃣ Crear recursos en Kubernetes

Aplicá los manifiestos **en este orden**:


kubectl apply -f volumen/pv.yaml
kubectl apply -f volumen/pvc.yaml
kubectl apply -f deploy/nginx-deployment.yaml
kubectl apply -f service/nginx-service.yaml


---

### 4️⃣ Verificar que todo funcione

#### Ver pod corriendo:


kubectl get pods


Deberías ver algo como:

nginx-deployment-xxxxx   1/1   Running


#### Ver contenido montado:


kubectl exec -it $(kubectl get pod -l app=nginx -o jsonpath="{.items[0].metadata.name}") -- ls /usr/share/nginx/html


Deberías ver `index.html`, `css/` o lo que hayas subido.


### 5️⃣ Acceder desde el navegador

minikube service nginx-service


🎉 ¡Deberías ver tu página personalizada cargada desde el volumen!

---


## 👨‍💻 Autor

**Emiliano Rodriguez**  
Estudiante - Computación en la Nube  
Instituto Tecnológico Universitario - UNCuyo  
2025
