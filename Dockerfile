FROM php:7.4-apache

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Instalar extensiones PHP requeridas por openSIS
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install mysqli pdo pdo_mysql zip opcache

# Configurar PHP
RUN echo "memory_limit = 256M" > /usr/local/etc/php/conf.d/memory.ini \
    && echo "upload_max_filesize = 20M" >> /usr/local/etc/php/conf.d/memory.ini \
    && echo "post_max_size = 20M" >> /usr/local/etc/php/conf.d/memory.ini \
    && echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/memory.ini

# Habilitar mod_rewrite de Apache
RUN a2enmod rewrite

# Copiar archivos de openSIS
COPY . /var/www/html/

# Dar permisos necesarios
RUN chmod -R 755 /var/www/html \
    && chmod -R 777 /var/www/html/assets 2>/dev/null || true \
    && chmod -R 777 /var/www/html/modules 2>/dev/null || true \
    && chown -R www-data:www-data /var/www/html

# Configurar Apache para escuchar en el puerto de Railway
RUN sed -i 's/80/${PORT}/g' /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
    CMD curl -f http://localhost:${PORT}/ || exit 1

# Exponer el puerto que Railway asigna dinámicamente
EXPOSE ${PORT}

# Script de inicio personalizado
RUN echo '#!/bin/bash\n\
sed -i "s/Listen 80/Listen ${PORT}/g" /etc/apache2/ports.conf\n\
sed -i "s/:80/:${PORT}/g" /etc/apache2/sites-available/000-default.conf\n\
apache2-foreground' > /start.sh && chmod +x /start.sh

CMD ["/start.sh"]
