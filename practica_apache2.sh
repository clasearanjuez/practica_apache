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

# Directorio donde se clona el repositorio de github
DIR_REPO="/tmp/practica_apache"

echo -e "${VERDE}Conexion a Github y descarga de ficheros desde la rama ${RAMA}${NC}"
if [ -d "$DIR_REPO" ]; then
    rm -rf "$DIR_REPO"
fi
git clone --branch "$RAMA" "$REPO_URL" "$DIR_REPO"
if [ $? -ne 0 ]; then
    echo "Error al clonar el repositorio. Revisa el token y que la rama '${RAMA}' existe."
    exit 1
fi

echo -e "${VERDE}Actualizando repositorios del sistema${NC}"
sudo apt-get update -y

echo -e "${VERDE}Instalando Docker${NC}"
sudo apt-get install -y docker.io

echo -e "${VERDE}Agregando el usuario actual al grupo docker${NC}"
sudo usermod -aG docker "$USER"

echo -e "${VERDE}Instalando git y openssl si no estan presentes${NC}"
sudo apt-get install -y git openssl apache2-utils

echo -e "${VERDE}Descargando imagen de Ubuntu 24.04${NC}"
sudo docker pull ubuntu:24.04

echo -e "${VERDE}Eliminando contenedor previo si existe${NC}"
sudo docker rm -f servidor-web-empresa 2>/dev/null




echo -e "${VERDE}Creando y arrancando el contenedor servidor-web-empresa${NC}"
sudo docker run -d \
    --name servidor-web-empresa \
    -p 80:80 \
    -p 443:443 \
    --restart=always \
    ubuntu:24.04 \
    sleep infinity

echo -e "${VERDE}Instalando Apache2 dentro del contenedor${NC}"
sudo docker exec servidor-web-empresa bash -c "apt-get update -y && apt-get install -y apache2 apache2-utils"

echo -e "${VERDE}Habilitando modulos rewrite, headers y ssl en Apache2${NC}"
sudo docker exec servidor-web-empresa bash -c "a2enmod rewrite headers ssl"




echo -e "${VERDE}Copiando pagina principal al contenedor${NC}"
sudo docker exec servidor-web-empresa bash -c "mkdir -p /var/www/empresa/admin /var/www/clientes"
sudo docker cp "${DIR_REPO}/html/index.html" servidor-web-empresa:/var/www/empresa/index.html
sudo docker cp "${DIR_REPO}/html/estilos.css" servidor-web-empresa:/var/www/empresa/estilos.css
sudo docker cp "${DIR_REPO}/html/panel.html" servidor-web-empresa:/var/www/empresa/admin/panel.html
sudo docker cp "${DIR_REPO}/html/index_clientes.html" servidor-web-empresa:/var/www/clientes/index.html
sudo docker cp "${DIR_REPO}/html/estilos.css" servidor-web-empresa:/var/www/clientes/estilos.css




echo -e "${VERDE}Configurando archivo .htaccess${NC}"
sudo docker cp "${DIR_REPO}/html/htaccess.txt" servidor-web-empresa:/var/www/empresa/.htaccess

echo -e "${VERDE}Copiando configuracion de virtual hosts al contenedor${NC}"
sudo docker cp "${DIR_REPO}/config/empresa.local.conf" servidor-web-empresa:/etc/apache2/sites-available/empresa.local.conf
sudo docker cp "${DIR_REPO}/config/clientes.local.conf" servidor-web-empresa:/etc/apache2/sites-available/clientes.local.conf

echo -e "${VERDE}Habilitando virtual hosts empresa.local y clientes.local${NC}"
sudo docker exec servidor-web-empresa bash -c "a2ensite empresa.local clientes.local && a2dissite 000-default"

echo -e "${VERDE}Generando certificado SSL autofirmado para empresa.local${NC}"
sudo docker exec servidor-web-empresa bash -c "
    openssl req -x509 -newkey rsa:2048 -nodes \
        -keyout /etc/ssl/private/empresa.key \
        -out /etc/ssl/certs/empresa.crt \
        -days 365 \
        -subj '/C=ES/ST=Madrid/O=EmpresaLocal/CN=empresa.local'
"





echo -e "${VERDE}Copiando configuracion SSL al contenedor${NC}"
sudo docker cp "${DIR_REPO}/config/empresa-ssl.conf" servidor-web-empresa:/etc/apache2/sites-available/empresa-ssl.conf
sudo docker exec servidor-web-empresa bash -c "a2ensite empresa-ssl"

echo -e "${VERDE}Configurando autenticacion basica HTTP${NC}"
sudo docker exec servidor-web-empresa bash -c "
    htpasswd -cb /etc/apache2/.htpasswd admin Admin2025!
    htpasswd -b /etc/apache2/.htpasswd supervisor Super2025!
"




echo -e "${VERDE}Arrancando Apache2 dentro del contenedor${NC}"
sudo docker exec servidor-web-empresa bash -c "service apache2 start"

echo -e "${VERDE}Añadiendo entradas en /etc/hosts para resolver empresa.local y clientes.local${NC}"
grep -q "empresa.local" /etc/hosts || echo "127.0.0.1 empresa.local www.empresa.local" | sudo tee -a /etc/hosts
grep -q "clientes.local" /etc/hosts || echo "127.0.0.1 clientes.local" | sudo tee -a /etc/hosts

echo -e "${VERDE}Comprobando que Apache2 esta activo dentro del contenedor${NC}"
sudo docker exec servidor-web-empresa bash -c "service apache2 status"

echo -e "${VERDE}Verificando que el puerto 80 responde${NC}"
curl -s -o /dev/null -w "HTTP status puerto 80: %{http_code}\n" http://localhost

echo -e "${VERDE}Verificando que empresa.local responde por HTTP${NC}"
curl -s -o /dev/null -w "HTTP status empresa.local: %{http_code}\n" http://empresa.local

echo -e "${VERDE}Verificando que clientes.local responde por HTTP${NC}"
curl -s -o /dev/null -w "HTTP status clientes.local: %{http_code}\n" http://clientes.local

echo -e "${VERDE}Verificando autenticacion en /admin (debe pedir credenciales - codigo 401)${NC}"
curl -s -o /dev/null -w "HTTP status sin credenciales en /admin: %{http_code}\n" http://empresa.local/admin/
curl -s -o /dev/null -w "HTTP status con usuario admin en /admin: %{http_code}\n" -u admin:Admin2025! http://empresa.local/admin/panel.html

echo -e "${VERDE}Verificando HTTPS en empresa.local${NC}"
curl -k -s -o /dev/null -w "HTTP status empresa.local HTTPS: %{http_code}\n" https://empresa.local

echo -e "${VERDE}Mostrando modulos activos en Apache2${NC}"
sudo docker exec servidor-web-empresa bash -c "apache2ctl -M 2>/dev/null | grep -E 'rewrite|headers|ssl'"

echo -e "${VERDE}Instalacion y configuracion completada correctamente${NC}"
