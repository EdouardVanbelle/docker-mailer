DOCKER=my-mailer
VERSION=1
LOCAL=/data-active
INSTANCE="${DOCKER}-instance"
LISTEN=`dig +short A mail.vanbelle.fr`
TIMEZONE=`readlink /etc/localtime | sed 's!/usr/share/zoneinfo/!!'`

all: build

.PHONY: build container start stop enter

# build image
build:
	docker build --pull -t dropz-one/${DOCKER}:${VERSION} .

move:
	docker container rename ${INSTANCE} ${INSTANCE}.old

#create container
container: 
	docker run -t -d -h ${DOCKER} --restart=unless-stopped --env TZ=${TIMEZONE} --name "${INSTANCE}" \
		-p ${LISTEN}:25:25 -p ${LISTEN}:143:143 -p ${LISTEN}:587:587 -p ${LISTEN}:4190:4190 -p ${LISTEN}:465:465 -p ${LISTEN}:993:993 \
		-v ${LOCAL}/mail-data:/data \
		-v ${LOCAL}/letsencrypt:/letsencrypt:ro \
		-v ${LOCAL}/postfix-spool:/var/spool/postfix --network web-net dropz-one/${DOCKER}:${VERSION}

start:
	docker start ${INSTANCE}
stop:
	docker stop ${INSTANCE}

# clean only moved container
clean:
	docker container rm ${INSTANCE}.old

enter:
	docker exec -t -i ${INSTANCE} /bin/bash

