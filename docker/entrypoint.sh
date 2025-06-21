#!/bin/bash

# Esperar a que MySQL arranque antes de continuar
echo "Esperando a que MySQL inicie..."
sleep 5

# Inicializar base de datos si no existe
echo "Inicializando base de datos y usuarios..."
mysql -u root -p1234 <<-EOSQL
CREATE DATABASE IF NOT EXISTS laravel;

CREATE USER IF NOT EXISTS 'user'@'%' IDENTIFIED BY '1234';
GRANT ALL PRIVILEGES ON laravel.* TO 'user'@'%';

CREATE USER IF NOT EXISTS 'user'@'localhost' IDENTIFIED BY '1234';
GRANT ALL PRIVILEGES ON laravel.* TO 'user'@'localhost';

FLUSH PRIVILEGES;
EOSQL

# Si hay dump para importar
if [ -f /var/www/dump.sql ]; then
  echo "Importando dump.sql..."
  mysql -u root -p1234 laravel < /var/www/dump.sql
else
  echo "No se encontró dump.sql. Continuando..."
fi

# Ajustar permisos de Laravel
echo "Configurando permisos de Laravel..."
chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache
chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# Iniciar supervisord
echo "Levantando servicios..."
exec /usr/bin/supervisord -n -c /etc/supervisord.conf
