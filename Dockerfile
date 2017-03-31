FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

# Configured timezone.
ENV TZ=Australia/Adelaide
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Ensure UTF-8.
RUN locale-gen en_AU.UTF-8
ENV LANG       en_AU.UTF-8
ENV LC_ALL     en_AU.UTF-8

# Use nearby apt mirror.
#RUN sed -i 's%http://archive.ubuntu.com/ubuntu/%mirror://mirrors.ubuntu.com/mirrors.txt%' /etc/apt/sources.list

# Upgrade all currently installed packages and install web server packages.
RUN apt-get update \
&& apt-get -y install software-properties-common python-software-properties \
&& add-apt-repository -y ppa:ondrej/php && apt-get update \
&& apt-get -y dist-upgrade \
&& apt-get -y install apache2 php-common libapache2-mod-php php-apcu php-curl php-gd php-ldap php-memcached php-mysql php7.1-opcache php-mbstring php-bcmath php-xml php-zip php-soap libedit-dev ssmtp \
&& apt-get -y remove --purge software-properties-common python-software-properties \
&& apt-get -y autoremove && apt-get -y autoclean && apt-get clean && rm -rf /var/lib/apt/lists /tmp/* /var/tmp/*

# Apache config.
COPY ./files/apache2-foreground /usr/local/bin/apache2-foreground
COPY ./files/apache2.conf /etc/apache2/apache2.conf
COPY ./files/mime_additional.conf /etc/apache2/mods-available/mime_additional.conf
RUN touch /etc/apache2/mods-available/mime_additional.load
RUN echo "umask 002" >> /etc/apache2/envvars

# PHP config.
COPY ./files/php.ini /etc/php/7.1/mods-available/ua.ini

# Add smtp support
RUN echo "sendmail_path = /usr/sbin/ssmtp -t" > /etc/php/7.1/mods-available/sendmail.ini \
&& echo "mailhub=mail:25\nUseTLS=NO\nFromLineOverride=YES" > /etc/ssmtp/ssmtp.conf

# Configure apache modules, php modules, error logging.
RUN a2enmod rewrite mime_additional \
&& a2dismod vhost_alias \
&& a2dissite 000-default \
&& phpenmod -v ALL -s ALL ua sendmail \
&& chmod +x /usr/local/bin/apache2-foreground

# Configure error logging.
RUN ln -sf /dev/stdout /var/log/apache2/access.log \
&& ln -sf /dev/stderr /var/log/apache2/error.log \
&& truncate -s 0 /etc/apache2/conf-available/other-vhosts-access-log.conf

# Web ports.
EXPOSE 80 443

# set working directory.
WORKDIR /web

# Start the web server.
CMD ["/usr/local/bin/apache2-foreground"]
