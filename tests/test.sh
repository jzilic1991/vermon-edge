#!/bin/bash

if [ -n "$1" ]; then
    mon=$1
else
    mon=monpoly
fi

dir=`pwd`

if [ -e $dir/errors.txt ]; then
    rm $dir/errors.txt
fi

# echo "Using $mon for tests"

for i in `seq 1 30`; do
    if [ -e "$dir/test$i.out" ]; then
        rm "$dir/test$i.out"
    fi
    while read f; do
        # strip comments of the form
        # 1) (* comment *)
        # 2) # comment
        # and reduces lines consisting of whitespace only to empty lines
        f=`echo "$f" | sed 's/(\*.*\*)//g; s/#.*$//; s/^\s+$//; s/\r//'`
    if [ "$f" != "" ]; then
        ff=$dir/test$i-tmp.mfotl
        echo "$f" > $ff
        # cat $ff
        # echo "---"
        $mon -sig $dir/tests.sig -formula $ff -log $dir/test$i.log \
            -verbose -nofilteremptytp -nonewlastts \
            >> $dir/test$i.out 2>> $dir/errors.txt
        echo "-----" >> $dir/test$i.out
        rm $ff
    fi
    done < $dir/test$i.mfotl
    diff -q $dir/test$i.out $dir/test$i.res
    if [ $? -eq 0 ]; then
        echo "Same results for test $i."
        rm test$i.out
    fi
done

if [ -s $dir/errors.txt ]; then
    diff -q $dir/errors.txt $dir/errors.res
    if [ $? -ne 0 ]; then  
        echo "There were errors: see errors.txt"
    fi
else
    rm $dir/errors.txt
fi
