FROM ubuntu:12.04

# Install dependencies
RUN apt-get update -y
RUN apt-get install -y git curl apache2 php5 libapache2-mod-php5 php5-mcrypt php5-mysql

#Update system and install packages
RUN [ "apt-get", "-q", "update" ]
RUN [ "apt-get", "-qy", "--force-yes", "upgrade" ]
RUN [ "apt-get", "-qy", "--force-yes", "dist-upgrade" ]
RUN [ "apt-get", "install", "-qy", "--force-yes", \
      "perl", \
      "build-essential", \
      "cpanminus" ]
RUN [ "apt-get", "clean" ]
RUN [ "rm", "-rf", "/var/lib/apt/lists/*", "/tmp/*", "/var/tmp/*" ]

#Install cpan modules
RUN ["cpanm", "Proc::ProcessTable", "Data::Dumper" ]

# Install app just to test from frontend
RUN rm -rf /var/www/*
ADD src /var/www

# Configure apache
RUN a2enmod rewrite
RUN chown -R www-data:www-data /var/www
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

EXPOSE 80

CMD ["/usr/sbin/apache2", "-D",  "FOREGROUND"]


#For Log Management
RUN apt-get -q update && \
  apt-get -y -q dist-upgrade && \
  apt-get -y -q install rsyslog python python-setuptools python-dev python-distribute python-pip curl
  RUN apt-get install -y nginx openssh-server git-core openssh-client curl
  RUN apt-get install -y nano
  RUN apt-get install -y build-essential
  RUN apt-get install -y openssl libreadline6 libreadline6-dev curl zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison subversion pkg-config

  # install RVM, Ruby, and Bundler
  #RUN \curl -L https://get.rvm.io | bash -s stable
  #RUN /bin/bash -l -c "rvm requirements"
  #RUN /bin/bash -l -c "rvm install 2.0"
  #RUN /bin/bash -l -c "gem install bundler --no-ri --no-rdoc"
  RUN apt-get update -q && \
    apt-get install -qy curl ca-certificates gnupg2 build-essential --no-install-recommends && apt-get clean
  RUN gpg2 --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
  RUN curl -sSL https://get.rvm.io | bash -s
  RUN /bin/bash -l -c ". /etc/profile.d/rvm.sh && rvm install 2.3.3"

RUN curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -o awslogs-agent-setup.py

RUN sed -i "s/#\$ModLoad imudp/\$ModLoad imudp/" /etc/rsyslog.conf && \
  sed -i "s/#\$UDPServerRun 514/\$UDPServerRun 514/" /etc/rsyslog.conf && \
  sed -i "s/#\$ModLoad imtcp/\$ModLoad imtcp/" /etc/rsyslog.conf && \
  sed -i "s/#\$InputTCPServerRun 514/\$InputTCPServerRun 514/" /etc/rsyslog.conf

RUN sed -i "s/authpriv.none/authpriv.none,local6.none,local7.none/" /etc/rsyslog.d/50-default.conf

RUN echo "if \$syslogfacility-text == 'local6' and \$programname == 'httpd' then /var/log/httpd-access.log" >> /etc/rsyslog.d/httpd.conf && \
	echo "if \$syslogfacility-text == 'local6' and \$programname == 'httpd' then ~" >> /etc/rsyslog.d/httpd.conf && \
	echo "if \$syslogfacility-text == 'local7' and \$programname == 'httpd' then /var/log/httpd-error.log" >> /etc/rsyslog.d/httpd.conf && \
	echo "if \$syslogfacility-text == 'local7' and \$programname == 'httpd' then ~" >> /etc/rsyslog.d/httpd.conf
RUN apt-get update && apt-get install -y python python-dev python3.5 python3.5-dev python-pip virtualenv libssl-dev libpq-dev git build-essential libfontconfig1 libfontconfig1-dev
RUN pip install setuptools pip --upgrade --force-reinstall
RUN virtualenv /venv/testenv/ -p which python3.5
COPY awslogs.conf awslogs.conf
RUN python ./awslogs-agent-setup.py -n -r us-east-1 -c /awslogs.conf

RUN pip install supervisor
COPY supervisord.conf /usr/local/etc/supervisord.conf

EXPOSE 514/tcp 514/udp
CMD ["/usr/local/bin/supervisord"]
