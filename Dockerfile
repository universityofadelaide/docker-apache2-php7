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
COPY ./files/sources.list /etc/apt/sources.list
RUN sed -i.bak "s/<mirror>/http:\/\/mirror.internode.on.net\/pub\/ubuntu\/ubuntu/g" /etc/apt/sources.list \
&& sed -i.bak "s/<version>/$(sed -n "s/^.*CODENAME=\(.*\)/\1/p" /etc/lsb-release)/g" /etc/apt/sources.list

# Upgrade all currently installed packages and install web server packages.
RUN apt-get update \
&& apt-get -y dist-upgrade \
&& apt-get -y install apache2 \
&& apt-get -y install php7.0-common libapache2-mod-php7.0 php-apcu php7.0-curl php7.0-gd php7.0-ldap php7.0-mysql php7.0-opcache php7.0-mbstring php7.0-bcmath php7.0-xml libedit-dev \
&& apt-get -y install ssmtp \
&& apt-get -y autoremove && apt-get -y autoclean && apt-get clean && rm -rf /var/lib/apt /tmp/* /var/tmp/*

# Apache config.
COPY ./files/apache2-foreground /usr/local/bin/apache2-foreground
COPY ./files/apache2.conf /etc/apache2/apache2.conf

# PHP config.
COPY ./files/php.ini /etc/php/7.0/mods-available/ua.ini

# Configure timezone and sendmail.
RUN echo "sendmail_path = /usr/sbin/ssmtp -t" > /etc/php/7.0/mods-available/sendmail.ini \
&& echo "mailhub=mail:25\nUseTLS=NO\nFromLineOverride=YES" > /etc/ssmtp/ssmtp.conf

# Configure apache modules, php modules, error logging.
RUN a2enmod rewrite \
&& a2dismod vhost_alias \
&& a2dissite 000-default \
&& phpenmod -v ALL -s ALL ua sendmail \
&& chmod +x /usr/local/bin/apache2-foreground

# Configure error logging.
RUN ln -sf /dev/stdout /var/log/apache2/access.log \
&& ln -sf /dev/stderr /var/log/apache2/error.log

# Web ports.
EXPOSE 80 443

# set working directory.
WORKDIR /web

# Start the web server.
CMD ["/usr/local/bin/apache2-foreground"]
