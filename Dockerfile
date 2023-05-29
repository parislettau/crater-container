# Use latest offical ubuntu image
FROM ubuntu:latest

# Set timezone environment variable
ENV TZ=Australia/Melbourne

# Set geographic area using above variable
# This is necessary, otherwise building the image doesn't work
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Remove annoying messages during package installation
ARG DEBIAN_FRONTEND=noninteractive

# Install packages: web server Apache, PHP and extensions
RUN apt-get update && apt-get install --no-install-recommends -y \
    apache2 \
    apache2-utils \
    ca-certificates \
    git \
    php \
    libapache2-mod-php \
    php-curl \
    php-dom \
    php-gd \
    php-intl \
    php-json \
    php-mbstring \
    php-xml \
    php-sqlite3 \
    php-zip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    libmagickwand-dev \
    sqlite3 \
    libsqlite3-dev \
    mariadb-client

# Install PHP extensions
RUN apt-get update && apt-get install -y \
    php-mbstring \
    php-mysql \
    php-bcmath 

# docker-php-ext-install pdo_mysql mbstring zip exif pcntl bcmath gd 

# Copy virtual host configuration from current path onto existing 000-default.conf
COPY default.conf /etc/apache2/sites-available/000-default.conf

# Copy cron configuration file
COPY crontab /etc/cron.d/crater-cron

# Remove default content (existing index.html)
RUN rm /var/www/html/*

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/crater-cron

# Fix files and directories ownership
RUN chown -R www-data:www-data /var/www/html/

# Apply cron job
RUN crontab /etc/cron.d/crater-cron

# Activate Apache modules headers & rewrite
RUN a2enmod headers rewrite

# Tell container to listen to port 80 at runtime
EXPOSE 80

# Start Apache web server
CMD [ "/usr/sbin/apache2ctl", "-DFOREGROUND" ]
