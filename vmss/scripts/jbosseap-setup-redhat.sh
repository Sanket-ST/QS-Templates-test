#!/bin/sh

adddate() {
    while IFS= read -r line; do
        printf '%s %s\n' "$(date "+%Y-%m-%d %H:%M:%S")" "$line";
    done
}

echo "Red Hat JBoss EAP Cluster Intallation Start " | adddate >> jbosseap.install.log
/bin/date +%H:%M:%S >> jbosseap.install.log

EAP_HOME=/opt/rh/eap7/root/usr/share
EAP_RPM_CONF_STANDALONE=/etc/opt/rh/eap7/wildfly/eap7-standalone.conf
EAP_LAUNCH_CONFIG=/opt/rh/eap7/root/usr/share/wildfly/bin/standalone.conf

export EAP_LAUNCH_CONFIG="/opt/rh/eap7/root/usr/share/wildfly/bin/standalone.conf"
echo 'export EAP_HOME="/opt/rh/eap7/root/usr/share"' >> ~/.bash_profile
echo 'export EAP_RPM_CONF_STANDALONE="/etc/opt/rh/eap7/wildfly/eap7-standalone.conf"' >> ~/.bash_profile
source ~/.bash_profile
touch /etc/profile.d/eap_env.sh
echo 'export EAP_HOME="/opt/rh/eap7/root/usr/share"' >> /etc/profile.d/eap_env.sh
echo 'export EAP_RPM_CONF_STANDALONE="/etc/opt/rh/eap7/wildfly/eap7-standalone.conf"' >> /etc/profile.d/eap_env.sh

while getopts "a:t:p:f:" opt; do
    case $opt in
        a)
            artifactsLocation=$OPTARG #base uri of the file including the container
        ;;
        t)
            token=$OPTARG #saToken for the uri - use "?" if the artifact is not secured via sasToken
        ;;
        p)
            pathToFile=$OPTARG #path to the file relative to artifactsLocation
        ;;
        f)
            fileToDownload=$OPTARG #filename of the file to download from storage
        ;;
    esac
done

fileUrl="$artifactsLocation$pathToFile/$fileToDownload$token"

JBOSS_EAP_USER=$9
JBOSS_EAP_PASSWORD=${10}
RHSM_USER=${11}
RHSM_PASSWORD=${12}
RHEL_OS_LICENSE_TYPE=${13}
RHSM_POOL=${14}
IP_ADDR=$(hostname -I)
STORAGE_ACCOUNT_NAME=${15}
CONTAINER_NAME=${16}
STORAGE_ACCESS_KEY=$(echo "${17}" | openssl enc -d -base64)
JAVA_VERSION=${18}
NODE_ID=$(uuidgen | sed 's/-//g' | cut -c 1-23)

echo "JBoss EAP admin user: " ${JBOSS_EAP_USER} | adddate >> jbosseap.install.log
echo "Storage Account Name: " ${STORAGE_ACCOUNT_NAME} | adddate >> jbosseap.install.log
echo "Storage Container Name: " ${CONTAINER_NAME} | adddate >> jbosseap.install.log
echo "RHSM_USER: " ${RHSM_USER} | adddate >> jbosseap.install.log
echo "JAVA VERSION : " ${JAVA_VERSION} | adddate >> jbosseap.install.log

echo "Configure firewall for ports 8080, 9990, 45700, 7600..." | adddate >> jbosseap.install.log

echo "firewall-cmd --zone=public --add-port=8080/tcp --permanent" | adddate >> jbosseap.install.log
sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent | adddate >> jbosseap.install.log 2>&1
echo "firewall-cmd --zone=public --add-port=9990/tcp --permanent" | adddate >> jbosseap.install.log
sudo firewall-cmd --zone=public --add-port=9990/tcp --permanent | adddate >> jbosseap.install.log 2>&1
echo "firewall-cmd --zone=public --add-port=45700/tcp --permanent" | adddate >> jbosseap.install.log
sudo firewall-cmd --zone=public --add-port=45700/tcp --permanent | adddate >> jbosseap.install.log 2>&1
echo "firewall-cmd --zone=public --add-port=7600/tcp --permanent" | adddate >> jbosseap.install.log
sudo firewall-cmd --zone=public --add-port=7600/tcp --permanent | adddate >> jbosseap.install.log 2>&1
echo "firewall-cmd --zone=public --add-port=22/tcp --permanent" | adddate >> jbosseap.install.log
sudo firewall-cmd --zone=public --add-port=22/tcp --permanent | adddate >> jbosseap.install.log 2>&1
echo "firewall-cmd --reload" | adddate >> jbosseap.install.log
sudo firewall-cmd --reload | adddate >> jbosseap.install.log 2>&1
echo "iptables-save" | adddate >> jbosseap.install.log
sudo iptables-save | adddate >> jbosseap.install.log 2>&1

