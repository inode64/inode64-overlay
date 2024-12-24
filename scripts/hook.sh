#!/bin/bash

cmd=$1
search_dir=$2
cp=$3
old_version=$4
new_version=$5
new_sha=${6:-}
old_sha=${7:-}
hash_date=${8:-}

ebuild="$(echo "$cp"|cut -d/ -f2)"
distdir="$(portageq envvar DISTDIR 2>/dev/null)"

if [ "$cmd" == "post" ]; then
	if [ "$cp" == "app-misc/node-red" ]; then
		file="${ebuild}-${new_version}-node_modules.tar.xz"
		cp ${distdir}/${file} ${search_dir}/dist/
		git add ${search_dir}/dist/${file}
		git commit -m "Add distfile for ${cp}"
	fi

	if [ "$cp" == "net-vpn/cloudflared" ]; then
		file="${ebuild}-${new_version}-vendor.tar.xz"
		cp ${distdir}/${file} ${search_dir}/dist/
		git add ${search_dir}/dist/${file}
		git commit -m "Add distfile for ${cp}"
	fi
fi

exit 0
