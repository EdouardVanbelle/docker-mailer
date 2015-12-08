FROM debian:jessie

MAINTAINER Edouard Vanbelle <edouard@vanbelle.fr>

RUN \
	apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -q -y \
		ca-certificates dnsutils netcat \
		openssl rsyslog \
		postfix opendkim opendkim-tools postfix-policyd-spf-python \
		spamassassin spamc bogofilter \
		dovecot-common dovecot-imapd dovecot-sqlite dovecot-antispam dovecot-sieve dovecot-managesieved \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# /etc/my-mailer is a stupid marker for manage.sh to check if it is inside container
RUN	mkdir /data && \
	mkdir /data/cache && \
	groupadd -g 5000 vmail && \
	useradd -g vmail -u 5000 vmail -d /data/vmail -m && \
	echo my-mailer > /etc/mailname && \
	touch /etc/my-mailer

ADD scripts/manage 			/usr/local/bin/manage
ADD scripts/bogofilter-dovecot.lda 	/usr/local/bin/bogofilter-dovecot.lda
ADD scripts/antispam-action.wrapper     /usr/local/bin/antispam-action.wrapper

ADD etc/rsyslog.conf		  /etc/rsyslog.conf
ADD etc/opendkim.conf 		  /etc/opendkim.conf
ADD etc/default 		  /etc/default
ADD etc/default/spamassassin 	  /etc/default/spamassassin
ADD etc/spamassassin/local.cf	  /etc/spamassassin/local.cf
ADD etc/postfix/main.cf 	  /etc/postfix/main.cf
ADD etc/postfix/master.cf 	  /etc/postfix/master.cf
ADD etc/dovecot/conf.d/	 	  /etc/dovecot/conf.d/
ADD etc/dovecot/sieve/	 	  /etc/dovecot/sieve/
ADD etc/dovecot/virtual-template/ /etc/dovecot/virtual-template/

# mails should be at least persistant...
VOLUME /data

# XXX take care that temp files like mails spool or spamassassin db will be in /var/... 

# SMTP SUBMISSION IMAP MANAGESIEVE
EXPOSE 25 587 143 4190
# XXX: no need to open SSL (TLS is forced): 995 993

# by default call: /manage.sh _run
ENTRYPOINT [ "/usr/local/bin/manage", "_run" ]