echo "Initial JBoss EAP setup" | adddate >> jbosseap.install.log
echo "subscription-manager register --username RHSM_USER --password RHSM_PASSWORD" | adddate >> jbosseap.install.log
subscription-manager register --username $RHSM_USER --password $RHSM_PASSWORD >> jbosseap.install.log 2>&1
flag=$?; if [ $flag != 0 ] ; then echo  "ERROR! Red Hat Manager Registration Failed" | adddate >> jbosseap.install.log; exit $flag;  fi
echo "subscription-manager attach --pool=EAP_POOL" | adddate >> jbosseap.install.log
subscription-manager attach --pool=${RHSM_POOL} >> jbosseap.install.log 2>&1
flag=$?; if [ $flag != 0 ] ; then echo  "ERROR! Pool Attach for JBoss EAP Failed" | adddate >> jbosseap.install.log; exit $flag;  fi
if [ $RHEL_OS_LICENSE_TYPE == "BYOS" ]
then
    echo "Attaching Pool ID for RHEL OS" | adddate >> jbosseap.install.log
    echo "subscription-manager attach --pool=RHEL_POOL" | adddate >> jbosseap.install.log
    subscription-manager attach --pool=${19} >> jbosseap.install.log 2>&1
fi
echo "Subscribing the system to get access to JBoss EAP repos" | adddate >> jbosseap.install.log

# Install JAVA
if [ $JAVA_VERSION == "JAVA_8" ]
then
    echo "Installing JAVA 8" | adddate >> jbosseap.install.log
    echo "sudo yum install java-1.8.0-openjdk -y" | adddate >> jbosseap.install.log
    sudo yum install java-1.8.0-openjdk -y | adddate >> jbosseap.install.log
    echo "Successfully installed JAVA 8" | adddate >> jbosseap.install.log
    echo "java -version" | adddate >> jbosseap.install.log
    java -version >> jbosseap.install.log 2>&1
elif [ $JAVA_VERSION == "JAVA_11" ]
then
    echo "Installing JAVA 11" | adddate >> jbosseap.install.log
    echo "sudo yum install java-11-openjdk -y" | adddate >> jbosseap.install.log
    sudo yum install java-11-openjdk -y >> jbosseap.install.log
    echo "Successfully installed JAVA 11" | adddate >> jbosseap.install.log
    echo "java -version" | adddate >> jbosseap.install.log
    java -version >> jbosseap.install.log 2>&1
elif [ $JAVA_VERSION == "JAVA_17" ]
then
    echo "Installing JAVA 17" | adddate >> jbosseap.install.log
    echo "sudo yum install java-17-openjdk -y" | adddate >> jbosseap.install.log
    sudo yum install java-17-openjdk -y >> jbosseap.install.log
    echo "Successfully installed JAVA 17" | adddate >> jbosseap.install.log
    echo "java -version" | adddate >> jbosseap.install.log
    java -version >> jbosseap.install.log 2>&1
fi

echo "Install wget, git, unzip, vim" | adddate >> jbosseap.install.log
echo "sudo yum install wget unzip vim git -y" | adddate >> jbosseap.install.log
sudo yum install wget unzip vim git -y | adddate >> jbosseap.install.log 2>&1
echo "Subscribing the system to get access to JBoss EAP 7.4 repos" | adddate >> jbosseap.install.log

# Install JBoss EAP 7.4
echo "subscription-manager repos --enable=jb-eap-7.4-for-rhel-8-x86_64-rpms" | adddate >> jbosseap.install.log
subscription-manager repos --enable=jb-eap-7.4-for-rhel-8-x86_64-rpms >> jbosseap.install.log 2>&1
flag=$?; if [ $flag != 0 ] ; then echo  "ERROR! Enabling repos for JBoss EAP Failed" | adddate >> jbosseap.install.log; exit $flag;  fi

