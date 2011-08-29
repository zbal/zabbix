#!/bin/bash
####################
# Zabbix install one-liner custom install
####################
# Description:
#  - retrieve scripts from github
#  - customize configuration of zabbix-agent
#  - create zabbix cronjob
#  - customize zabbix user
#  - test new items
####################

ZBX_REPO='https://zbal@github.com/zbal/zabbix.git'
ZBX_HOME=/usr/share/zabbix

# Initial Check
check_git=$(git --version 1> /dev/null 2>&1)
  if [ $? -ne 0 ]; then echo "Git is not installed. Aborting."; exit 1 fi


## Zabbix user needs shell to run sudo and cron
usermod -s /bin/bash -m $ZBX_HOME zabbix

## Zabbix sudo needs
# TODO: handle more granular, read and update config instead of appending
cat >> /etc/sudoers << EOF

# Added for Zabbix custom monitoring needs
Defaults:zabbix !requiretty
Cmnd_Alias ZABBIX = /usr/bin/test, /bin/cat, /usr/bin/stat, /usr/bin/tail
zabbix ALL = NOPASSWD: ZABBIX

EOF

## Functions
## Setup or update Zabbix scripts
sync_scripts() {
    cd $ZBX_HOME
    if [ -d .git ]; then
        git pull
    else
        git clone $ZBX_REPO .
    fi
}

# Ugly .. need re-architecture
sync_scripts

create_mysql_config() {

#    if [ -f $ZBX_HOME/conf/my.cnf ]; then
#        echo -n ' * Keep existing login/pass defined in conf/my.cnf ? (Y/n)'; read MY_KEEP
#        if [ -z "$MY_KEEP" -o "$MY_KEEP" == 'Y' -o "$MY_KEEP" == 'y' ]; then
#            return
#        else
#            echo '   ==> Overriding existing configuration'
#        fi
#    fi

    echo -n ' * Enter admin MySQL user: '; read MY_USER
    echo -n ' * Enter admin MySQL pass: '; read -s MY_PASS
    echo -n ' * Enter MySQL host (localhost): '; read MY_HOST
    [ -z "$MY_HOST" ] && MY_HOST='localhost' || MY_HOST=$MY_HOST
    MY_MONIT_PASS=$(cat /dev/urandom | tr -dc "a-zA-Z0-9-_" | head -c 10)

    MYSQL="mysql -u $MY_USER -p$MY_PASS -h $MY_HOST"
    echo
    echo -n ' * Creating monitoring MySQL user... '
    $MYSQL -e "create user 'monitoring'@'$MY_HOST' identified by '$MY_MONIT_PASS'; grant PROCESS, REPLICATION CLIENT, SHOW DATABASES on *.* to 'monitoring'@'$MY_HOST'; flush privileges;" 2> /dev/null
    [ $? -eq 0 ] && echo 'OK' || echo 'Error'

    ## Creating configuration file
    mkdir -p $ZBX_HOME/conf
    cat > $ZBX_HOME/conf/my.cnf << EOF
[client]
user=monitoring
password=$MY_MONIT_PASS
host=$MY_HOST
EOF
}



## Handle MySQL
echo -n 'Install MySQL monitoring on this host ? (Y/n) '; read MY_STATUS

if [ -z "$MY_STATUS" -o "$MY_STATUS" == 'Y' -o "$MY_STATUS" == 'y' ]; then
    MY_ENABLE=1
else
    MY_ENABLE=0
fi

# Handle MySQL if required during the installation
[ $((MY_ENABLE)) -eq 1 ] && create_mysql_config

## Create crontab
## TODO: use patch instead
if [ ! -f /etc/cron.d/zabbix ]; then
    cp $ZBX_HOME/setup/zabbix.cron /etc/cron.d/zabbix
else
    echo 'Commenting out existing cronjob for zabbix...'
    sed -i 's/^/# /' /etc/cron.d/zabbix
    echo 'Appending new cronjob for zabbix...'
    cat $ZBX_HOME/setup/zabbix.cron >> /etc/cron.d/zabbix
fi

## Appending UserParameters to zabbix-agentd.conf
## TODO: use patch instead
if [ ! -f /etc/zabbix/zabbix_agentd.conf ]; then
    echo 'Missing zabbix configuration file.'
    echo 'Install Zabbix and append the configuration manually'
    echo " Custom configuration available in $ZBX_HOME/setup/zabbix_agentd-extra.conf"
else
    echo 'Appending custom UserParameters to zabbix configuration file...'
    cat $ZBX_HOME/setup/zabbix_agentd-extra.conf >> /etc/zabbix/zabbix-agentd.conf
fi

## Restarting agent
service zabbix-agentd restart

