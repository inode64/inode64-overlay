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

. /etc/portage/inode64.conf

# livecheck only learns that an upload failed from the exit status, but a
# package with two archives must still try to upload the second one.
status=0
upload() {
	rsync -av "${distdir}/$1" "$INODE64_OVERLAY_REPO" || status=$?
}

if [ "$cp" == "app-backup/backrest" ] || \
    [ "$cp" == "app-metrics/alloy" ] || \
    [ "$cp" == "app-misc/node-red" ] || \
    [ "$cp" == "app-misc/zigbee2mqtt" ] || \
    [ "$cp" == "dev-lang/typescript" ] || \
    [ "$cp" == "dev-util/locust" ] || \
    [ "$cp" == "dev-util/openchamber" ] || \
    [ "$cp" == "dev-util/rulesync" ] || \
    [ "$cp" == "sys-process/pm2" ] || \
    [ "$cp" == "www-apps/guacamole-client" ] ; then
	upload "${ebuild}-${new_version}-node_modules.tar.xz"
fi

# With "archive_mode": "lockfile" the archive is ${PN}-<digest>-node_modules.tar.xz
# and versions with the same dependencies share it. rsync skips one that is
# already published.
if [ "$cp" == "dev-util/orca-ide" ]; then
	# ${PN} is matched literally, as the ebuild writes it.
	# shellcheck disable=SC2016
	archive=$(sed -n 's|.*/${PN}\(-[0-9a-f]\{16\}-node_modules\.tar\.xz\).*|'"${ebuild}"'\1|p' \
		"${search_dir}/${cp}/${ebuild}-${new_version}.ebuild")
	if [ -n "$archive" ]; then
		upload "$archive"
	else
		echo "No lockfile-named node_modules archive in ${cp}-${new_version}" >&2
		status=1
	fi
fi

if [ "$cp" == "app-backup/autorestic" ] || \
    [ "$cp" == "app-backup/backrest" ] || \
    [ "$cp" == "app-backup/wal-g" ] || \
    [ "$cp" == "app-backup/rest-server" ] || \
    [ "$cp" == "app-backup/resticprofile" ] || \
    [ "$cp" == "app-metrics/alloy" ] || \
    [ "$cp" == "app-metrics/mcp-grafana" ] || \
    [ "$cp" == "app-metrics/varnish_exporter" ] || \
    [ "$cp" == "dev-php/composer" ] || \
    [ "$cp" == "media-video/go2rtc" ] || \
    [ "$cp" == "sys-process/runitor" ] || \
    [ "$cp" == "net-vpn/nebula-mesh" ] || \
    [ "$cp" == "net-vpn/nebula" ] ; then
	upload "${ebuild}-${new_version}-vendor.tar.xz"
fi

if [ "$cp" == "www-apps/guacamole-client" ]; then
	upload "${ebuild}-${new_version}-mvn.tar.xz"
fi

if [ "$cp" == "dev-python/jiter" ] || \
    [ "$cp" == "sys-apps/pnpm" ] ; then
	upload "${ebuild}-${new_version}-crates.tar.xz"
fi

exit "$status"
