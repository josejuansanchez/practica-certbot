#!/bin/bash
set -ex

# Comprobamos que el script se ejecuta como root
if [ "$EUID" -ne 0 ]; then
  echo "Este script debe ejecutarse con sudo"
  exit 1
fi

# Habilitamos 'allexport': toda variable definida a continuación se exportará al entorno.
# Esto hace que las variables de entorno estén disponibles para el binario externo 'envsubst'.
set -a

# Importamos las variables de entorno
source .env

# Comprobamos que las variables necesarias tienen valor
: "${LETS_ENCRYPT_DOMAIN:?Asigne un valor a LETS_ENCRYPT_DOMAIN en .env}"
: "${LETS_ENCRYPT_EMAIL:?Asigne un valor a LETS_ENCRYPT_EMAIL en .env}"

# Realizamos la instalación y actualización de snapd
snap install core
snap refresh core

# Eliminamos si existiese alguna instalación previa de certbot con apt
apt remove certbot -y

# Instalamos el cliente de Certbot con snapd
snap install --classic certbot

# Creamos una alias para el comando certbot
ln -fs /snap/bin/certbot /usr/bin/certbot

# Deshabilitamos los virtual hosts por defecto de Apache
a2dissite 000-default.conf
a2dissite default-ssl.conf

# Creamos el virtual host para el nuevo dominio a partir de la plantilla
envsubst '${LETS_ENCRYPT_DOMAIN} ${LETS_ENCRYPT_EMAIL}' < ../conf/virtualhost.conf.template > "/etc/apache2/sites-available/${LETS_ENCRYPT_DOMAIN}.conf"

# Habilitamos el virtual host para el nuevo dominio
a2ensite "${LETS_ENCRYPT_DOMAIN}.conf"

# Reiniciamos el servicio de Apache
systemctl restart apache2

# Ejecutamos el comando para obtener el certificado SSL de Let's Encrypt y redirigir HTTP a HTTPS
certbot --apache -m "$LETS_ENCRYPT_EMAIL" --agree-tos --no-eff-email -d "$LETS_ENCRYPT_DOMAIN" --non-interactive --redirect
