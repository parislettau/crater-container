# Use latest offical ubuntu image
FROM ubuntu:latest

# Set timezone environment variable
ENV TZ=Europe/Berlin

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
    php-zip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*


# Remove default content (existing index.html)
RUN rm /var/www/html/*

# Clone the repository from github https://github.com/crater-invoice/crater (opens new window).
RUN git clone https://github.com/crater-invoice/crater.git /var/www/html

# Install Yarn globally if you haven't installed that already , for more information please refer this link(opens new window)
RUN apt-get update
RUN apt-get install nodejs npm
RUN npm install -g yarn

# After installing Yarn globally , run yarn command inside your cloned folder, it will download all the required dependencies.
RUN cd /var/www/html &&\
    yarn && \
    # Run yarn dev to generate the public files (do yarn build if you wish to use it on production).
    yarn dev
# Install composer to your system and run composer install inside your cloned folder to install all laravel/php dependencies.
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
RUN composer install && \
    # Create an .env file by running the following command: cp .env.example .env. Or alternately you can just copy .env.example file to the same folder and re-name it to .env.
    cp .env.example .env  && \
    # run command: php artisan key:generate to generate a unique application key.
    php artisan key:generate

# Open the link to the domain in the browser (Example: https://demo.craterapp.com) and complete the installation wizard as directed.

# Copy virtual host configuration from current path onto existing 000-default.conf
COPY default.conf /etc/apache2/sites-available/000-default.conf

# Fix files and directories ownership
# RUN chown -R www-data:www-data /var/www/html/

# Activate Apache modules headers & rewrite
RUN a2enmod headers rewrite

# Tell container to listen to port 80 at runtime
EXPOSE 80

# Start Apache web server
CMD [ "/usr/sbin/apache2ctl", "-DFOREGROUND" ]