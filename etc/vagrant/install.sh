#!/bin/bash

# Script to set up a Django project on Vagrant.

# Installation settings

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
apt-get install -y build-essential python python3-dev npm
# python-setuptools being installed manually
wget https://bootstrap.pypa.io/ez_setup.py -O - | python3.4
# Dependencies for image processing with Pillow (drop-in replacement for PIL)
# supporting: jpeg, tiff, png, freetype, littlecms
# (pip install pillow to get pillow itself, it is not in requirements.txt)
apt-get build-dep -y python-imaging
apt-get install -y nodejs libjpeg-dev libtiff-dev zlib1g-dev libfreetype6-dev liblcms2-dev libjpeg8 libjpeg62-dev
# Git (we'd rather avoid people keeping credentials for git commits in the repo, but sometimes we need it for pip requirements that aren't in PyPI)
apt-get install -y git

# Postgresql
if ! command -v psql; then
    apt-get install -y postgresql libpq-dev
    # Create vagrant pgsql superuser
    su - postgres -c "createuser -s vagrant"
fi

# virtualenv global setup
if ! command -v pip; then
    easy_install -U pip
fi
if [[ ! -f /usr/local/bin/virtualenv ]]; then
    pip3.4 install virtualenv virtualenvwrapper stevedore virtualenv-clone
fi

# bash environment global setup
cp -p $PROJECT_DIR/etc/vagrant/bashrc /home/vagrant/.bashrc

# ---

# virtualenv setup for project
su - vagrant -c "/usr/local/bin/virtualenv $VIRTUALENV_DIR --python=/usr/bin/python3.4 --no-site-packages && \
    echo $PROJECT_DIR > $VIRTUALENV_DIR/.project && \
    $VIRTUALENV_DIR/bin/pip install -r $PROJECT_DIR/requirements/dev.txt"


cp $PROJECT_DIR/etc/local_config.yaml.sample $PROJECT_DIR/local_config.yaml
sed '/^secret_key/ d' $PROJECT_DIR/local_config.yaml > $PROJECT_DIR/tmp.yaml && mv $PROJECT_DIR/tmp.yaml $PROJECT_DIR/local_config.yaml
UUID=a63eb5ef-3b25-4595-846a-5d97d99486f0
echo "secret_key: $UUID" >> $PROJECT_DIR/local_config.yaml


echo "workon $VIRTUALENV_NAME" >> /home/vagrant/.bashrc

# Set execute permissions on manage.py, as they get lost if we build from a zip file
chmod a+x $PROJECT_DIR/manage.py

# postgresql setup for project
su - postgres -c "psql -c 'CREATE ROLE $DB_USERNAME;'"
su - postgres -c "psql -c \"ALTER USER $DB_USERNAME with password '$DB_PASSWD';\""
su - postgres -c "psql -c \"ALTER ROLE $DB_USERNAME WITH LOGIN;\""
su - postgres -c "psql -c \"CREATE DATABASE $DB_NAME WITH  TEMPLATE=template0 ENCODING='utf-8' owner $DB_USERNAME;\""
su - postgres -c "psql -c \"ALTER USER $DB_USERNAME CREATEDB;\""  # this is needed for running tests


# Django project setup
cp $PROJECT_DIR/etc/vagrant/settings.py $PROJECT_DIR/volontulo_org/settings/dev_vagrant.py
su - vagrant -c "source $VIRTUALENV_DIR/bin/activate && cd $PROJECT_DIR && \
   ./manage.py migrate --settings=volontulo_org.settings.dev_vagrant && \
   ./manage.py loaddata initial/data.json --settings=volontulo_org.settings.dev_vagrant"


# Reinstall Node
su - -c "curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -"
su - -c "sudo apt-get install -y nodejs"

# Install gulp
echo "Installing Gulp"
# su - -c "ln -s /usr/bin/nodejs /usr/bin/node"
# su - vagrant -c "npm install gulp"
su - vagrant -c "cd $PROJECT_DIR/apps/volontulo && \
   npm install && \
   node_modules/.bin/gulp build"


# Finish
cat << "EOF"

///     #//(  &(//////#    //(          (//////#@    (///    (/(  //////////( ///     (//   ///         &(//////#
#//(    ///  /////#/////#  //(        ///////////(   (////   (/(     #//#     ///     (//   ///        ////// ////#
 (//%  #//( (////( (#////% //(       (///#%/# (///#  (/////& (/(     #//#     ///     (//   ///       (/////# /////
  /// %//(  ///%/    %///( //(        /(&@&( #(& /(  (// ///&(/(     #//#     (//     (//   ///       ///#     #///
  #/////(   (///#    ////  //(         #///%(&/////  (//  (////(     #//#     (//     (//   ///       #///      (//
   /////     ()#///(&///   //(&&&&&&@   #////////    (//   #///(     #//#     #///#////     ///&&&&@   #///(((((//

EOF