echo "Installing JBoss EAP 7.4 repos" | adddate >> jbosseap.install.log
echo "yum groupinstall -y jboss-eap7" | adddate >> jbosseap.install.log
yum groupinstall -y jboss-eap7 >> jbosseap.install.log 2>&1
flag=$?; if [ $flag != 0 ] ; then echo  "ERROR! JBoss EAP installation Failed" | adddate >> jbosseap.install.log; exit $flag;  fi

echo "sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config" | adddate >> jbosseap.install.log
sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config | adddate >> jbosseap.install.log 2>&1
echo "echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config" | adddate >> jbosseap.install.log
echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config | adddate >> jbosseap.install.log 2>&1

echo "systemctl restart sshd" | adddate >> jbosseap.install.log
systemctl restart sshd | adddate >> jbosseap.install.log 2>&1

echo "Copy the standalone-azure-ha.xml from EAP_HOME/doc/wildfly/examples/configs folder to EAP_HOME/wildfly/standalone/configuration folder" | adddate >> jbosseap.install.log
echo "cp $EAP_HOME/doc/wildfly/examples/configs/standalone-azure-ha.xml $EAP_HOME/wildfly/standalone/configuration/" | adddate >> jbosseap.install.log
cp $EAP_HOME/doc/wildfly/examples/configs/standalone-azure-ha.xml $EAP_HOME/wildfly/standalone/configuration/ | adddate >> jbosseap.install.log 2>&1

echo "Updating standalone-azure-ha.xml" | adddate >> jbosseap.install.log
echo -e "\t stack UDP to TCP"           | adddate >> jbosseap.install.log
echo -e "\t management:inet-address"    | adddate >> jbosseap.install.log
echo -e "\t public:inet-address"        | adddate >> jbosseap.install.log
echo -e "\t set transaction id"         | adddate >> jbosseap.install.log

## OpenJDK 17 specific logic
if [ $JAVA_VERSION == "JAVA_17" ]
then
    sudo -u jboss $EAP_HOME/bin/jboss-cli.sh --file=$EAP_HOME/docs/examples/enable-elytron-se17.cli -Dconfig=standalone-full-ha.xml
fi

sudo -u jboss $EAP_HOME/wildfly/bin/jboss-cli.sh --echo-command \
'embed-server --std-out=echo  --server-config=standalone-azure-ha.xml',\
'/subsystem=transactions:write-attribute(name=node-identifier,value="'${NODE_ID}'")',\
'/subsystem=jgroups/channel=ee:write-attribute(name="stack", value="tcp")' | adddate >> jbosseap.install.log

# Configure the JBoss server and setup eap service
echo "Setting configurations in $EAP_RPM_CONF_STANDALONE"
echo -e "\t-> WILDFLY_SERVER_CONFIG=standalone-azure-ha.xml" | 
echo 'WILDFLY_SERVER_CONFIG=standalone-azure-ha.xml' >> $EAP_RPM_CONF_STANDALONE | 

echo "Setting configurations in $EAP_LAUNCH_CONFIG"
echo -e '\t-> JAVA_OPTS=$JAVA_OPTS -Djboss.bind.address=0.0.0.0' | adddate >> jbosseap.install.log
echo -e '\t-> JAVA_OPTS=$JAVA_OPTS -Djboss.bind.address.management=0.0.0.0' | adddate >> jbosseap.install.log
echo -e '\t-> JAVA_OPTS="$JAVA_OPTS -Djboss.bind.address.private=$(hostname -I)"' | adddate >> jbosseap.install.log

echo -e 'JAVA_OPTS="$JAVA_OPTS -Djboss.bind.address=0.0.0.0"' >> $EAP_LAUNCH_CONFIG | adddate >> jbosseap.install.log
echo -e 'JAVA_OPTS="$JAVA_OPTS -Djboss.bind.address.management=0.0.0.0"' >> $EAP_LAUNCH_CONFIG | adddate >> jbosseap.install.log
echo -e 'JAVA_OPTS="$JAVA_OPTS -Djboss.bind.address.private=$(hostname -I)"' >> $EAP_LAUNCH_CONFIG | adddate >> jbosseap.install.log
echo -e 'JAVA_OPTS="$JAVA_OPTS -Djava.net.preferIPv4Stack=true"' >> $EAP_LAUNCH_CONFIG | adddate >> jbosseap.install.logadddate >> jbosseap.install.log

