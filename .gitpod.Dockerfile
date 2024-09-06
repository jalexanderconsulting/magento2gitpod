FROM gitpod/workspace-full:latest

RUN sudo apt-get update
RUN sudo apt-get -y install lsb-release
RUN sudo apt-get -y install apt-utils
#RUN sudo apt-get -y install python
RUN sudo apt-get install -y libmysqlclient-dev
RUN sudo apt-get -y install rsync
RUN sudo apt-get -y install curl
RUN sudo apt-get -y install libnss3-dev
RUN sudo apt-get -y install openssh-client
RUN sudo apt-get -y install mc
RUN sudo apt install -y software-properties-common
RUN sudo apt-get -y install gcc make autoconf libc-dev pkg-config
RUN sudo apt-get -y install libmcrypt-dev
RUN sudo mkdir -p /tmp/pear/cache
RUN sudo mkdir -p /etc/bash_completion.d/cargo
RUN sudo apt install -y php-dev
RUN sudo apt install -y php-pear
RUN sudo apt-get -y install dialog

#Install php-fpm7.4
RUN sudo apt-get update \
    && sudo apt-get install -y curl zip unzip git software-properties-common supervisor sqlite3 \
    && sudo add-apt-repository -y ppa:ondrej/php \
    && sudo apt-get update \
    && sudo apt-get install -y php7.4-dev php7.4-fpm php7.4-common php7.4-cli php7.4-imagick php7.4-gd php7.4-mysql php7.4-pgsql php7.4-imap php-memcached php7.4-mbstring php7.4-xml php7.4-xmlrpc php7.4-soap php7.4-zip php7.4-curl php7.4-bcmath php7.4-sqlite3 php7.4-apcu php7.4-apcu-bc php7.4-intl php-dev php7.4-dev php7.4-xdebug php-redis \
    && sudo php -r "readfile('http://getcomposer.org/installer');" | sudo php -- --install-dir=/usr/bin/ --version=1.10.16 --filename=composer \
    && sudo mkdir /run/php \
    && sudo chown gitpod:gitpod /run/php \
    && sudo chown -R gitpod:gitpod /etc/php \
    && sudo apt-get remove -y --purge software-properties-common \
    && sudo apt-get -y autoremove \
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && sudo update-alternatives --remove php /usr/bin/php8.0 \
    && sudo update-alternatives --remove php /usr/bin/php7.3 \
    && sudo update-alternatives --set php /usr/bin/php7.4 \
    && sudo echo "daemon off;" >> /etc/nginx/nginx.conf

