FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

# Ensure UTF-8
RUN locale-gen en_AU.UTF-8
ENV LANG       en_AU.UTF-8
ENV LC_ALL     en_AU.UTF-8

# Use nearby apt mirror
COPY ./files/sources.list /etc/apt/sources.list
RUN sed -i.bak "s/<mirror>/http:\/\/mirror.internode.on.net\/pub\/ubuntu\/ubuntu/g" /etc/apt/sources.list
RUN sed -i.bak "s/<version>/$(sed -n "s/^.*CODENAME=\(.*\)/\1/p" /etc/lsb-release)/g" /etc/apt/sources.list

# Start by adding/updating required software
RUN apt-get update
RUN apt-get -y install python-software-properties software-properties-common

# Update again now with the extra repos
RUN apt-get update
RUN apt-get -y dist-upgrade

# Install new packages we need
RUN apt-get -y install apache2

# Configure timezone
RUN echo "Australia/Adelaide" > /etc/timezone; dpkg-reconfigure tzdata

# Update the default virtualhost
RUN a2enmod rewrite
RUN a2dismod vhost_alias

# As everything up to here is exactly the same between PHP versions, its all cached
# in the build process, and is super fast.
RUN apt-get -y install php7.0 php7.0-cli php7.0-common libapache2-mod-php7.0 php-apcu php7.0-curl php7.0-gd php7.0-ldap php7.0-mysql php7.0-opcache php-xdebug php7.0-xml php7.0-mbstring php7.0-bcmath libedit-dev

COPY ./files/apache2-foreground /usr/local/bin/apache2-foreground
COPY ./files/apache2.conf /etc/apache2/apache2.conf

RUN phpenmod -v ALL -s ALL xdebug

# Add smtp support
RUN apt-get -y install ssmtp
RUN echo "sendmail_path = /usr/sbin/ssmtp -t" > /etc/php/7.0/mods-available/sendmail.ini
RUN echo "mailhub=mail:25\nUseTLS=NO\nFromLineOverride=YES" > /etc/ssmtp/ssmtp.conf
RUN phpenmod -v ALL -s ALL sendmail

RUN chmod +x /usr/local/bin/apache2-foreground
RUN a2dissite 000-default

RUN apt-get -y autoclean
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Ports
EXPOSE 80 443

# set working directory.
WORKDIR /web

# Setup stdout/stderr for logging
RUN ln -sf /dev/stdout /var/log/apache2/access.log
RUN ln -sf /dev/stderr /var/log/apache2/error.log

CMD ["/usr/local/bin/apache2-foreground"]
