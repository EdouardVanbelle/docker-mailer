# postfix + dovecot in one container

This container is designed for you if you are like me, tired of reinstalling your mail solution
It contains:

  * postfix
  * dovecot
  * spamassassin 
  * opendkim
  * postfix

There is a helper to configure your container

# build

	`# docker build -t my-mailer .`

# run

	`# docker run -t -i -h my-mailer -p 25:25 -p 143:143 -p 587:587 -p 4190:4190 -v /home/mail-data:/data my-mailer`	

# tools

	# ./run shell
	docker run -t -i -h my-mailer -p 25:25 -p 143:143 -p 587:587 -p 4190:4190 -v /home/mail-data:/data my-mailer shell
	[ ok ] Starting periodic command scheduler: cron.
	[ ok ] Starting IMAP/POP3 mail server: dovecot.
	Starting SpamAssassin Mail Filter Daemon: spamd.
	Starting OpenDKIM: opendkim.
	[ ok ] Starting Postfix Mail Transport Agent: postfix.
	[ ok ] Starting enhanced syslogd: rsyslogd.
	Daemons started

	root@my-mailer:/# /manage.sh 
	/manage.sh <domain-list|user-list|remap|status|shell|domain-add|domain-del|domain-check|dkim-get-selector|user-add|user-del|user-password>

	root@my-mailer:/# /manage.sh domain-list
	enor.me

	root@my-mailer:/# /manage.sh user-add c@enor.me
	c@enor.me added with password 4Ad-Az$Ed...

	root@my-mailer:/# /manage.sh domain-add dropz.one
	don't forget to add DKIM key in your zone:
	default._domainkey      IN      TXT     ( "v=DKIM1; k=rsa; "
		  "p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC07yJorKfsPVY7Rp+9AXzjziDFuy/WENpScBhCCnbwNXNX6k0AotrllcL2hO0Td0ZTI4fjSAPpclML+YqCaPs54L9A1riKI7sToynicIX0Vg/YlwJ4sCPgz3TyYOJMxRLuACsCnZIPNzrIk1SqxZ4aglzj+zW5ZgrXO27kFB4C4QIDAQAB" )  ; ----- DKIM key default for omain
	_adsp._domainkey.dropz.one TXT 'dkim=all'
	dropz.one added (use /manage.sh domain-check dropz.one to test)

