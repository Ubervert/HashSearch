#!/bin/sh
#
#########################################
# Author: Ubervert
# Depends:
#       jsawk
#       curl
#
# Searches goog.li for hashes in its db
# Takes the hash file name as an argument
# 
# Outputs to HASH_TYPE (of that hash)
# Output format is similar to pot file
# Hash:pass

#########################################

errors=0
supress=0
file=0

## Checks for depends
command -v jsawk >/dev/null 2>&1 || { echo >&2 "Error: jsawk is not installed.";errors=$((errors+1));}
command -v curl >/dev/null 2>&1 || { echo >&2 "Error: curl is not installed.";errors=$((errors+1));}

if [ $errors -gt 0 ] ; then
        echo 'Errors:' $errors
        exit
fi

## Checks for correct number of arguments
if [ $# -lt 1 ] ; then
        echo 'Usage: '$0 'INPUT_FILE [-o OUTPUT_FILE] [-s]'
	echo "\$OUTPUT_FILE: Output file or - to indicate stdout"
	echo '-s: Supresses output to terminal (only printing to files)'
	echo "Note: -s takes precedence over -f, so printing to stdout with '-f -' is supressed"
        echo 'REASON: Expected at least 1 file name,' $# 'args given'
        exit
fi

## Gets the parameters
arglist=("$@")
for args in `seq 1 $(($#-1))`
do
	arg=$(($args+1))
	if [ "${arglist[$args]}" = "-o" ]; then 
		if [ $arg -lt $# ]; then
			file=${arglist[$arg]}
		else
			echo 'No output file given'
			exit
		fi
	else 
		if [ "${arglist[$args]}" = "-s" ]; then
			supress=1
		fi
	fi
done

## Searches for the hashes!
for line in $(cat $1)
do
        raw=`curl -ks https://goog.li/?j=$line`
        result=`echo "$raw" | jsawk 'return this.found'`
        if [ "$result" = "true" ] ; then
                digest=`echo "$raw" | jsawk 'return this.type'`
                check=`echo "$raw" | jsawk "return this.hashes[0].$digest"`
                pt=`echo "$raw" | jsawk 'return this.hashes[0].plaintext'`
                if [ "$supress" = "0" ] ; then
			if [ "$file" = " 0" ] ; then
				echo $check':'$pt | tee -a $digest
			else
				echo $check':'$pt | tee -a $file
			fi
		else
			if [ "$file"  = "-" ] ; then
				exit
			else
				if [ "$file" = "0" ] ; then
					echo $check':'$pt >> $digest
				else
					echo $check':'$pt >> $file
				fi
			fi
		fi
        fi
done
