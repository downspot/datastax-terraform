#!/bin/sh

###################################################################################################################################################

# Nagios

rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y nagios-plugins-all nrpe


# CloudWatchMonitoringScripts

yum install -y perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https perl-Digest-SHA.x86_64 zip unzip wget

mkdir /opt

wget https://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.2.zip -P /opt

cd /opt
unzip CloudWatchMonitoringScripts-1.2.2.zip
rm CloudWatchMonitoringScripts-1.2.2.zip

echo '*/5 * * * * root perl /opt/aws-scripts-mon/mon-put-instance-data.pl --mem-util --disk-space-util --disk-path=/ --disk-path=/mnt/data --disk-path=/mnt/data00 --disk-path=/mnt/data01 >> /var/log/cwpump.log 2>&1' > /etc/cron.d/cwpump


# script for setting hostname

cat <<'EOF' >> /root/set_hostname.sh 
#!/bin/sh 

sudo dig +short -x `GET http://169.254.169.254/latest/meta-data/local-ipv4` @dns0000.ash1.datasciences.tmcs | sed s'/.$//' | sudo xargs hostnamectl set-hostname
sudo sed -i '/hostname/d' /etc/cloud/cloud.cfg
EOF

###################################################################################################################################################


### DSE SETUP ###

# attach EBS filesystem

sleep 20

mkdir -p /mnt/{data,data00,data01}

DEVICE=/dev/$(lsblk -n | awk '$NF != "/" {print $1}' | grep nvme1n1)
FS_TYPE=$(file -s $DEVICE | awk '{print $2}')
MOUNT_POINT=/mnt/data

# If no FS, then this output contains "data"
if [ "$FS_TYPE" = "data" ]
then
    echo "Creating file system on $DEVICE"
    mkfs -t xfs $DEVICE
    mkdir $MOUNT_POINT
    echo "" >> /etc/fstab
    echo "$DEVICE		/mnt/data		xfs	rw,noatime 1 1" >> /etc/fstab 
    mount -a 
fi


# SSD

if [ -b /dev/nvme2n1 ] && [ -b /dev/nvme3n1 ]; then 

        parted -s -a optimal /dev/nvme2n1 mklabel gpt mkpart primary 'xfs' '0%' '100%'
        parted -s -a optimal /dev/nvme3n1 mklabel gpt mkpart primary 'xfs' '0%' '100%'
        
	pvcreate -f /dev/nvme2n1
        pvcreate -f /dev/nvme3n1 
        
	vgcreate DatastaxVG00 /dev/nvme2n1
        vgcreate DatastaxVG01 /dev/nvme3n1
        
	lvcreate -n DatastaxLV00 -l 100%FREE DatastaxVG00
        lvcreate -n DatastaxLV01 -l 100%FREE DatastaxVG01
        
	mkfs.xfs /dev/DatastaxVG00/DatastaxLV00
        mkfs.xfs /dev/DatastaxVG01/DatastaxLV01

	echo "" >> /etc/fstab
        echo "/dev/DatastaxVG00/DatastaxLV00                /mnt/data00               xfs     rw,noatime 1 1" >> /etc/fstab
        echo "/dev/DatastaxVG01/DatastaxLV01                /mnt/data01               xfs     rw,noatime 1 1" >> /etc/fstab

	mount -a

	cat << 'EOF' >> /etc/rc.local

	# DSE settings 

	echo noop > /sys/block/nvme2n1/queue/scheduler
	echo 0 > /sys/class/block/nvme2n1/queue/rotational
	echo 8 > /sys/class/block/nvme2n1/queue/read_ahead_kb
        echo noop > /sys/block/nvme3n1/queue/scheduler
        echo 0 > /sys/class/block/nvme3n1/queue/rotational
        echo 8 > /sys/class/block/nvme3n1/queue/read_ahead_kb
	touch /var/lock/subsys/local
EOF

chmod +x /etc/rc.d/rc.local

fi 


# fix yum issue and install required packages 

rpm -ivh http://mirror.ufs.ac.za/centos/7/os/x86_64/Packages/centos-release-7-6.1810.2.el7.centos.x86_64.rpm --force
mv /etc/yum.repos.d/CentOS-* /tmp/
yum -y install java-1.8.0-openjdk


# user and directories

groupadd -r cassandra
useradd -r -g cassandra cassandra
mkdir -p /mnt/{data,data00,data01}/cassandra/{data,commitlog,saved_caches,hints,cdc_raw}
mkdir -p /mnt/data/datastax-agent/{commitlogs,backups}
chown -R cassandra:cassandra /mnt/{data,data00,data01}/cassandra
chown -R cassandra:cassandra /mnt/data/datastax-agent


# yum repo

cat << 'EOF' >> /etc/yum.repos.d/datastax.repo
[opscenter] 
name = DataStax Repository
baseurl = https://joel.flickinger%40ticketmaster.com:datastax-key@rpm.datastax.com/enterprise
enabled = 1
gpgcheck = 0
EOF


# kernel settings

cat << 'EOF' >> /etc/sysctl.conf

# DSE settings 

net.ipv4.tcp_keepalive_time=60
net.ipv4.tcp_keepalive_probes=3
net.ipv4.tcp_keepalive_intvl=10
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.core.rmem_default=16777216
net.core.wmem_default=16777216
net.core.optmem_max=40960
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
EOF
