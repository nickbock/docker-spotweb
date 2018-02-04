FROM ubuntu:17.10
MAINTAINER Nick <git@bocky.nl>

ENV DEBIAN_FRONTEND="noninteractive" \
    TERM="xterm" \
    APTLIST="apache2 php7.1 php7.1-curl php7.1-gd php7.1-gmp php7.1-mysql php7.1-xml php7.1-xmlrpc php7.1-mbstring php7.1-zip git-core wget curl cron" \
    REFRESHED_AT='2018-04-02'

RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup &&\
    echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache && \
    apt-get -q update && \
    apt-get -qy dist-upgrade && \
    apt-get install -qy $APTLIST && \

    # Cleanup
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -r /var/www/html && \
    rm -rf /tmp/*

RUN git clone -b master --single-branch https://github.com/spotweb/spotweb.git /var/www/spotweb && \
    rm -rf /var/www/spotweb/.git && \
    mkdir /var/www/spotweb/cache && \
    chmod -R 775 /var/www/spotweb && \
    chown -R www-data:www-data /var/www/spotweb

COPY files/entrypoint.sh /entrypoint.sh
RUN chmod u+x /entrypoint.sh

# Enabling PHP mod rewrite
RUN /usr/sbin/a2enmod rewrite

# Updating hourly cron
RUN touch /var/log/spotweb-retrieve.log
RUN (crontab -l ; echo "1 * * * * /usr/bin/php /var/www/spotweb/retrieve.php >> tee /var/log/spotweb-retrieve.log") | crontab -

COPY files/000-default.conf /etc/apache2/sites-enabled/000-default.conf

ENV DOCKERIZE_VERSION v0.6.0
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz

VOLUME [ "/var/www/spotweb" ]

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
