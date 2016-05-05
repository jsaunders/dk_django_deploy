# Copyright 2013 Thatcher Peskens
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from ubuntu:precise

maintainer jsaunders


run echo "deb http://us.archive.ubuntu.com/ubuntu/ precise-updates main restricted" | tee -a /etc/apt/sources.list.d/precise-updates.list

# update packages
run apt-get update

# install required packages
run apt-get install -y python python-dev python-setuptools python-software-properties vim
run apt-get install -y libpq-dev
run apt-get install -y supervisor

# add nginx stable ppa
run add-apt-repository -y ppa:nginx/stable
# update packages after adding nginx repository
run apt-get update
# install latest stable nginx
run apt-get install -y nginx
run apt-get install -y rabbitmq-server

# install pip
run easy_install pip

# install uwsgi now because it takes a little while
run pip install uwsgi

run useradd celeryuser

# install our code
add paywall/requirements.txt /home/docker/code/paywall/
add paywall/requirements/production.txt /home/docker/code/paywall/requirements/
add paywall/requirements/base.txt /home/docker/code/paywall/requirements/


run apt-get install -y libffi-dev

run apt-get install -y libmysqlclient-dev
run pip install MySQL-python
run pip install -r /home/docker/code/paywall/requirements.txt

add . /home/docker/code/
# setup all the configfiles
run echo "worker_rlimit_nofile 100000;" >> /etc/nginx/nginx.conf
run echo "daemon off;" >> /etc/nginx/nginx.conf
run sed -i 's/768/20000/' /etc/nginx/nginx.conf
run rm /etc/nginx/sites-enabled/default
run ln -s /home/docker/code/nginx-app.conf /etc/nginx/sites-enabled/
run ln -s /home/docker/code/supervisor-app.conf /etc/supervisor/conf.d/
run ln -s /home/docker/code/celeryd.conf /etc/default/celeryd
run ln -s /home/docker/code/celerybeat.conf /etc/default/celerybeat

run chmod u+rwx /usr/local/bin/celeryd
run chmod 640 /etc/default/celeryd
run chmod 640 /etc/default/celerybeat
run mkdir /var/log/celery
run mkdir /var/run/celery
run chmod 777 /var/run/celery

env DJANGO_SECRET_KEY j5yh(y-4&t10#ne_k&+%l(nmc)&p82qdsci+g#_k@rc$n%7w@a

env DJANGO_AWS_ACCESS_KEY_ID AKIAIKJXMDHMF7OHOEOA
env DJANGO_AWS_SECRET_ACCESS_KEY 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
env DJANGO_AWS_STORAGE_BUCKET_NAME dkops.cdn
env DJANGO_SECURE_SSL_REDIRECT False
env DJANGO_SETTINGS_MODULE config.settings.production
env STRIPE_PUBLIC_KEY pk_live_wlK415VuvCmOiJe3pkUBmllu
env STRIPE_SECRET_KEY sk_live_t4P4gy7dNDAOzauPLHEmvjO4
RUN sed -i 's/captured=/capture=/' /usr/local/lib/python2.7/dist-packages/payments/models.py
# install django, normally you would remove this step because your project would already
# be installed in the code/app/ directory
run cd /home/docker/code/paywall $$ ls -al
run cd /home/docker/code/paywall && chmod u+rwx ./manage.py
run cd /home/docker/code/paywall $$ ls -al
run cd /home/docker/code/paywall && ./manage.py collectstatic --noinput
#run cd /home/docker/code/paywall && chmod u+rwx ./manage.py && ./manage.py syncdb --noinput
WORKDIR /
expose 80
cmd ["supervisord", "-n"]
