FROM alpine:3.8

MAINTAINER Zeyu Ye <Shuliyey@gmail.com>

ENV CONFIG "\
      --prefix=/etc/tengine \
      --conf-path=/etc/tengine/tengine.conf \
      --sbin-path=/usr/sbin/tengine \
      --pid-path=/var/run/tengine.pid \
      --lock-path=/var/run/lock/tengine.lock \
      --user=tengine \
      --group=www-data \
      --http-log-path=/var/log/tengine/access.log \
      --error-log-path=/var/log/tengine/error.log \
      --http-client-body-temp-path=/var/lib/tengine/client-body \
      --http-proxy-temp-path=/var/lib/tengine/proxy \
      --http-fastcgi-temp-path=/var/lib/tengine/fastcgi \
      --http-scgi-temp-path=/var/lib/tengine/scgi \
      --http-uwsgi-temp-path=/var/lib/tengine/uwsgi \
      --with-imap \
      --with-imap_ssl_module \
      --with-ipv6 \
      --with-pcre-jit \
      --with-http_addition_module \
      --with-http_auth_request_module \
      --with-http_dav_module \
      --with-http_gunzip_module \
      --with-http_gzip_static_module \
      --with-http_flv_module \
      --with-http_mp4_module \
      --with-http_random_index_module \
      --with-http_realip_module \
      --with-http_secure_link_module \
      --with-http_sub_module \
      --with-http_ssl_module \
      --with-http_v2_module \
      --with-http_stub_status_module \
      --with-http_addition_module \
      --with-http_degradation_module \
      --with-file-aio \
      --with-mail \
      --with-mail_ssl_module \
      --with-jemalloc \
      --with-threads"


ADD . /root

RUN \
    addgroup -S tengine \
    && adduser -D -S -h /var/lib/tengine -s /sbin/nologin -G tengine tengine \
    && addgroup -S www-data \
    && adduser tengine www-data \
    && apk add --update \
      gcc \
      libc-dev \
      make \
      openssl-dev \
      pcre-dev \
      zlib-dev \
      linux-headers \
      jemalloc-dev \
      geoip-dev \
    && apk --no-cache add php5 php5-fpm php5-mysqli php5-json php5-openssl php5-curl php5-soap \
      php5-zlib php5-xmlrpc php5-phar php5-intl php5-dom php5-xmlreader php5-ctype php5-gd supervisor curl \
    && cd /root \
    && ./configure $CONFIG \
      # --with-cc-opt='-O2 -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic -fPIC -Wno-error=cast-function-type' \
      # --with-ld-opt='-Wl,-z,relro -Wl,-z,now -pie' \
    && make install -j$(nproc) \
    && chown tengine:www-data /var/log/tengine \
    && chmod 750 /var/log/tengine \
    && install -d /var/lib/tengine /var/www/tengine \
    && chown tengine:www-data /var/www/tengine
    # forward request and error logs to docker log collector
    # && ln -sf /dev/stdout /var/log/tengine/access.log \
    # && ln -sf /dev/stderr /var/log/tengine/error.log

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Remove unneeded packages/files
RUN apk del gcc linux-headers make \
  && rm -rf ~/* ~/.git ~/.gitignore ~/.travis.yml ~/.ash_history \
  && rm -rf /var/cache/apk/*

EXPOSE 80 443

WORKDIR /var/www

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
