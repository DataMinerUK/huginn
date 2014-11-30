FROM        phusion/passenger-ruby21:0.9.14
MAINTAINER  Nicola Hughes

################################################################################
# Required packages
################################################################################

RUN	apt-get update
RUN apt-get -y install mysql-server vim

################################################################################
# Huginn user
################################################################################

RUN	useradd huginn -p Pi/lo4hZikFNE -g sudo -m -s /bin/bash
RUN	touch /etc/sudoers.d/huginn && chmod 0440 /etc/sudoers.d/huginn
RUN	echo "huginn ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/huginn

################################################################################
# Huginn install
################################################################################

# Copy the Gemfile and Gemfile.lock into the image.
# Temporarily set the working directory to where they are.

WORKDIR /home/huginn/huginn
ADD ./Gemfile Gemfile
ADD ./Gemfile.lock Gemfile.lock
RUN su huginn -c bundle install

# Everything up to here was cached. This includes
# the bundle install, unless the Gemfiles changed.
# Now copy the app into the image.

ADD . /home/huginn/huginn
RUN	chown -R huginn /home/huginn/huginn

# Copy and change private config variables.
RUN	cd /home/huginn/huginn && su huginn -c 'sed s/REPLACE_ME_NOW\!/$(rake secret)/ .env.example > .env'
RUN bash -c 'cat "/home/huginn/huginn/.config" >> /home/huginn/huginn/.env'
RUN rm /home/huginn/huginn/.config

RUN	cd /home/huginn/huginn && (mysqld &) && su huginn -c 'bundle exec rake db:create; bundle exec rake db:migrate; bundle exec rake db:seed'
RUN	echo "#!/bin/bash\ncd /home/huginn/huginn\nsudo mysqld &\nforeman start" > /home/huginn/start
RUN	chown huginn /home/huginn/start
RUN	chmod +x /home/huginn/start
