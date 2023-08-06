#!/bin/sh

docker container export my-mailer-instance | tar -xO etc/postfix/master.cf > etc/postfix/master.cf.LIVE
docker container export my-mailer-instance | tar -xO etc/postfix/main.cf   > etc/postfix/main.cf.LIVE
