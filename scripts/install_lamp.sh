#!/bin/bash
set -ex

# Comprobamos que el identificador del usuario efectivo es root
if [ "$EUID" -ne 0 ]; then
  echo "Este script debe ejecutarse con sudo"
  exit 1
fi

# Evitamos que apt haga preguntas durante la instalación
export DEBIAN_FRONTEND=noninteractive

# Actualizamos los repositorios
apt update

# Instalamos el servidor web apache
apt install apache2 -y

# Copiamos el archivo de configuración de Apache
cp ../conf/000-default.conf /etc/apache2/sites-available

# Habilitamos el módulo de reescritura de Apache
a2enmod rewrite

# Instalamos PHP y las extensiones necesarias
apt install php libapache2-mod-php php-mysql -y

# Reiniciamos el servicio de Apache para aplicar los cambios
systemctl restart apache2

# Eliminamos la página por defecto de Apache
rm -f /var/www/html/index.html

# Copiamos el archivo index.php a la carpeta raíz del servidor web
cp ../php/index.php /var/www/html

# Cambiamos el propietario y el grupo de la carpeta /var/www/html a www-data
chown -R www-data:www-data /var/www/html

# Instalamos MySQL
apt install mysql-server -y
