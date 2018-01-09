#!/bin/bash
# startup script to launch sctp

#!/bin/sh
#
##
# SCTP Startup Script
# (c) Copyright 2018 Andreas Fink <andreas@fink.org>
# Maveriks Version
##

mkdir -p /var/log/sctp
LOG="/var/log/sctp/start.log"

echo "----------" > "$LOG"
echo "/Library/Application Support/me.fink.sctp/startup_script.sh is being called at `date`" >> "$LOG"
echo "Input Parameters: $@"  >> "$LOG"
echo "Calling /etc/rc.common" >> "$LOG"
. /etc/rc.common

StatusService()
{
    kextstat | grep sctp
}

PrepareService ()
{
       	/usr/sbin/kextcache -e -a x86_64
       	launchctl load -w /Library/LaunchDaemons/me.fink.sctp.plist
}

FirstStart ()
{
    PrepareService
    StartService
}

StartService ()
{
    echo "Loading SCTP driver" >> "$LOG"
    echo " kextutil -t -v /Library/Extensions/SCTP.kext" >> "$LOG"
    kextutil -t -v /Library/Extensions/SCTP.kext  >> "$LOG"
    echo " sysctl -w net.inet.sctp.addr_watchdog_limit=120"
    sysctl -w net.inet.sctp.addr_watchdog_limit=120 >> "$LOG"
}

WaitForever()
{
    echo "wait forever" >> $LOG
    while true
    do
        sleep 10000000
    done
}

StopService ()
{
    echo "Unoading SCTP driver" >> "$LOG"
    echo " kextunload /Library/Extensions/SCTP.kext " >> "$LOG"
    kextunload /Library/Extensions/SCTP.kext
}

RestartService ()
{
    StopService
    StartService
}

if( [ "$1" = "start" ] )
then
    StartService
fi

if( [ "$1" = "start-and-wait" ] )
then
    StartService
    WaitForever
fi

if( [ "$1" = "stop" ] )
then
    StopService
fi

if( [ "$1" = "restart" ] )
then
    RestartService
fi

if( [ "$1" = "status" ] )
then
    StatusService
fi

if( [ "$1" = "prepare" ] )
then
    PrepareService
fi

if( [ "$1" = "FirstStart" ] )
then
    FirstStart
fi



