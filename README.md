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

