FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

# Configured timezone.
ENV TZ=Australia/Adelaide
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Ensure UTF-8.
RUN locale-gen en_AU.UTF-8
ENV LANG       en_AU.UTF-8
ENV LC_ALL     en_AU.UTF-8

# Upgrade all currently installed packages and install web server packages.
RUN apt update \
&& apt-get -y dist-upgrade \
&& apt-get -y install apache2 php7.0-common libapache2-mod-php7.0 php-apcu php7.0-curl php7.0-gd php7.0-ldap php7.0-mysql php7.0-opcache php7.0-mbstring php7.0-bcmath php7.0-xml php7.0-zip php7.0-soap libedit-dev \
&& apt-get -y autoremove && apt-get -y autoclean && apt-get clean && rm -rf /var/lib/apt/lists /tmp/* /var/tmp/*

# Apache config.
COPY ./files/apache2.conf /etc/apache2/apache2.conf

# PHP config.
COPY ./files/php_custom.ini /etc/php/7.0/mods-available/php_custom.ini

# Configure apache modules, php modules, logging.
RUN a2enmod rewrite \
&& a2dismod vhost_alias \
&& a2disconf other-vhosts-access-log \
&& a2dissite 000-default \
&& phpenmod -v ALL -s ALL php_custom

# Add /code /shared directories and ensure ownership by web user.
RUN mkdir -p /code /shared && chown www-data:www-data /code /shared

# Add in bootstrap script.
COPY ./files/apache2-foreground /apache2-foreground
RUN chmod +x /apache2-foreground

# Web port.
EXPOSE 80

# Set working directory.
WORKDIR /code

# Start the web server.
CMD ["/apache2-foreground"]
