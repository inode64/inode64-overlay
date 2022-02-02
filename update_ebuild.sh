#!/bin/bash

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
	<email>ffelix@inode64.com</email>
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
done

repoman 2>/dev/null
