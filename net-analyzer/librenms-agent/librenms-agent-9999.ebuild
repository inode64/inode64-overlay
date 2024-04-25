# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )
inherit git-r3 python-single-r1 tmpfiles

DESCRIPTION="Agent for librenms"
HOMEPAGE="https://www.librenms.org"
EGIT_REPO_URI="https://github.com/librenms/${PN}"

LIBRENMS_APPS="
	apache
	asterisk
	backupninja
	beagleboard
	bind
	borgbackup
	cape
	ceph
	certificate
	check_mrpe
	chip
	chrony
	dhcp
	distro
	dmi
	docker
	drbd
	entropy
	exim
	fail2ban
	freeradius
	freeswitch
	gpsd
	hddtemp
	icecast-stats
	ifAlias
	linux_config_files
	linux_iw
	linux_softnet_stat
	logsize
	mailcow-dockerized-postfix
	mailscanner
	mdadm
	memcached
	munin
	mysql
	nfs
	nginx
	ntp-client
	ntp-server
	nvidia
	opensearch
	opensip
	osupdate
	pacman
	phpfpmsp
	pi-hole
	portactivity
	postfix
	postgres
	poudriere
	powerdns
	powermon-snmp
	privoxy
	proxmox
	puppet_agent
	pureftpd
	pwrstatd
	raspberry
	redis
	rocks
	rpigpiomonitor
	rpm
	rrdcached
	sdfsinfo
	seafile
	shoutcast
	smart
	ss
	supervisord
	systemd
	temperature
	tinydns
	unbound
	ups-apcups
	ups-nut
	voipmon-stats
	wireguard
	zfs
"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"
IUSE="agent snmp systemd"

for app in $LIBRENMS_APPS; do
	IUSE="${IUSE} librenms_app_${app}"
done

REQUIRED_USE="
	${PYTHON_REQUIRED_USE}
"
RDEPEND="
	${PYTHON_DEPS}
	agent? (
		!systemd? ( sys-apps/xinetd )
		sys-apps/ethtool
		sys-apps/ipmitool
	)
	snmp? (
		net-analyzer/net-snmp[elf,lm-sensors,mfd-rewrites,netlink,pci]
		app-admin/sudo
		dev-python/distro
	)
	librenms_app_apache? ( dev-perl/libwww-perl )
	librenms_app_bind? ( dev-perl/File-ReadBackwards )
	librenms_app_fail2ban? ( dev-perl/JSON )
	librenms_app_hddtemp? ( app-admin/hddtemp )
	librenms_app_mdadm? ( dev-perl/JSON )
"

LIBRENMS_AGENT="/usr/lib/check_mk_agent"

src_compile() {
	rm snmp/distro || die
	rm agent-local/README || die
	rm -rf snmp/{Openwrt,Routeros} || die
}

src_install() {
	diropts -m 0750

	if use agent; then
		insinto /usr/bin/
		doins check_mk_agent mk_enplug
		fperms 0750 /usr/bin/{check_mk_agent,mk_enplug}

		keepdir ${LIBRENMS_AGENT}/{local,plugins}

		insinto ${LIBRENMS_AGENT}/repo
		doins agent-local/*

		fperms +x -R ${LIBRENMS_AGENT}/repo

		if use systemd; then
			systemd_dounit check_mk@.service"
		else
			insinto /etc/xinetd.d
			newins check_mk_xinetd check_mk
		fi

		keepdir /etc/check_mk
	fi

	if use snmp; then
		insinto ${LIBRENMS_AGENT}/snmp
		doins snmp/*

		insinto /etc/snmp/conf.d/librenms
		doins "${FILESDIR}"/snmp/*

		fperms +x -R ${LIBRENMS_AGENT}/snmp
	fi

	dotmpfiles "${FILESDIR}"/librenms-agent.conf
}

pkg_postinst() {
	tmpfiles_process librenms-agent.conf

	if use agent; then
		einfo "Use Cmk_enplug to enable app"
	fi
}
