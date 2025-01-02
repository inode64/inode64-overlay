#!/bin/bash

search_dir=$1
cp=$2
old_version=$3
new_version=$4
new_sha=${5:-}
old_sha=${6:-}
hash_date=${7:-}

ebuild="$(echo "$cp"|cut -d/ -f2)"
distdir="$(portageq envvar DISTDIR 2>/dev/null)"

if [ "$cp" == "app-misc/node-red" ] || [ "$cp" == "dev-lang/typescript" ]; then
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

exit 0
