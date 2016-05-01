FROM nginx:stable

ENV DEBIAN_FRONTEND noninteractive

RUN echo "America/Sao_Paulo" > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

### UPDATE DEBIAN
RUN apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y && apt-get autoremove -y && apt-get install -y locales git vim gzip openssl fail2ban

### CONFIGURE LOCALES
RUN echo "LANGUAGE=pt_BR.UTF-8" >> /etc/environment
RUN echo "LANG=pt_BR.UTF-8"     >> /etc/environment
RUN echo "LC_ALL=pt_BR.UTF-8"   >> /etc/environment
RUN locale-gen pt_BR.UTF-8
RUN dpkg-reconfigure locales

RUN mkdir -p /etc/my_init.d && \
    usermod -u 99 nobody && \
    usermod -g 100 nobody && \
    usermod -d /home nobody && \
    chown -R nobody:users /home

VOLUME ["/config"]

EXPOSE 80 443

ENV HOME="/root"
ENV DHLEVEL="2048"

ADD firstrun.sh /etc/my_init.d/firstrun.sh
ADD defaults/ /defaults/
ADD https://raw.githubusercontent.com/letsencrypt/letsencrypt/master/letsencrypt-auto /defaults/letsencrypt-auto

RUN apt-get install cron -y
RUN chmod +x /etc/my_init.d/firstrun.sh && \
chmod +x /defaults/letsencrypt.sh && \
chmod +x /defaults/letsencrypt-auto && \
chmod +x /etc/service/*/run && \
crontab /defaults/letsencryptcron.conf && \
/defaults/letsencrypt-auto -h && \
update-rc.d -f nginx remove && \
update-rc.d -f fail2ban remove
