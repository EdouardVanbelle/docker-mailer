DOCKER=my-mailer
LOCAL=/home
INSTANCE="${DOCKER}-instance"

all: build

.PHONY: build container start stop enter

# build image
build:
	docker build -t dropz-one/${DOCKER} .

#create container
container: 
	docker run -t -d -h ${DOCKER} --name "${INSTANCE}" -p 25:25 -p 143:143 -p 587:587 -p 4190:4190 -p 465:465 -p 993:993 -v ${LOCAL}/mail-data:/data -v ${LOCAL}/postfix-spool:/var/spool/postfix dropz-one/${DOCKER}

start:
	docker start ${INSTANCE}
stop:
	docker stop ${INSTANCE}

enter:
	docker exec -t -i ${INSTANCE} /bin/bash

