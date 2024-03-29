FROM debian:bookworm

MAINTAINER Edouard Vanbelle <edouard@vanbelle.fr>

RUN \
	echo "LANG=C" > /etc/default/locale \
	&& apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get upgrade -q -y \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -q -y \
		apt-utils procps less vim ca-certificates dnsutils netcat-openbsd \
		openssl rsyslog sqlite3 \
		postfix opendkim opendkim-tools postfix-policyd-spf-python \
		spamassassin spamc bogofilter \
		dovecot-common dovecot-imapd dovecot-sqlite dovecot-antispam dovecot-sieve dovecot-managesieved \
		jq \
	&& apt-get clean \
	&& apt-get autoclean \
	&& rm -rf /var/lib/apt/lists/*

# /etc/my-mailer is a stupid marker for manage.sh to check if it is inside container
RUN	mkdir /data && \
	mkdir /data/cache && \
	groupadd -g 5000 vmail && \
	useradd -g vmail -u 5000 vmail -d /data/vmail -m && \
	ln -s /data/log/mail/mail.log /var/log/syslog && \
	touch /etc/my-mailer

ADD scripts/manage 			/usr/local/bin/manage
ADD scripts/bogofilter-dovecot.lda 	/usr/local/bin/bogofilter-dovecot.lda
ADD scripts/antispam-action.wrapper     /usr/local/bin/antispam-action.wrapper
ADD scripts/dovecot-archive             /usr/local/bin/dovecot-archive
ADD scripts/auto-welcomelist		/usr/local/bin/auto-welcomelist
ADD scripts/rotate			/usr/local/bin/rotate

ADD etc/rsyslog.conf		  	/etc/rsyslog.conf
ADD etc/opendkim.conf 		  	/etc/opendkim.conf
ADD etc/default 		  	/etc/default
ADD etc/default/spamassassin 	  	/etc/default/spamassassin
ADD etc/spamassassin/local.cf	  	/etc/spamassassin/local.cf
ADD etc/postfix/main.cf 	  	/etc/postfix/main.cf
ADD etc/postfix/master.cf 	  	/etc/postfix/master.cf
ADD etc/dovecot/conf.d/	 	  	/etc/dovecot/conf.d/
ADD etc/dovecot/sieve/	 	  	/etc/dovecot/sieve/
ADD etc/dovecot/virtual-template/	/etc/dovecot/virtual-template/
ADD etc/cron.hourly/auto-welcomelist	/etc/cron.hourly/auto-welcomelist
ADD etc/cron.daily/dovecot-archive	/etc/cron.daily/dovecot-archive
ADD etc/cron.weekly/rotate		/etc/cron.weekly/rotate
ADD etc/cron.d/ssl-reload		/etc/cron.d/ssl-reload

# mails should be at least persistant...
VOLUME /data

# XXX take care that temp files like mails spool or spamassassin db will be in /var/... 

# SMTP SUBMISSION IMAP MANAGESIEVE SMTPS IMAPS
EXPOSE 25 587 143 4190 465 993
# XXX: don't really need imaps nor smtps (TLS is present)

# FIXME: implement it @see: https://dzone.com/articles/health-checking-your-docker-containers
HEALTHCHECK --interval=60s --timeout=3s \
	CMD openssl s_client -showcerts -starttls smtp -servername mail.vanbelle.fr -connect 127.0.0.1:25  </dev/null >/dev/null \
	&&  openssl s_client -showcerts -starttls imap -servername mail.vanbelle.fr -connect 127.0.0.1:143 </dev/null >/dev/null
	


# by default call: /manage.sh _run
ENTRYPOINT [ "/usr/local/bin/manage", "_run" ]

