#!/bin/sh
if [ ! -f "./compile" ]
then
autoreconf -i -f -v
if [ -f "../ltmain.sh" ]
then
echo "fixing ltmain.sh for some reason"
mv ../ltmain.sh ./
autoreconf -i -f -v
fi
/usr/bin/python generate-darwin-source-and-headers.py --only-ios
fi
