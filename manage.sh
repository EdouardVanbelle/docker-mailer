#!/bin/bash

if [ ! -e /etc/my-mailer ]
then
	echo "This script must be runned under a 'my-mailer' container" >&2
	exit 1
fi

if [ \( "$1" == "_run" \) -a \( ${#@} -gt 1 \) ]
then
	# parameters used from docker
	shift
fi



SERVICES="cron dovecot spamassassin opendkim postfix rsyslog"


STD_CMD="domain-list|user-list|remap|status|shell"
DOMAIN_CMD="domain-add|domain-del|domain-check|dkim-get-selector"
USER_CMD="user-add|user-del|user-password"

ESC=$(echo -n -e "\033" )

# -------------------------------------------------------


BLACK="$ESC[30m"
BLUE="$ESC[34m"
GREEN="$ESC[32m"
CYAN="$ESC[36m"
RED="$ESC[31m"
PURPLE="$ESC[35m"
BROWN="$ESC[33m"
GRAY="$ESC[37m"

BOLD="$ESC[1m"
RESET="$ESC[0m"



# -------------------------------------------------------

is_valid_domain()
{
	DOMAIN=$1
	[[ $DOMAIN =~ ^([a-z0-9\-]+\.)+[a-z0-9\-]+$ ]] 
	return $?
}

is_valid_email()
{
	EMAIL=$1
	[[ $EMAIL =~ ^[a-z0-9\-]+@([a-z0-9\-]+\.)+[a-z0-9\-]+$ ]]
	return $?
}

gen-password()
{
	tr -dc '12345!@#$%qwertQWERTasdfgASDFGzxcvbZXCVB' </dev/urandom | head -c${1:-12}; echo ""
}

sha512()
{
	# FIXME: should use random salt, cf: http://wiki2.dovecot.org/Authentication/PasswordSchemes
	echo -n "$1" | sha512sum | awk '{print $1}'
}


usage() 
{
	echo $0 "<$STD_CMD|$DOMAIN_CMD|$USER_CMD>"
	exit 1
}

# -------------------------------------------------------

domain-list()
{
	cat /data/config/virtual-mailbox-domains
}

dkim-add()
{
	DOMAIN=$1
	SELECTOR=default

	# dkim
	mkdir /data/config/opendkim/keys/$DOMAIN

	opendkim-genkey --selector $SELECTOR -domain $DOMAIN --directory /data/config/opendkim/keys/$DOMAIN
	chown opendkim:opendkim /data/config/opendkim/keys/$DOMAIN/$SELECTOR.private
	chmod 600 /data/config/opendkim/keys/$DOMAIN/$SELECTOR.private
	chmod 644 /data/config/opendkim/keys/$DOMAIN/$SELECTOR.txt

	echo "$SELECTOR._domainkey.$DOMAIN $DOMAIN:mail:/data/config/opendkim/keys/$DOMAIN/$SELECTOR.private" >> /data/config/opendkim/KeyTable
	echo "*@$DOMAIN $SELECTOR._domainkey.$DOMAIN" >>/data/config/opendkim/SigningTable

	# don't know if important
	service opendkim reload 2>/dev/null >/dev/null

	echo "don't forget to add DKIM key in your zone: "
	cat /data/config/opendkim/keys/$DOMAIN/$SELECTOR.txt

	echo _adsp._domainkey.$DOMAIN TXT "'"dkim=all"'"

}

dkim-get-selector()
{
	DOMAIN=$1

	awk '{ if( $1 == "'"*@$DOMAIN"'") { print $2; } }' </data/config/opendkim/SigningTable | cut -d . -f 1
}


domain-add() 
{
	DOMAIN=$1


	if grep -q -- "$DOMAIN$" /data/config/virtual-mailbox-domains
	then
		echo domain already exists >&2
		exit 1
	fi

	echo $DOMAIN >> /data/config/virtual-mailbox-domains

	dkim-add $DOMAIN default

	echo "$DOMAIN added (use $0 domain-check $DOMAIN to test)"
}

domain-del()
{
	DOMAIN=$1

	if ! grep -q -- "^$DOMAIN$" /data/config/virtual-mailbox-domains
	then
		echo domain not in list >&2
	fi

	grep -v -- "^$DOMAIN$" /data/config/virtual-mailbox-domains > /data/config/virtual-mailbox-domains.tmp
	mv /data/config/virtual-mailbox-domains.tmp /data/config/virtual-mailbox-domains

	echo $DOMAIN removed
}

domain-check() 
{
	DOMAIN=$1

	SOA=$(dig +short SOA $DOMAIN) 
	
	if [ -z "$SOA" ]
	then
		echo dns zone not found, please create the domain name $DOMAIN of remove it from db if not possible
		return 1
	fi

	echo "check MX (should be something like: <num> <docker-host>)"
	echo -n ${CYAN}
	TEST=$(dig +short MX $DOMAIN)
	echo $TEST
	echo -n ${RESET}
	HOST=$(echo $TEST | head -n 1 | awk '{print $2}')
	# 1 mx.enor.me.
	echo 'quit'  | nc -q 1 $HOST 25
	echo

	echo "check submission SRV helper (should be something like: <num> <num> 587 <docker-host>)"
	# 0 0 587 c.enor.me.
	echo -n ${CYAN}
	TEST=$(dig +short SRV _submission._tcp.$DOMAIN)
	echo $TEST
	echo -n ${RESET}
	HOST=$(echo $TEST | head -n 1 | awk '{print $4}')
	PORT=$(echo $TEST | head -n 1 | awk '{print $3}')
	if [ ! $PORT -eq 587 ] 
	then
		echo "${RED}ko${RESET} - wrong port $PORT, expected 587"
	else
		echo "${GREEN}ok${RESET} - correct submission port"
	fi
	echo 'quit'  | nc -q 1 $HOST 587
	echo

	echo "check imap SRV helper (should be something like: <num> <num> 143 <docker-host>)"
	echo -n ${CYAN}
	TEST=$(dig +short SRV _imap._tcp.$DOMAIN)
	# 0 0 143 c.enor.me.
	echo $TEST
	echo -n ${RESET}
	HOST=$(echo $TEST | head -n 1 | awk '{print $4}')
	PORT=$(echo $TEST | head -n 1 | awk '{print $3}')
	if [ ! $PORT -eq 143 ] 
	then
		echo "${RED}ko${RESET} - wrong port $PORT, expected 143"
	else
		echo "${GREEN}ok${RESET} - correct imap port"
	fi
	echo 'a001 logout'  | nc -q 1 $HOST $PORT
	echo
	
	echo "check sieve (port 4190)"
	echo -n ${CYAN}
	SIEVE=$(echo 'logout'  | nc -q 1 $HOST 4190 )
	echo $SIEVE
	echo -n ${RESET}
	echo

	echo check SPF1 '(should be something like: "(v=spf1 mx ip4:<docker-host-ip> -all)"'
	# "v=spf1 mx ip4:178.33.231.79 -all"	
	echo -n ${CYAN}
	SPF=$(dig +short TXT $DOMAIN | grep '^"v=spf1')
	echo $SPF
	echo -n ${RESET}
	if [[ $SPF =~ -all\"$ ]]
	then
		echo "${GREEN}ok${RESET} - SPF is strict (ending with -all)"
	else
		echo "${RED}ko${RESET} - SPF is not found or not strict (must end with -all)"
	fi
	echo

	SELECTOR=$(dkim-get-selector $DOMAIN)

	echo check DKIM entry	
	echo -n ${CYAN}
	DKIM=$(dig +short TXT  $SELECTOR._domainkey.$DOMAIN) | head -c 40
	echo $DKIM
	echo -n ${RESET}
	if opendkim-testkey -d $DOMAIN -s $SELECTOR 
	then
		echo ${GREEN}ok${RESET} - dkim key for selector $SELECTOR found and correct 
	else
		echo ${RED}ko${RESET} - missing dkim key, please add:
		cat /data/config/opendkim/keys/$DOMAIN/$SELECTOR.txt
	fi
	echo

	echo check ADSP '(should be "dkim=all")'
	# "v=spf1 mx ip4:178.33.231.79 -all"	
	echo -n ${CYAN}
	ADSP=$(dig +short TXT  _adsp._domainkey.$DOMAIN) 
	echo $ADSP
	echo -n ${RESET}
	if [ "$ADSP" == '"dkim=all"' ]
	then
		echo "${GREEN}ok${RESET} - ADSP is strict"
	else
		echo "${RED}ko${RESET} - ADSP is not correct, should have: _adsp._domainkey.$DOMAIN TXT ""'"dkim=all"'"
	fi
	echo


}

# -------------------------------------------------------

user-list()
{
	awk '{print $1}' < /data/config/virtual-mailbox-maps
}

user-add()
{
	EMAIL=$1
	PASSWORD=$2

	USER=${EMAIL%@*}
	DOMAIN=${EMAIL#*@}

	AUTOPASS=0

	if ! grep -q "^$DOMAIN$" /data/config/virtual-mailbox-domains
	then
		echo $DOMAIN unknwon, please use before: $0 domain-add $DOMAIN >&2
		exit 1
	fi

	if postmap -q $EMAIL /data/config/virtual-mailbox-maps >/dev/null
	then
		echo $EMAIL already exists
		exit 1
	fi

	if [ -z "$PASSWORD" ]
	then
		# random password
		PASSWORD=$(gen-password)
		AUTOPASS=1
	fi

	# add credential
	# TODO: change method to non PLAIN 
	# TODO: should avoid linear text file
	SHA512_PASSWORD=$( sha512 $PASSWORD)
	echo "$EMAIL:{SHA512.hex}$SHA512_PASSWORD" >> /data/config/passwd

	echo $EMAIL $DOMAIN/$USER/ >>/data/config/virtual-mailbox-maps
	postmap /data/config/virtual-mailbox-maps

	echo $EMAIL $EMAIL >>/data/config/virtual-sender-login-maps
	postmap /data/config/virtual-sender-login-maps

	if [ $AUTOPASS == 1 ]
	then
		echo $EMAIL added with password $PASSWORD
	else
		echo $EMAIL added
	fi
}

user-del()
{
	EMAIL=$1

	USER=${EMAIL%@*}
	DOMAIN=${EMAIL#*@}

	AUTOPASS=0

	if ! postmap -q $EMAIL /data/config/virtual-mailbox-maps >/dev/null
	then
		echo $EMAIL not found >&2
		exit 1
	fi

	grep -v "^$EMAIL:" /data/config/passwd > /data/config/passwd.tmp
	mv /data/config/passwd.tmp /data/config/passwd

	for F in /data/config/virtual-mailbox-maps /data/config/virtual-sender-login-maps
	do
		grep -v "^$EMAIL " $F > $F.tmp
		mv $F.tmp $F
		postmap $F
	done 

	echo "$EMAIL deleted (data kept)"
}

user-password()
{
	EMAIL=$1
	PASSWORD=$2

	USER=${EMAIL%@*}
	DOMAIN=${EMAIL#*@}

	AUTOPASS=0

	if ! postmap -q $EMAIL /data/config/virtual-mailbox-maps >/dev/null
	then
		echo $EMAIL not found >&2
		exit 1
	fi

	if [ -z "$PASSWORD" ]
	then
		# random password
		PASSWORD=$(gen-password)
		AUTOPASS=1
	fi

	# add credential
	# TODO: change method to non PLAIN 
	# TODO: should avoid linear text file
	grep -v "^$EMAIL:" /data/config/passwd > /data/config/passwd.tmp

	SHA512_PASSWORD=$( sha512 $PASSWORD)
	echo "$EMAIL:{SHA512.hex}$SHA512_PASSWORD" >> /data/config/passwd.tmp

	mv /data/config/passwd.tmp /data/config/passwd
	

	if [ $AUTOPASS == 1 ]
	then
		echo $EMAIL new password generated: $PASSWORD
	else
		echo $EMAIL password changed
	fi
}



remap()
{
	for map in /data/config/virtual-sender-login-maps /data/config/virtual-mailbox-maps /data/config/virtual-alias-maps
	do
		postmap $map
	done
}


status()
{
	for s in $SERVICES
	do
		service $s status 
	done
}

start()
{
	for s in $SERVICES
	do
		service $s start
	done
}

reload()
{
	for s in $SERVICES
	do
		service $s start
	done
}

security-check()
{
	test -d /run/dovecot               || mkdir /run/dovecot
	test -d /data/vmail                || mkdir /data/vmail
	test -d /data/config               || mkdir /data/config
	test -d /data/config/ssl           || mkdir /data/config/ssl
	test -d /data/config/opendkim      || mkdir /data/config/opendkim
	test -d /data/config/opendkim/keys || mkdir /data/config/opendkim/keys

	test -d /data/config/opendkim/KeyTable     || touch /data/config/opendkim/KeyTable
	test -d /data/config/opendkim/SigningTable || touch /data/config/opendkim/SigningTable
	test -d /data/config/opendkim/TrustedHosts || echo -e "127.0.0.1\nlocalhost" > /data/config/opendkim/TrustedHosts

	chown vmail: /data/vmail

	# create basic 
	test -e /data/config/passwd || touch /data/config/passwd
	chown dovecot: /data/config/passwd
	chmod 600 /data/config/passwd

	test -e /data/config/virtual-mailbox-domains || touch /data/config/virtual-mailbox-domains

	for map in /data/config/virtual-sender-login-maps /data/config/virtual-mailbox-maps /data/config/virtual-alias-maps
	do
		if [ ! -e $map ]
		then
			touch $map
			postmap $map
		fi
	done

	if [ ! -e /data/config/ssl/default.pem ]
	then
		echo "copy dummy ssl-cert-snakeoil.pem into /data/config/ssl/default.pem"
		cp /etc/ssl/certs/ssl-cert-snakeoil.pem   /data/config/ssl/default.pem 
		cp /etc/ssl/private/ssl-cert-snakeoil.key /data/config/ssl/default.key
	fi
	
	# security
	chmod 640 /data/config/ssl/*.key
}

_init()
{
	if [ -s /data/config/passwd ] 
	then
		start
		echo "Daemons started"
	else
		echo "${RED}Please initialize mailer using $0 tool, help:${RESET}"
		$0 
	fi
}

_run()
{
	_init
	if [ -s /data/config/passwd ] 
	then
		tail -F /var/log/messages
	fi
}

shell()
{
	_init
	exec /bin/bash
}

# --------------------------------------------

security-check

VERB=$1
shift

case $VERB in


	domain-list|user-list|remap|status|_run|shell)
	# no param
		$VERB
		;;

	# 1 domain param
	domain-add|domain-del|domain-check|dkim-get-selector)
		DOMAIN=$1
		shift
		test -z "$DOMAIN" && echo usage $0 $VERB '<domain>' >&2 && exit 1
		if $( is_valid_domain $DOMAIN )
		then
			$VERB $DOMAIN "$@"
		else
			echo "invalid domain $DOMAIN"
		fi
		;;

	user-add|user-del|user-password)
		EMAIL=$1
		shift
		test -z "$EMAIL" && echo usage $0 $VERB '<email>' >&2 && exit 1
		if $( is_valid_email $EMAIL )
		then
			$VERB $EMAIL "$@"
		else
 			echo "invalid email $EMAIL"
		fi
		;;

	*)
		usage
		;;

esac


