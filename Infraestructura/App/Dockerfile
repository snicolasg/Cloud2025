FROM public.ecr.aws/amazonlinux/amazonlinux:2

RUN amazon-linux-extras enable epel && \
    yum install -y \
        yum-utils \
        epel-release \
        http://rpms.remirepo.net/enterprise/remi-release-7.rpm && \
    yum-config-manager --enable remi-php54 && \
    yum install -y \
        httpd \
        php php-cli php-common php-mbstring php-xml php-mysql php-fpm mysql \
        unzip wget curl && \
    yum clean all

# Copiar archivos de la aplicación
COPY ./e-commerce-obligatorio/ /var/www/html/

# Ajustar permisos de los archivos
RUN chown -R apache:apache /var/www/html && \
    chmod -R 775 /var/www/html

# Exponer el puerto HTTP
EXPOSE 80

# Iniciar Apache en primer plano
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]

# Le pasa los paramentros al RDS
#RUN /var/www/html/entrypoint.sh