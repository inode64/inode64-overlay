#!/bin/bash

# For convert go.sum to EGO_SUM
# cat go.sum |awk '{print $1 " " $2}'|while read line; do echo \"${line}\"; done

temp_file=$(mktemp "/tmp/$(basename "$0").XXXXXX")

#
# Fix tabs in old metadata.xml
#

#find -iname metadata.xml| while read file; do
#	expand -i -t8 ${file} >"${temp_file}"
#	unexpand --first-only -t4 "${temp_file}" >${file}
#done

#
# Trim and convert indents to tabs
#

find . -type f | grep -v ".svn\|CVS\|CVSROOT\|.git\|.idea\|eclass" | while read -r file; do
	if file "${file}" | grep -v 'unified diff' | grep -q text; then
		sed -i -e 's/[ \t]*$//' "${file}"
		unexpand --first-only "${file}" | awk '/^$/ {nlstack=nlstack "\n";next;} {printf "%s",nlstack; nlstack=""; print;}' >"${temp_file}"
		cat "${temp_file}" >"${file}"
	fi
done

rm -f "${temp_file}" 2>/dev/null

find . -name "*.ebuild" | while read -r ebuild; do
	sed -i '/^# Copyright/d' "${ebuild}"
	sed -i '/^# Distributed/d' "${ebuild}"

	sed -i "1s/^/# Distributed under the terms of the GNU General Public License v2\n/" "${ebuild}"
	sed -i "1s/^/# Copyright 1999-$(date +%Y) Gentoo Authors\n/" "${ebuild}"

	metadata=$(dirname "${ebuild}")/metadata.xml

	if [ ! -e "${metadata}" ]; then
		tee "${metadata}" <<EOF >/dev/null
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE pkgmetadata SYSTEM "https://www.gentoo.org/dtd/metadata.dtd">
<pkgmetadata>
	<maintainer type="person" proxied="yes">
		<email>web@inode64.com</email>
		<name>Fco. Javier Félix</name>
	</maintainer>
		<maintainer type="project" proxied="proxy">
		<email>proxy-maint@gentoo.org</email>
		<name>Proxy Maintainers</name>
	</maintainer>
</pkgmetadata>
EOF
	fi
	ebuild "${ebuild}" digest 2>/dev/null
	#ebuild "${ebuild}" clean manifest prepare 2>/dev/null
done

/usr/bin/pkgcheck scan --net
