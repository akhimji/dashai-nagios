FROM centos:latest

#ENV hostIP=VAR

RUN rpm -ivh "https://labs.consol.de/repo/stable/rhel7/i386/labs-consol-stable.rhel7.noarch.rpm"
RUN rpm -ivh "https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
RUN yum install -y nagios wget gcc make gcc-c++  libstdc++-static php php-pear php-gd php-common php-mysql php-pdo php-cli thruk supervisor mod_gearman
RUN wget https://mathias-kettner.de/download/mk-livestatus-1.2.8p20.tar.gz
RUN tar xvfz mk-livestatus-1.2.8p20.tar.gz
RUN rm -rf mk-livestatus-1.2.8p20.tar.gz
RUN ["ln", "-s", "/mk-livestatus-1.2.8p20/nagios4/", "/mk-livestatus-1.2.8p20/src/nagios4"]
RUN ["/mk-livestatus-1.2.8p20/configure", "--with-nagios4"]
RUN ["cd", "/mk-livestatus-1.2.8p20/"]
RUN make -j 8
RUN make install
RUN ["mkdir", "-p", "/var/log/nagios/spool/checkresults"]
RUN ["chown", "-R", "nagios:nagios", "/var/log/nagios/spool/checkresults"]
RUN ["chmod", "770", "/var/log/nagios/spool/checkresults"]
RUN ["chown", "-R", "nagios:nagios", "/var/spool/nagios/checkresults"]
RUN ["chmod", "770", "/var/spool/nagios/checkresults"]
RUN ["mkdir", "-p", "/var/spool/pnp4nagios/"]
RUN ["chown", "-R", "nagios:nagios", "/var/spool/pnp4nagios/"]

RUN ["mkdir", "-p", "/var/log/supervisord/"]
RUN ["chmod", "-R", "770", "/var/log/supervisord/"]

RUN echo "[supervisord]" > /etc/supervisord.conf && \
    echo "nodaemon=true" >> /etc/supervisord.conf && \
#   echo "childlogdir=/var/log/supervisord/" >> /etc/supervisord.conf && \
    echo "logfile=/tmp/supervisord.log" >> /etc/supervisord.conf && \
    echo "pidfile=/tmp/supervisord.pid" >> /etc/supervisord.conf && \
#    echo "user=nagios" >> /etc/supervisord.conf && \
    echo "" >> /etc/supervisord.conf && \
    echo "[program:nagios]" >> /etc/supervisord.conf && \
    echo "user=nagios" >> /etc/supervisord.conf && \
    echo "command=/usr/sbin/nagios /etc/nagios/nagios.cfg" >> /etc/supervisord.conf && \
    echo "" >> /etc/supervisord.conf && \
    echo "[program:httpd]" >> /etc/supervisord.conf && \
    echo "user=nagios" >> /etc/supervisord.conf && \
    echo "command=/usr/sbin/apachectl -D FOREGROUND" >> /etc/supervisord.conf




RUN echo "broker_module=/usr/local/lib/mk-livestatus/livestatus.o  /var/spool/nagios/cmd/live" >> /etc/nagios/nagios.cfg
RUN echo "<Component Thruk::Backend>" >> /etc/thruk/thruk_local.conf && \
    echo "<peer>"  >> /etc/thruk/thruk_local.conf && \
    echo "    name    = local"  >> /etc/thruk/thruk_local.conf && \
    echo "    id      = 7215e"   >> /etc/thruk/thruk_local.conf && \
    echo "    type    = livestatus"  >> /etc/thruk/thruk_local.conf && \
    echo "    <options>"  >> /etc/thruk/thruk_local.conf && \
    echo "        peer          = /var/spool/nagios/cmd/live"  >> /etc/thruk/thruk_local.conf && \
    echo "    </options>"  >> /etc/thruk/thruk_local.conf && \
    echo "</peer>"  >> /etc/thruk/thruk_local.conf && \
    echo "</Component>"  >> /etc/thruk/thruk_local.conf
RUN echo "broker_module=/usr/lib64/mod_gearman/mod_gearman_nagios4.o config=/etc/mod_gearman/module.conf" >> /etc/nagios/nagios.cfg
RUN ["touch", "/var/run/nagios/nagios.lock"]
RUN ["chown", "nagios:nagios", "/var/run/nagios/nagios.lock"]

#RUN echo "set smtp=smtp://${hostIP}:25"  >> /etc/mail.rc
#COPY ./mail.rc /etc/mail.rc

# Add files.
ADD add-on/httpd.conf /etc/httpd/conf/
ADD add-on/thruk.conf /etc/thruk/
ADD add-on/thruk_local.conf /etc/thruk/

ADD add-on/module.conf /etc/mod_gearman/module.conf
ADD add-on/nagios.cfg /etc/nagios/nagios.cfg
RUN mkdir /etc/nagiosql

ADD add-on/nagiosql.tar.gz /etc/nagiosql/
RUN ["chown", "nagios.nagios", "-R", "/etc/nagiosql"]
RUN ["chmod", "770", "-R", "/etc/nagiosql"]

ADD add-on/plugins.tar.gz /usr/lib64/nagios/plugins
RUN ["chown", "nagios.nagios", "-R", "/usr/lib64/nagios/plugins"]
RUN ["chmod", "770", "-R", "/usr/lib64/nagios/plugins"]

ADD add-on/wwwroot.tar.gz /var/www/html/
RUN ["chown", "nagios.nagios", "-R", "/var/www/html"]
RUN ["chmod", "750", "-R", "/var/www/html"]

ADD add-on/fix-perms.sh /
RUN ["chmod", "+x", "/fix-perms.sh"]
RUN /fix-perms.sh

RUN ["chown", "nagios.nagios", "-R", "/var/log/supervisord"]
RUN ["chown", "nagios.nagios", "-R", "/var/log/supervisord/"]
RUN ["chown", "nagios.nagios", "-R", "/var/log/httpd"]

USER root
EXPOSE 8080
CMD ["/usr/bin/supervisord"]