echo -e "JAVA_OPTS=\"\$JAVA_OPTS -Djboss.jgroups.azure_ping.storage_account_name=$STORAGE_ACCOUNT_NAME\"" >> $EAP_LAUNCH_CONFIG | adddate >> jbosseap.install.log
echo -e "JAVA_OPTS=\"\$JAVA_OPTS -Djboss.jgroups.azure_ping.storage_access_key=$STORAGE_ACCESS_KEY\"" >> $EAP_LAUNCH_CONFIG | adddate >> jbosseap.install.log
echo -e "JAVA_OPTS=\"\$JAVA_OPTS -Djboss.jgroups.azure_ping.container=$CONTAINER_NAME\"" >> $EAP_LAUNCH_CONFIG | adddate >> jbosseap.install.log

echo "Start JBoss-EAP service" | adddate >> jbosseap.install.log
echo "systemctl enable eap7-standalone.service" | adddate >> jbosseap.install.log
systemctl enable eap7-standalone.service | adddate >> jbosseap.install.log 2>&1

# Editing eap7-standalone.services
echo "Editing eap7-standalone.services" | adddate >> jbosseap.install.log 2>&1
echo "Adding - After=syslog.target network.target NetworkManager-wait-online.service" | adddate >> jbosseap.install.log
sed -i 's/After=syslog.target network.target/After=syslog.target network.target NetworkManager-wait-online.service/' /usr/lib/systemd/system/eap7-standalone.service | adddate >> jbosseap.install.log
echo "Adding - Wants=NetworkManager-wait-online.service \nBefore=httpd.service" | adddate >> jbosseap.install.log
sed -i 's/Before=httpd.service/Wants=NetworkManager-wait-online.service \nBefore=httpd.service/' /usr/lib/systemd/system/eap7-standalone.service | adddate >> jbosseap.install.log
echo "systemctl daemon-reload" | adddate >> jbosseap.install.log
systemctl daemon-reload | adddate >> jbosseap.install.log

echo "systemctl restart eap7-standalone.service"| adddate >> jbosseap.install.log 2>&1
systemctl restart eap7-standalone.service       | adddate >> jbosseap.install.log 2>&1
echo "systemctl status eap7-standalone.service" | adddate >> jbosseap.install.log 2>&1
systemctl status eap7-standalone.service        | adddate >> jbosseap.install.log 2>&1

yum install cronie cronie-anacron | adddate >> jbosseap.install.log 2>&1
service crond start | adddate >> jbosseap.install.log 2>&1
chkconfig crond on | adddate >> jbosseap.install.log 2>&1
echo "@reboot sleep 90 && /bin/jbossservice.sh" >>  /var/spool/cron/root
chmod 600 /var/spool/cron/root

echo "Deploy an application" | adddate >> jbosseap.install.log
echo "wget $fileUrl" | adddate >> jbosseap.install.log
wget $fileUrl >> jbosseap.install.log 2>&1
flag=$?; if [ $flag != 0 ] ; then echo  "ERROR! Sample Application Download Failed" | adddate >> jbosseap.install.log; exit $flag; fi
echo "cp ./eap-session-replication.war $EAP_HOME/wildfly/standalone/deployments/" | adddate >> jbosseap.install.log
cp ./eap-session-replication.war $EAP_HOME/wildfly/standalone/deployments/ | adddate >> jbosseap.install.log 2>&1
echo "touch $EAP_HOME/wildfly/standalone/deployments/eap-session-replication.war.dodeploy" | adddate >> jbosseap.install.log
touch $EAP_HOME/wildfly/standalone/deployments/eap-session-replication.war.dodeploy | adddate >> jbosseap.install.log 2>&1

echo "Configuring JBoss EAP management user..." | adddate >> jbosseap.install.log
echo "$EAP_HOME/wildfly/bin/add-user.sh -u JBOSS_EAP_USER -p JBOSS_EAP_PASSWORD -g 'guest,mgmtgroup'" | adddate >> jbosseap.install.log
$EAP_HOME/wildfly/bin/add-user.sh  -u $JBOSS_EAP_USER -p $JBOSS_EAP_PASSWORD -g 'guest,mgmtgroup' >> jbosseap.install.log 2>&1
flag=$?; if [ $flag != 0 ] ; then echo  "ERROR! JBoss EAP management user configuration Failed" | adddate >> jbosseap.install.log; exit $flag;  fi

# Seeing a race condition timing error so sleep to delay
sleep 20

echo "Red Hat JBoss EAP Cluster Intallation End " | adddate >> jbosseap.install.log
/bin/date +%H:%M:%S  >> jbosseap.install.log