# Install MySQL
ENV PERCONA_MAJOR 8.0
RUN sudo apt-get update \
 && sudo apt-get -y install gnupg2 \
 && sudo apt-get clean && sudo rm -rf /var/cache/apt/* /var/lib/apt/lists/* /tmp/* \
 && sudo mkdir /var/run/mysqld \
 && sudo wget -c https://repo.percona.com/apt/percona-release_latest.stretch_all.deb \
 && sudo dpkg -i percona-release_latest.stretch_all.deb \
 && sudo apt-get update

RUN set -ex; \
	{ \
		for key in \
			percona-server-server/root_password \
			percona-server-server/root_password_again \
			"percona-server-server-$PERCONA_MAJOR/root-pass" \
			"percona-server-server-$PERCONA_MAJOR/re-root-pass" \
		; do \
			sudo echo "percona-server-server-$PERCONA_MAJOR" "$key" password 'nem4540'; \
		done; \
	} | sudo debconf-set-selections; \
	sudo apt-get update; \
	sudo apt-get install -y \
		percona-server-server-8.0 percona-server-client-8.0 percona-server-common-8.0 \
	;
	
RUN sudo chown -R gitpod:gitpod /etc/mysql /var/run/mysqld /var/log/mysql /var/lib/mysql /var/lib/mysql-files /var/lib/mysql-keyring

# Install our own MySQL config
COPY mysql.cnf /etc/mysql/conf.d/mysqld.cnf
COPY .my.cnf /home/gitpod
COPY mysql.conf /etc/supervisor/conf.d/mysql.conf
RUN sudo chown gitpod:gitpod /home/gitpod/.my.cnf

# Install default-login for MySQL clients
COPY client.cnf /etc/mysql/conf.d/client.cnf

#Copy nginx default and php-fpm.conf file
#COPY default /etc/nginx/sites-available/default
COPY php-fpm.conf /etc/php/7.4/fpm/php-fpm.conf
COPY sp-php-fpm.conf /etc/supervisor/conf.d/sp-php-fpm.conf
RUN sudo chown -R gitpod:gitpod /etc/php

COPY nginx.conf /etc/nginx

# Install Redis.
RUN sudo apt-get update \
 && sudo apt-get install -y \
  redis-server \
 && sudo rm -rf /var/lib/apt/lists/*
 
 #n98-magerun2 tool.
 RUN wget https://files.magerun.net/n98-magerun2.phar \
     && chmod +x ./n98-magerun2.phar \
     && sudo mv ./n98-magerun2.phar /usr/local/bin/n98-magerun2
     
RUN sudo chown -R gitpod:gitpod /etc/php
RUN sudo chown -R gitpod:gitpod /etc/nginx
RUN sudo chown -R gitpod:gitpod /etc/init.d/
RUN sudo echo "net.core.somaxconn=65536" | sudo tee /etc/sysctl.conf
     
RUN sudo chown -R gitpod:gitpod /etc/php
RUN sudo rm -f /usr/bin/php
RUN sudo ln -s /usr/bin/php7.4 /usr/bin/php

# nvm environment variables
RUN sudo mkdir -p /usr/local/nvm
RUN sudo chown gitpod:gitpod /usr/local/nvm
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 14.17.3

# Replace shell with bash so we can source files
RUN sudo rm /bin/sh && sudo ln -s /bin/bash /bin/sh

# install nvm
# https://github.com/creationix/nvm#install-script
RUN curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash

# install node and npm, set default alias
RUN source $NVM_DIR/nvm.sh \
  && nvm install $NODE_VERSION \
  && nvm alias default $NODE_VERSION \
  && nvm use default

# add node and npm to path so the commands are available
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH
    
RUN curl https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.6.16.tar.gz --output elasticsearch-5.6.16.tar.gz \
    && tar -xzf elasticsearch-5.6.16.tar.gz
ENV ES_HOME56="$HOME/elasticsearch-5.6.16"

RUN curl https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.8.9.tar.gz --output elasticsearch-6.8.9.tar.gz \
    && tar -xzf elasticsearch-6.8.9.tar.gz
ENV ES_HOME68="$HOME/elasticsearch-6.8.9"

RUN curl https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.9.3-linux-x86_64.tar.gz --output elasticsearch-7.9.3-linux-x86_64.tar.gz \
    && tar -xzf elasticsearch-7.9.3-linux-x86_64.tar.gz
ENV ES_HOME79="$HOME/elasticsearch-7.9.3"

COPY sp-elasticsearch.conf /etc/supervisor/conf.d/elasticsearch.conf

RUN sudo apt-key adv --keyserver "hkps://keys.openpgp.org" --recv-keys "0x0A9AF2115F4687BD29803A206B73A36E6026DFCA" \
    && sudo apt-key adv --keyserver "keyserver.ubuntu.com" --recv-keys "F77F1EDA57EBB1CC" \
    && sudo curl -1sLf 'https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey' | sudo apt-key add - \
    && sudo echo 'deb http://ppa.launchpad.net/rabbitmq/rabbitmq-erlang/ubuntu bionic main' | sudo tee /etc/apt/sources.list.d/rabbitmq.list \
    && sudo echo 'deb-src http://ppa.launchpad.net/rabbitmq/rabbitmq-erlang/ubuntu bionic main' | sudo tee /etc/apt/sources.list.d/rabbitmq.list \
    && sudo echo 'deb https://packagecloud.io/rabbitmq/rabbitmq-server/debian/ buster main' | sudo tee /etc/apt/sources.list.d/rabbitmq.list \
    && sudo echo 'deb-src https://packagecloud.io/rabbitmq/rabbitmq-server/debian/ buster main' | sudo tee /etc/apt/sources.list.d/rabbitmq.list \
    && sudo apt-get update -y \
    && sudo apt-get install -y erlang-base \
       erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets \
       erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key \
       erlang-runtime-tools erlang-snmp erlang-ssl \
       erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl
