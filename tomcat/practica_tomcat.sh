#!/bin/bash
# Color verde para los mensajes de traza
VERDE='\033[0;32m'
NC='\033[0m'

# Datos del repositorio privado de github
USUARIO="clasearanjuez"
REPO="practica_apache"
TOKEN="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"
RAMA="practicas"
REPO_URL="https://${TOKEN}@github.com/${USUARIO}/${REPO}.git"
# Ruta donde se aloja el repositorio de github
DIR_REPO="/tmp/practica_tomcat"

echo -e "${VERDE}Conexion a Github y descarga de ficheros desde la rama ${RAMA}${NC}"
if [ -d "$DIR_REPO" ]; then
    rm -rf "$DIR_REPO"
fi
git clone --branch "$RAMA" "$REPO_URL" "$DIR_REPO"
if [ $? -ne 0 ]; then
    echo "Error al clonar el repositorio."
    exit 1
fi

echo -e "${VERDE}Actualizando repositorios del sistema${NC}"
sudo apt-get update -y

echo -e "${VERDE}Instalando git, Docker, Java y Maven${NC}"
sudo apt-get install -y git docker.io openjdk-21-jdk maven

echo -e "${VERDE}Agregando el usuario actual al grupo docker${NC}"
sudo usermod -aG docker "$USER"

echo -e "${VERDE}Compilando el WAR del Sitio 1 con Maven${NC}"
cd "${DIR_REPO}/tomcat/sitio1"
mvn clean package -q -DskipTests
if [ $? -ne 0 ]; then
    echo "Error al compilar sitio1."
    exit 1
fi

echo -e "${VERDE}Compilando el WAR del Sitio 2 con Maven${NC}"
cd "${DIR_REPO}/tomcat/sitio2"
mvn clean package -q -DskipTests
if [ $? -ne 0 ]; then
    echo "Error al compilar sitio2."
    exit 1
fi



echo -e "${VERDE}Eliminando contenedor e imagen previos si existen${NC}"
sudo docker rm -f servidor-tomcat 2>/dev/null
sudo docker rmi -f tomcat_tomcat 2>/dev/null

echo -e "${VERDE}Construyendo la imagen Docker con Tomcat 11${NC}"
cd "${DIR_REPO}/tomcat"
sudo docker build -t tomcat_imagen .
if [ $? -ne 0 ]; then
    echo "Error al construir la imagen Docker."
    exit 1
fi

echo -e "${VERDE}Arrancando el contenedor con Docker Compose${NC}"
sudo docker compose up -d
if [ $? -ne 0 ]; then
    echo "Intentando con docker-compose..."
    sudo docker-compose up -d
fi

echo -e "${VERDE}Esperando a que Tomcat arranque${NC}"
sleep 15

echo -e "${VERDE}Comprobando que el contenedor esta en ejecucion${NC}"
sudo docker ps | grep servidor-tomcat





echo -e "${VERDE}Verificando que el Sitio 1 responde en puerto 8080${NC}"
curl -s -o /dev/null -w "HTTP status Sitio1 puerto 8080: %{http_code}\n" http://localhost:8080/sitio1/hello

echo -e "${VERDE}Verificando que el Sitio 2 responde en puerto 8081${NC}"
curl -s -o /dev/null -w "HTTP status Sitio2 puerto 8081: %{http_code}\n" http://localhost:8081/sitio2/hello

echo -e "${VERDE}Verificando HTTPS en puerto 8443${NC}"
curl -k -s -o /dev/null -w "HTTP status HTTPS Sitio1: %{http_code}\n" https://localhost:8443/sitio1/hello

echo -e "${VERDE}Verificando acceso al Manager de Tomcat${NC}"
curl -s -o /dev/null -w "HTTP status Manager: %{http_code}\n" -u admin:Admin2025! http://localhost:8080/manager/html

echo -e "${VERDE}Mostrando contenido del Sitio 1${NC}"
curl -s http://localhost:8080/sitio1/hello

echo -e "${VERDE}Mostrando contenido del Sitio 2${NC}"
curl -s http://localhost:8081/sitio2/hello

echo -e "${VERDE}Instalacion y configuracion completada correctamente${NC}"
