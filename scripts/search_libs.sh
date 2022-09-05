#!/bin/bash

# https://forums.gentoo.org/viewtopic-t-846698-start-0.html

# find > ../$(basename $(pwd)).txt
# find -type f -executable > ../$(basename $(pwd))_exe.txt
# find -exec ldd {} 2>/dev/null \; |awk '{print $1}'|sort|uniq > ../$(basename $(pwd))_ldd.txt

if [ ! "$1" ]; then
    echo "Missing parameter"
    exit 1
fi

temp_file=$(mktemp /tmp/`basename $0`.XXXXXX)

(
	cat "$1" | while read -r lib; do
		grep "$lib" /var/db/pkg/*/*/CONTENTS | cut -d/ -f5-6
	done
) |sort|uniq > ${temp_file}

cat ${temp_file} | while read -r file; do
	cat ${temp_file} | while read -r dest; do
		if grep
	done
done
