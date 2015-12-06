DOCKER=my-mailer

all: build

.PHONY: build run

build:
	docker build -t dropz-one/${DOCKER} .

run: 
	docker run -t -i -h my-mailer -p 25:25 -p 143:143 -p 587:587 -p 4190:4190 -v /home/mail-data:/data dropz-one/${DOCKER}
