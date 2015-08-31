#!/usr/bin/env bash

# Translates relevant docker environment values
# to configure.rb parameters
# ----------------------------------------------

# Allow parameters to configure.rb to come from CONFIGURE_PARAMS as opposed to stdin
# This is to support parameterizing via Compose in particular. The two lines below are equivalent in effect:
# docker run -e "CONFIGURE_PARAMS=cassandra --dc daas-1 --calculate-tokens 1:1" -ti --name c1 --rm andlaz/hadoop-cassandra
# docker run -ti --name c1 --rm andlaz/hadoop-cassandra cassandra --dc daas-1 --calculate-tokens 1:1
P=${CONFIGURE_PARAMS:-$(echo $*)}
set -- $P

add_namenode_options () {
	
	local opts=""
	
	if [ $HOSTNAME ] && [ ! "$*" == *"--fs-host"* ]; then opts="$opts --fs-host $HOSTNAME"; fi
	
	echo $opts
}

add_secondary_namenode_options () {

	local opts=""
	
	if [ $NAMENODE_NAME ] && [ ! "$*" == *"--fs-host"* ]; then opts="$opts --fs-host namenode"; fi
	if [ $NAMENODE_PORT_8020_TCP_PORT ] && [ ! "$*" == *"--fs-port"* ]; then opts="$opts --fs-port $NAMENODE_PORT_8020_TCP_PORT"; fi
	if [ $NAMENODE_PORT_50070_TCP_PORT ] && [ ! "$*" == *"--name-web-ui-port"* ]; then opts="$opts --name-web-ui-port $NAMENODE_PORT_50070_TCP_PORT"; fi

	echo $opts
}

case $1 in
	namenode) ruby /root/configure.rb $* `add_namenode_options` && supervisord -c /etc/supervisord.conf ;;
	namenodesecondary) ruby /root/configure.rb $* `add_secondary_namenode_options` && supervisord -c /etc/supervisord.conf ;;
	help) cat << EOM
The image's entry point script will populate the following -parameters from Docker environment variables:
EOM
	echo -e "\nnamenode\t\t\t:" `add_namenode_options` "\n"
	echo -e "namenodesecondary\t\t:" `add_secondary_namenode_options` "\n"
	ruby /root/configure.rb $* ;;
	*) ruby /root/configure.rb $* ;;
esac

