#!/bin/bash
if [ -e $1 ] ; then
    find $1 -exec wc -l {} + 2>/dev/null | grep total | awk '{print $1}'
else
    find ./ -exec wc -l {} + 2>/dev/null | grep total | awk '{print $1}'
fi


