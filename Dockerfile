FROM php:8.2-fpm

# Instalar dependencias
RUN apt-get update && apt-get install -y \
    unzip \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    git \
    nginx \
    supervisor \
    mariadb-server

# Instalar Node.js LTS
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && apt-get install -y nodejs

# Instalar Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# PHP extensiones
RUN docker-php-ext-install pdo pdo_mysql

# Config PHP y Nginx
COPY docker/php.ini /usr/local/etc/php/conf.d/
COPY docker/nginx.conf /etc/nginx/nginx.conf

# Supervisor config
COPY docker/supervisord.conf /etc/supervisord.conf

# Directorio de trabajo
WORKDIR /var/www

# Copiar aplicación
COPY ./Laravel /var/www

# Instalar dependencias de PHP y JS
RUN composer install --optimize-autoloader --no-dev
RUN npm install && npm run build

# Dump de base de datos inicial
COPY ./database/dump-erp_crm.sql /var/www/dump.sql

# Crear permisos iniciales
RUN chown -R www-data:www-data /var/www

# Exponer puertos (Nginx escucha en 10000)
EXPOSE 10000

# Crear directorio para mysqld socket
RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld

# Entrypoint script
COPY ./docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Comando inicial: supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
