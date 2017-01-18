#!/bin/bash
# Script to set up a Django project on Vagrant.
PROJECT_NAME=$1

DB_NAME=$PROJECT_NAME
DB_USERNAME=$PROJECT_NAME
DB_PASSWD=$PROJECT_NAME
VIRTUALENV_NAME=$PROJECT_NAME

PROJECT_DIR=/home/vagrant/$PROJECT_NAME
VIRTUALENV_DIR=/home/vagrant/.virtualenvs/$PROJECT_NAME


# Install essential packages from Apt
apt-get update -y

# Python dev packages
#apt-get install -y build-essential python python3-dev npm
apt-get build-dep -y python-imaging
apt-get install -y python3-pip \
        libjpeg8 \
        libjpeg62-dev \
        libfreetype6 \
        libfreetype6-dev \
        libpq-dev \
        wget

# Git
apt-get install -y git

# Postgresql
if ! command -v psql; then
    apt-get install -y postgresql libpq-dev
fi

# Create vagrant pgsql superuser
su - postgres -c "createuser -s vagrant"


if ! command -v pip; then
    easy_install -U pip
fi


# install python packages
pip install -r $PROJECT_DIR/requirements/base.txt
pip install -r $PROJECT_DIR/requirements/dev.txt

cp $PROJECT_DIR/etc/local_config.yaml.sample $PROJECT_DIR/local_config.yaml
sed '/^secret_key/ d' $PROJECT_DIR/local_config.yaml > $PROJECT_DIR/tmp.yaml && mv tmp.yaml local_config.yaml
UUID=a63eb5ef-3b25-4595-846a-5d97d99486f0
echo "secret_key: $UUID" >> $PROJECT_DIR/local_config.yaml

# postgresql setup for project
su - postgres -c "psql -c 'CREATE ROLE $DB_USERNAME;'"
su - postgres -c "psql -c \"ALTER USER $DB_USERNAME with password '$DB_PASSWD';\""
su - postgres -c "psql -c \"ALTER ROLE $DB_USERNAME WITH LOGIN;\""
su - postgres -c "psql -c \"CREATE DATABASE $DB_NAME WITH  TEMPLATE=template0 ENCODING='utf-8' owner $DB_USERNAME;\""


# Django project setup
cp $PROJECT_DIR/etc/vagrant/settings.py $PROJECT_DIR/volontulo_org/settings/dev.py

$PROJECT_DIR/manage.py migrate --settings=volontulo_org.settings.dev
$PROJECT_DIR/manage.py loaddata $PROJECT_DIR/initial/data.json --settings=volontulo_org.settings.dev


# Instrall nodejs
NODE_VERSION="7.4.0"
NVM_DIR="/root/.nvm"

wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.32.1/install.sh | bash && \
    source $NVM_DIR/nvm.sh && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION && \
    nvm use default

# Install gulp
su - -c "cd $PROJECT_DIR/apps/volontulo && \
   npm install && \
   npm install gulp && \
   node node_modules/.bin/gulp build"


# Finish
cat << "EOF"

///     #//(  &(//////#    //(          (//////#@    (///    (/(  //////////( ///     (//   ///         &(//////#
#//(    ///  /////#/////#  //(        ///////////(   (////   (/(     #//#     ///     (//   ///        ////// ////#
 (//%  #//( (////( (#////% //(       (///#%/# (///#  (/////& (/(     #//#     ///     (//   ///       (/////# /////
  /// %//(  ///%/    %///( //(        /(&@&( #(& /(  (// ///&(/(     #//#     (//     (//   ///       ///#     #///
  #/////(   (///#    ////  //(         #///%(&/////  (//  (////(     #//#     (//     (//   ///       #///      (//
   /////     ()#///(&///   //(&&&&&&@   #////////    (//   #///(     #//#     #///#////     ///&&&&@   #///(((((//

EOF
