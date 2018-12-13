FROM php:7.1-apache


LABEL maintainer="Aleksandr Zaichenko <alllexandr@gmail.com>"

# YetiForce CRM
ENV DOWNLOAD_URL https://github.com/YetiForceCompany/YetiForceCRM/releases/download/4.4.0/YetiForceCRM-4.4.0-complete.zip
ENV DOWNLOAD_FILE YetiForceCRM-4.4.0-complete.zip
ENV EXTRACT_FOLDER YetiForceCRM
ENV WWW_FOLDER /var/www/html
ENV WWW_USER www-data
ENV WWW_GROUP www-data

#RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
#RUN apt-get -y purge cmdtest
RUN apt-get update && apt-get upgrade -y
RUN apt-get -y install gnupg apt-transport-https
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get -y purge cmdtest
RUN apt-get update && apt-get install -y yarn

RUN apt-get install -y wget git nodejs vim libfreetype6-dev libxml2-dev libjpeg62-turbo-dev libpng-dev libmcrypt-dev libcurl4-gnutls-dev libssl-dev libc-client2007e-dev libkrb5-dev unzip cron re2c python tree memcached

RUN docker-php-ext-configure imap --with-imap-ssl --with-kerberos && \
    docker-php-ext-install soap curl gd zip mbstring imap mysqli pdo pdo_mysql gd iconv intl opcache   && \
    rm -rf /var/lib/apt/lists/*


WORKDIR /tmp

#RUN wget ${DOWNLOAD_URL}
RUN ls
#RUN unzip $DOWNLOAD_FILE -d $EXTRACT_FOLDER && \
#    rm $DOWNLOAD_FILE && \
#    rm -rf ${WWW_FOLDER}/* && \
#    cp -R ${EXTRACT_FOLDER}/* ${WWW_FOLDER}/ && \
#    chown -R ${WWW_USER}:${WWW_GROUP} ${WWW_FOLDER}/* && \
#    chown -R ${WWW_USER}:${WWW_GROUP} ${WWW_FOLDER}

COPY deploy/yarn /usr/share/
COPY . "${WWW_FOLDER}"/

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y nodejs
RUN cd ${WWW_FOLDER} && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php && php composer.phar install
RUN cd ${WWW_FOLDER} && yarn --modules-folder public_html/libraries

RUN chown -R ${WWW_USER}:${WWW_GROUP} ${WWW_FOLDER}/* && \
    chown -R ${WWW_USER}:${WWW_GROUP} ${WWW_FOLDER}

ADD deploy/php.ini /usr/local/etc/php/php.ini

ADD deploy/init.sh /usr/local/bin/init.sh

RUN chmod u+x /usr/local/bin/init.sh
ADD deploy/docker-php.conf /etc/apache2/conf-enabled/docker-php.conf
RUN a2enmod headers
ADD deploy/crons.conf /root/crons.conf
#RUN crontab /root/crons.conf

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/init.sh"]