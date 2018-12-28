FROM adhocguru/app:php


LABEL maintainer="Aleksandr Zaichenko <alllexandr@gmail.com>"

ENV WWW_FOLDER /var/www/html
ENV WWW_USER www-data
ENV WWW_GROUP www-data


WORKDIR /tmp

RUN ls

COPY . "${WWW_FOLDER}"/

RUN cd ${WWW_FOLDER} && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php && php composer.phar install
RUN cd ${WWW_FOLDER} && yarn --modules-folder public_html/libraries

RUN chown -R ${WWW_USER}:${WWW_GROUP} ${WWW_FOLDER}/* && \
    chown -R ${WWW_USER}:${WWW_GROUP} ${WWW_FOLDER}
#RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
#RUN php composer-setup.php
#RUN php composer.phar install

ADD deploy/php.ini /usr/local/etc/php/php.ini

ADD deploy/init.sh /usr/local/bin/init.sh

RUN chmod u+x /usr/local/bin/init.sh

ADD deploy/crons.conf /root/crons.conf

ADD deploy/docker-php.conf /etc/apache2/conf-enabled/docker-php.conf
RUN a2enmod headers
#RUN crontab /root/crons.conf

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/init.sh"]
