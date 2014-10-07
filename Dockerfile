FROM        ubuntu:14.04
MAINTAINER  Nicola Hughes


################################################################################
# Required packages
################################################################################

RUN	apt-get update
RUN	apt-get -y install ruby1.9.1 ruby1.9.1-dev rubygems1.9.1 irb1.9.1
RUN	apt-get -y install ri1.9.1 rdoc1.9.1 build-essential
RUN	apt-get -y install libopenssl-ruby1.9.1 libssl-dev zlib1g-dev
RUN	apt-get -y install libxslt-dev libxml2-dev libmysqlclient-dev curl git
RUN	apt-get -y install mysql-server python-software-properties python g++
RUN	apt-get -y install make
RUN apt-get -y install vim
RUN	gem install rake bundle


################################################################################
# NodeJS (https://index.docker.io/u/mugen/nodejs)
################################################################################

RUN     apt-get install -qq wget
RUN     wget -q http://nodejs.org/dist/v0.10.29/node-v0.10.29-linux-x64.tar.gz
RUN     tar xzf node-v0.10.29-linux-x64.tar.gz --strip-components=1 -C /usr
RUN     rm node-v0.10.29-linux-x64.tar.gz


################################################################################
# Huginn user
################################################################################

RUN	useradd huginn -p Pi/lo4hZikFNE -g sudo -m -s /bin/bash
RUN	touch /etc/sudoers.d/huginn && chmod 0440 /etc/sudoers.d/huginn
RUN	echo "huginn ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/huginn


################################################################################
# Huginn install
################################################################################

RUN	cd /home/huginn && git clone git://github.com/DataMinerUK/huginn.git
RUN	cd /home/huginn/huginn && su huginn -c bundle
RUN	chown -R huginn /home/huginn/huginn

RUN	cd /home/huginn/huginn && su huginn -c 'sed s/REPLACE_ME_NOW\!/$(rake secret)/ .env.example > .env'
RUN	cd /home/huginn/huginn && (mysqld &) && su huginn -c 'rake db:create'
RUN	cd /home/huginn/huginn && (mysqld &) && su huginn -c 'rake db:migrate'
RUN	cd /home/huginn/huginn && (mysqld &) && su huginn -c 'rake db:seed'

RUN	echo "#!/bin/bash\ncd /home/huginn/huginn\nsudo mysqld &\nforeman start" > /home/huginn/start
RUN	chown huginn /home/huginn/start
RUN	chmod +x /home/huginn/start



################################################################################
# Enable Huginn email
################################################################################

RUN su huginn -c 'sed -i "s/SMTP_DOMAIN=your-domain-here.com/SMTP_DOMAIN=$SMTP_DOMAIN/g" /home/huginn/huginn/.env'
RUN su huginn -c 'sed -i "s/SMTP_USER_NAME=you@gmail.com/SMTP_USER_NAME=$SMTP_USER_NAME/g" /home/huginn/huginn/.env'
RUN su huginn -c 'sed -i "s/SMTP_PASSWORD=somepassword/SMTP_PASSWORD=$SMTP_PASSWORD/g" /home/huginn/huginn/.env'


################################################################################
# Refresh Huginn source code. Update VERSION number on changes to remote repo.
################################################################################

RUN	cd /home/huginn/huginn && git pull && su huginn -c bundle && (mysqld &) && su huginn -c 'rake db:migrate'
