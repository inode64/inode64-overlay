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

if [ "$cp" == "dev-python/jiter" ]; then
	upload "${ebuild}-${new_version}-crates.tar.xz"
fi

exit "$status"
