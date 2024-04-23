# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )
inherit git-r3 python-single-r1

DESCRIPTION="a fully featured network monitoring system"
HOMEPAGE="https://www.librenms.org"
EGIT_REPO_URI="https://github.com/librenms/${PN}"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"
IUSE="apache fail2ban mdadm bind ipmi hddtemp"

REQUIRED_USE="
	${PYTHON_REQUIRED_USE}
"
RDEPEND="
	${PYTHON_DEPS}
	hddtemp? ( app-admin/hddtemp )
	sys-apps/ethtool
	app-admin/sudo
	dev-python/distro
	sys-apps/xinetd
	net-analyzer/net-snmp[elf,lm-sensors,mfd-rewrites,netlink,pci]
	apache? ( dev-python/pycurl dev-perl/libwww-perl )
	fail2ban? ( dev-perl/JSON )
	mdadm? ( dev-perl/JSON )
	bind? ( dev-perl/File-ReadBackwards )
	ipmi? ( || ( sys-libs/freeipmi sys-apps/ipmitool ) )
"

LIBRENMS_AGENT="/usr/lib/check_mk_agent"

src_compile() {
	rm snmp/distro
	#rm snmp/snmpd.conf.example
	rm agent-local/README
	rm -rf snmp/Openwrt

	sed -i -e 's:/usr/bin/grep:/bin/grep:g' snmp/* agent-local/*
	sed -i -e 's:/usr/bin/cat:/bin/cat:g' snmp/* agent-local/*
	sed -i -e 's:/usr/bin/sed:/bin/sed:g' snmp/* agent-local/*
	sed -i -e 's:/usr/bin/rm:/bin/rm:g' snmp/* agent-local/*
	sed -i -e 's:/usr/bin/mv:/bin/mv:g' snmp/* agent-local/*
}

src_install() {
	diropts -m 0750

	insinto /usr/bin/
	doins check_mk_agent
	doins mk_enplug
	fperms 0750 /usr/bin/{check_mk_agent,mk_enplug}

	dodir ${LIBRENMS_AGENT}/plugins
	dodir ${LIBRENMS_AGENT}/local
	dodir ${LIBRENMS_AGENT}/repo
	dodir ${LIBRENMS_AGENT}/snmp

	insinto ${LIBRENMS_AGENT}/snmp
	doins snmp/*

	insinto ${LIBRENMS_AGENT}/repo
	doins agent-local/*

	insinto /etc/xinetd.d
	newins check_mk_xinetd check_mk

	keepdir /var/cache/librenms/
	keepdir /var/cache/librenms/spool
	keepdir /etc/check_mk

	insinto /etc/snmp/conf.d/librenms

	doins "${FILESDIR}"/snmp/*

	fperms +x ${LIBRENMS_AGENT}/snmp/*
	fperms +x ${LIBRENMS_AGENT}/repo/*
}
