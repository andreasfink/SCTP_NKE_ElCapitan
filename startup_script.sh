#!/bin/sh
#
##
# SCTP Startup Script
# (c) Copyright 2006-2014 Andreas Fink <andreas@fink.org>
# Maveriks Version
##

. /etc/rc.common

StatusService()
{
    kextstat | grep sctp
}

PrepareService ()
{
    ConsoleMessage "Preparing SCTP driver"
	/usr/sbin/kextcache -e -a x86_64
}

FirstStart ()
{
	PrepareService
	StartService
}

StartService ()
{
    ConsoleMessage "Loading SCTP driver"
#   kextutil -t -v /Library/Extensions/SCTPSupport.kext
    kextutil -t -v /Library/Extensions/SCTP.kext
    sysctl -w net.inet.sctp.addr_watchdog_limit=120
}

StopService ()
{
    ConsoleMessage "Unloading SCTP driver"
    kextunload /Library/Extensions/SCTP.kext
#   kextunload /Library/Extensions/SCTPSupport.kext
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



