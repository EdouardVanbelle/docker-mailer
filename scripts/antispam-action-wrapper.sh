#!/bin/bash

while [ ${#@} -gt 0 ]
do
        param=$1
        shift
        case $param in
                --user)
                        USER=$1
                        shift;
                        ;;
                --domain)
                        DOMAIN=$1
                        shift;
                        ;;
                --spam)
                        ACTION=-s
                        ;;
                --ham)
                        ACTION=-n
                        ;;
                *)
                        # unknown parameter
                        ;;
        esac
done

HOME=/data/vmail/$DOMAIN/$USER/bogofilter

if [ ! -d $HOME ]
then
	/usr/bin/logger -p mail.err -- "antispam-action-wrapper.sh: $HOME does not exist yet"
        exit 255
fi

if [ ! -z "$ACTION" ]
then
	/usr/bin/logger -p mail.err -- "antispam-action-wrapper.sh: no action (--spam or --ham) specified"
        exit 255
fi


/usr/bin/bogofilter -l -q -d $HOME $ACTION 
EXITCODE=$?

exit $EXITCODE

