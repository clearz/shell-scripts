#!/bin/sh

CONSOLE_OUT=0 #Set to 1 to log to stdout or use -o switch in terminal

DIR="/jffs/ddns"
LOG="$DIR/ddns.log"  #Log file
DAT_FILE="$DIR/ip"

log () {
   echo $1 >> $LOG
   if [ $CONSOLE_OUT = 1 ]
   then
		echo $1
   fi
}

update () {
	IP1=$(curl -sk --retry 3 --retry-delay 3000 $UPDATE_URL?$UPDATE_HASH1 | grep -oE $IP_REGEX)
	IP2=$(curl -sk --retry 3 --retry-delay 3000 $UPDATE_URL?$UPDATE_HASH2 | grep -oE $IP_REGEX)
	if [ $IP1 == $IP2 ]
	then
		IP=$IP1
	else
		log "ERROR Expected IP1 & IP2 to be the same, got IP1=$IP1, IP2=$IP2"
		if [ -z $IP1 ] 
		then
			IP=$IP2
		else
			IP=$IP1
		fi
	fi
	log "Updated IP to $IP"
}

find_ip () {
	CNT=0;
	IP=$(curl -sk --retry 3 --retry-delay 3000 $URL | grep -oE $IP_REGEX)

	while [ -z "$IP" ] # If no IP found yet, keep trying!
	do
		log "ERROR: Connecting to $URL" 
		log "Trying another server in 30 seconds"
		CNT=$((CNT + 1))
		POS=$(((POS + 1) % LEN))
		if [ $((LEN - CNT)) -lt 1 ]; then
			log "Unable to connect to any servers, exiting." 
			break
		fi
		
		eval URL=\${url_list$POS}
		sleep 30
		
		log "Retrieving IP from $URL" 
		IP=$(curl -sk --retry 3 --retry-delay 3000 $URL | grep -oE $IP_REGEX)
	done
}

for var in "$@"
do
    if [ $var == "-o" ]; then
		CONSOLE_OUT=1
	elif [ $var == "-f" ]; then
		FORCE_UPDATE=1
	fi
done

url_list0="http://checkip.amazonaws.com" 
url_list1="http://ip.dnsexit.com" 
url_list2="http://ifconfig.me/ip" 
url_list3="http://ipecho.net/plain" 
url_list4="http://myexternalip.com/raw" 
url_list5="http://icanhazip.com/" 
url_list6="http://bot.whatismyipaddress.com/" 
url_list7="http://ipinfo.io/ip" 
url_list8="http://diagnostic.opendns.com/myip" 
url_list9="http://api.ipify.org" 
url_list10="https://tnx.nl/ip" 
url_list11="http://ident.me"
LEN=12

UPDATE_HASH1="Tm14U1Z4U2poMVl4RVJYNGJUamZXZDJGOjE0Njc1ODU4"
UPDATE_HASH2="Tm14U1Z4U2poMVl4RVJYNGJUamZXZDJGOjE3NjY3NjAx"
UPDATE_URL="http://freedns.afraid.org/dynamic/update.php"
IP_REGEX='[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}'

date -R >> $LOG

if [ $FORCE_UPDATE ]; then
	log "Forcing update"
	update
else
	if [ -e $DAT_FILE ]; then
		read -r CUR_IP POS < $DAT_FILE
		POS=$(((POS + 1) % LEN))
	else
		RANDOM=$(</dev/urandom tr -dc 0-9 | dd bs=5 count=1 2> /dev/null | sed -e 's/^0\+//')
		POS=$((  RANDOM % LEN  ))
		CUR_IP=""
	fi
  
	log "Current IP = $CUR_IP, Position = $POS" 
	eval URL=\${url_list$POS}
	log "Retrieving IP from $URL" 
	find_ip

	if [ $IP == $CUR_IP ]; then
		log "No change in current IP: $IP" 
	else
		log "Mismatched IPs: $IP" 
		update
	fi
fi

log "" # log a blank line for clarity
echo "$IP $POS" > $DAT_FILE #save info to data file


# use 'array' of urls instead of a static list
#url_string="http://checkip.amazonaws.com http://ip.dnsexit.com http://ifconfig.me/ip http://ipecho.net/plain http://myexternalip.com/raw http://icanhazip.com/ http://bot.whatismyipaddress.com/ http://ipinfo.io/ip http://diagnostic.opendns.com/myip http://api.ipify.org https://tnx.nl/ip http://ident.me"

# dynamically generate list variables from 'array'
#for url in $url_string; do 
#	eval url_list$LEN=$url;
#	LEN=$((LEN+1))
#done

