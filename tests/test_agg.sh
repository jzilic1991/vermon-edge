#!/bin/bash

if [ -n "$1" ]; then
    mon=$1
else
    mon=monpoly
fi

log=test_agg_empty_rel.log
sig=test_agg_empty_rel.sig
out=test_agg_empty_rel.out
res=test_agg_empty_rel.res

if [ -e $out ]; then
    rm $out
fi

touch $out

while read f ; do
    # strip comments of the form
    # 1) (* comment *)
    # 2) # comment
    # and reduces lines consisting of whitespace only to empty lines
    f=`echo "$f" | sed 's/(\*.*\*)//g; s/#.*$//; s/^\s+$//; s/\r//'`
    if [ "$f" != "" ]; then
	ff=tmp.mfotl
	echo $f > $ff
        cat $ff >> $out
        # echo "---"
	$mon -sig $sig -formula $ff -log $log \
	    -nofilteremptytp -nonewlastts \
	    >> $out 2>> $out
	echo "-----" >> $out
	rm $ff
    fi
done < test_agg_empty_rel.mfotl

diff -q $res $out
if [ $? -eq 0 ]; then
    echo "Same results."
    rm $out
fi
