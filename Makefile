DOCKER=my-mailer
LOCAL=/data-active
INSTANCE="${DOCKER}-instance"
LISTEN=`dig +short A mail.vanbelle.fr`
TIMEZONE=`readlink /etc/localtime | sed 's!/usr/share/zoneinfo/!!'`

all: build

.PHONY: build container start stop enter

# build image
build:
	docker build --pull -t dropz-one/${DOCKER} .

#create container
container: 
	docker run -t -d -h ${DOCKER} --env TZ=${TIMEZONE} --name "${INSTANCE}" -p ${LISTEN}:25:25 -p ${LISTEN}:143:143 -p ${LISTEN}:587:587 -p ${LISTEN}:4190:4190 -p ${LISTEN}:465:465 -p ${LISTEN}:993:993 -v ${LOCAL}/mail-data:/data -v ${LOCAL}/postfix-spool:/var/spool/postfix dropz-one/${DOCKER}

start:
	docker start ${INSTANCE}
stop:
	docker stop ${INSTANCE}

enter:
	docker exec -t -i ${INSTANCE} /bin/bash

