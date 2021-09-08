#!/bin/bash
set -e

if [ "${1:0:1}" == '-' ]; then
	CMDARG="$@"
fi

if [ $MONITOR_CONFIG_CHANGE ]; then
	#Megvaltozott a conf
	echo 'Env MONITOR_CONFIG_CHANGE=true'
	CONFIG=/etc/proxysql.cnf
	oldcksum=$(cksum ${CONFIG})

	proxysql --reload -f $CMDARG &

	echo "Monitorozzuk a $CONFIG fajlt valtozasokra varva"
	inotifywait -e modify,move,create,delete -m --timefmt '%d/%m/%y %H:%M' --format '%T' ${CONFIG} | \
	while read date time; do
		newcksum=$(cksum ${CONFIG})
		if [ "$newcksum" != "$oldcksum" ]; then
			echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			echo "IDO ${time} DATUM ${date}, ${CONFIG} valtozas tortent."
			echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			oldcksum=$newcksum
			echo "Reloadoljuk a ProxySQL-t"
		        killall -15 proxysql
			proxysql --initial --reload -f $CMDARG
		fi
	done
fi

exec proxysql -f $CMDARG
