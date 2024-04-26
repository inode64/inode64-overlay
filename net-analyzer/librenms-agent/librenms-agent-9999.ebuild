# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3 tmpfiles systemd

DESCRIPTION="Agent for librenms"
HOMEPAGE="https://www.librenms.org"
EGIT_REPO_URI="https://github.com/librenms/${PN}"

LIBRENMS_SNMP_APPS="
    apache
    asterisk
    backupninja
    beagleboard
    bind
    borgbackup
    cape
    certificate
    chip
    chrony
    dhcp
    distro
    docker
    entropy
    exim-stats
    fail2ban
    freeradius
    gpsd
    icecast-stats
    ifAlias
    linux_config_files
    linux_iw
    linux_softnet_stat
    logsize
    mailscanner
    mdadm
    memcached
    mysql
    nfs
    nginx
    ntp
    nvidia
    opensearch
    opensip
    php
    pi-hole
    portactivity
    postfix
    postgres
    poudriere
    powerdns
    powermon
    privoxy
    puppet_agent
    pureftpd
    pwrstatd
    raspberry
    redis
    rpigpiomonitor
    sdfsinfo
    seafile
    shoutcast
    smart
    ss
    supervisord
    systemd
    unbound
    ups-apcups
    ups-nut
    voipmon-stats
    wireguard
    zfs
"

LIBRENMS_AGENT_APPS="
    apache
    bind
    ceph
    check_mrpe
    dmi
    drbd
    freeswitch
    gpsd
    hddtemp
    memcached
    munin
    mysql
    nfs
    nginx
    powerdns
    rocks
    rrdcached
    temperature
    tinydns
    unbound
"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"
IUSE="agent snmp systemd"

for app in $LIBRENMS_SNMP_APPS; do
	IUSE="${IUSE} librenms_snmp_app_${app}"
done
for app in $LIBRENMS_AGENT_APPS; do
	IUSE="${IUSE} librenms_agent_app_${app}"
done

RDEPEND="
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
	librenms_snmp_app_apache? ( dev-perl/libwww-perl net-misc/curl )
	librenms_snmp_app_bind? ( dev-perl/File-ReadBackwards )
	librenms_snmp_app_fail2ban? ( dev-perl/JSON )
	librenms_snmp_app_bind? ( dev-perl/File-ReadBackwards )
	librenms_snmp_app_borgbackup? ( dev-perl/Config-Tiny dev-perl/File-Slurp dev-perl/JSON dev-perl/String-ShellQuote )
	librenms_snmp_app_cape? ( dev-perl/Config-Tiny dev-perl/File-Slurp dev-perl/JSON dev-perl/String-ShellQuote )
	librenms_snmp_app_chip? ( sys-apps/i2c-tools )
	librenms_snmp_app_dhcp? ( dev-perl/File-Slurp dev-perl/JSON )
	librenms_snmp_app_fail2ban? ( dev-perl/JSON )
	librenms_snmp_app_linux_softnet_stat? ( dev-perl/File-Slurp dev-perl/JSON )
	librenms_snmp_app_logsize? ( dev-perl/File-Slurp dev-perl/JSON dev-perl/File-Find-Rule )
	librenms_snmp_app_mailscanner? ( dev-lang/php )
	librenms_snmp_app_mdadm? ( app-misc/jq )
	librenms_snmp_app_memcached? ( dev-lang/php )
	librenms_snmp_app_mysql? ( dev-lang/php )
	librenms_snmp_app_nfs? ( dev-perl/File-Slurp dev-perl/JSON )
	librenms_snmp_app_opensearch? ( dev-perl/JSON )
	librenms_snmp_app_opensip? ( net-misc/curl )
	librenms_snmp_app_php? ( net-misc/curl )
	librenms_snmp_app_pi-hole? ( app-misc/jq net-misc/curl )
	librenms_snmp_app_portactivity? ( dev-perl/JSON )
	librenms_snmp_app_powerdns? ( app-misc/jq net-misc/curl )
	librenms_snmp_app_poudriere? ( dev-perl/File-Slurp dev-perl/JSON )
	librenms_snmp_app_privoxy? ( dev-perl/File-Slurp dev-perl/JSON )
	librenms_snmp_app_smart? ( dev-perl/JSON )
	librenms_snmp_app_ups-apcups? ( dev-perl/JSON )
	librenms_snmp_app_zfs? ( dev-perl/File-Slurp dev-perl/JSON )
	librenms_agent_app_check_mrpe? ( net-analyzer/openbsd-netcat )
	librenms_agent_app_dmi? ( sys-apps/dmidecode )
	librenms_agent_app_gpsd? ( dev-lang/php )
	librenms_agent_app_hddtemp? ( app-admin/hddtemp )
	librenms_agent_app_memcached? ( dev-lang/php )
	librenms_agent_app_mysql? ( dev-lang/php )
"

LIBRENMS_AGENT="/usr/lib/check_mk_agent"

src_compile() {
	rm snmp/distro || die
	rm agent-local/README || die
	rm -rf snmp/{Openwrt,Routeros,linux_config_files.py} || die
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
			systemd_dounit check_mk@.service
		else
			insinto /etc/xinetd.d
			newins check_mk_xinetd check_mk
		fi

		keepdir /etc/check_mk
	fi

	if use snmp; then
		insinto ${LIBRENMS_AGENT}/snmp
		doins snmp/*

		insinto /etc/snmp/conf.d.avail
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
