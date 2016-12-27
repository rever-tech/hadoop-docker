#!/bin/bash

: ${HADOOP_PREFIX:=/usr/local/hadoop}

$HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

rm /tmp/*.pid

# installing libraries if any - (resource urls added comma separated to the ACP system variable)
cd $HADOOP_PREFIX/share/hadoop/common ; for cp in ${ACP//,/ }; do  echo == $cp; curl -LO $cp ; done; cd -

# altering the core-site configuration
sed s/HOSTNAME/$HOSTNAME/ /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml

# altering TMP_DIR
TMP_DIR=${TMP_DIR:-/opt/hadoop}
if [[ ! -d $TMP_DIR/data ]]; then
	mkdir -p $TMP_DIR/data
fi
sed -i "s;TMP_DIR;$TMP_DIR;g" /usr/local/hadoop/etc/hadoop/core-site.xml

service sshd start

case $1 in
	all)
	# Formating name node if data dir is fresh
	if [[ ! -f $TMP_DIR/formated ]]; then
		$HADOOP_PREFIX/bin/hdfs namenode -format
		touch $TMP_DIR/formated
	fi
	$HADOOP_PREFIX/sbin/start-dfs.sh
	$HADOOP_PREFIX/sbin/start-yarn.sh
	$HADOOP_PREFIX/sbin/mr-jobhistory-daemon.sh start historyserver
	shift
	;;
	master)
	# Formating name node if data dir is fresh
	if [[ ! -f $TMP_DIR/formated ]]; then
		$HADOOP_PREFIX/bin/hdfs namenode -format
		touch $TMP_DIR/formated
	fi
	$HADOOP_PREFIX/sbin/hadoop-daemon.sh --script hdfs start namenode
	$HADOOP_YARN_HOME/sbin/yarn-daemon.sh start resourcemanager
	$HADOOP_YARN_HOME/sbin/yarn-daemon.sh start proxyserver
	$HADOOP_PREFIX/sbin/mr-jobhistory-daemon.sh start historyserver
	shift
	;;
	slave)
	$HADOOP_PREFIX/sbin/hadoop-daemons.sh --script hdfs start datanode
	$HADOOP_YARN_HOME/sbin/yarn-daemons.sh start nodemanager
	shift
	;;
	
	*)
	# Unknown option
	exec $@
	;;
esac

if [[ $1 == "-d" ]]; then
  while true; do sleep 1000; done
fi

if [[ $1 == "-bash" ]]; then
  /bin/bash
fi
