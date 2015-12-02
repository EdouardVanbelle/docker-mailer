FROM debian:jessie

MAINTAINER edouard@vanbelle.fr 

RUN \
	apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -q -y \
		openssl rsyslog \
		postfix opendkim opendkim-tools postfix-policyd-spf-python \
		spamassassin spamc \
		dovecot-common dovecot-imapd dovecot-sqlite dovecot-sieve dovecot-managesieved \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# TODO: Squash it
RUN	mkdir /data && \
	groupadd -g 5000 vmail && \
	useradd -g vmail -u 5000 vmail -d /data/vmail -m && \
	echo my-mailer > /etc/mailname && \
	echo 127.0.0.1 my-mailer >>/etc/hosts

ADD manage.sh /manage.sh

ADD etc/opendkim.conf 		/etc/opendkim.conf
ADD etc/default 		/etc/default
ADD etc/default/spamassassin 	/etc/default/spamassassin
ADD etc/postfix/main.cf 	/etc/postfix/main.cf
ADD etc/postfix/master.cf 	/etc/postfix/master.cf
ADD etc/dovecot/etc/ 		/etc/dovecot/etc/

# mails should be at least persistant...
VOLUME /data

# XXX take care that temp files like pending mails will be in /var/...
# TODO simplify logs (no need to polluate too much /var/log/mail.* & /var/log/messages)

# SMTP SUBMISSION IMAP MANAGESIEVE
EXPOSE 25 587 143 4190
# XXX: no need to open SSL (TLS is forced): 995 993

# by default call: /manage.sh run

ENTRYPOINT [ "/manage.sh", "_run" ]

