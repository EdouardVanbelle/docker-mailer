FROM debian:jessie

MAINTAINER edouard@vanbelle.fr 

RUN \
	apt-get update && \
	apt-get install -y \
		postfix \
		dovecot-common dovecot-imapd dovecot-sqlite \
		openssl opendkim opendkim-tools 
#	groupadd -g 5000 vmail && \
#	useradd -g vmail -u 5000 vmail -d /home/vmail -m && \
#	chgrp vmail /etc/dovecot/dovecot.conf && \
#	chmod g+r /etc/dovecot/dovecot.conf

# TODO: check for clamav / spamassassin ? / bogofilter ?

#ADD postfix /etc/postfix

ADD start.sh /start.sh

# mails should be at least persistant...
VOLUME /home/vmail

# XXX take care that temp files like pending mails will be in /var/...

# SMTP & IMAP ports
EXPOSE 25 587 143 995 993

# go
CMD /start.sh
