FROM centos:latest

#ENV hostIP=VAR

RUN rpm -ivh "https://labs.consol.de/repo/stable/rhel7/i386/labs-consol-stable.rhel7.noarch.rpm"
RUN rpm -ivh "https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
ADD add-on/nagios-3.5.1-1.el7.x86_64.rpm /temp/
ADD add-on/nagios-common-3.5.1-1.el7.x86_64.rpm /temp/
RUN yum localinstall -y /temp/nagios-3.5.1-1.el7.x86_64.rpm /temp/nagios-common-3.5.1-1.el7.x86_64.rpm
RUN yum install -y  wget gcc make gcc-c++  libstdc++-static php php-pear php-gd php-common php-mysql php-pdo php-cli thruk supervisor mod_gearman
RUN ["mkdir", "-p", "/usr/local/lib/mk-livestatus/"]
RUN ["chown", "-R", "nagios:nagios", "/usr/local/lib/mk-livestatus/"]
ADD add-on/livestatus.o /usr/local/lib/mk-livestatus/livestatus.o

RUN ["mkdir", "-p", "/var/log/nagios/spool/checkresults/"]
RUN ["chown", "-R", "nagios:nagios", "/var/log/nagios/spool/checkresults/"]
RUN ["chmod", "770", "/var/log/nagios/spool/checkresults"]

RUN ["mkdir", "-p", "/var/spool/nagios/checkresults/"]
RUN ["chown", "-R", "nagios:nagios", "/var/spool/nagios/checkresults/"]
RUN ["chmod", "770", "/var/spool/nagios/checkresults"]

RUN ["mkdir", "-p", "/var/spool/pnp4nagios/"]
RUN ["chown", "-R", "nagios:nagios", "/var/spool/pnp4nagios/"]
RUN ["mkdir", "-p", "/var/log/supervisord/"]
RUN ["chmod", "-R", "770", "/var/log/supervisord/"]

ADD add-on/supervisord.conf  /etc/supervisord.conf
ADD add-on/thruk_local.conf /etc/thruk/thruk_local.conf
RUN ["mkdir", "-p", "/var/run/nagios"]
RUN ["touch", "/var/run/nagios/nagios.lock"]
RUN ["chown", "nagios:nagios", "/var/run/nagios/nagios.lock"]


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

USER nagios
EXPOSE 8080
CMD ["/usr/bin/supervisord"]
