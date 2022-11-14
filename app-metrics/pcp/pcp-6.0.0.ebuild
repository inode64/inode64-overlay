# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
PYTHON_COMPAT=(python3_{8..11})
inherit distutils-r1

DESCRIPTION="Performance Co-Pilot, system performance and analysis framework"
HOMEPAGE="https://pcp.io"if [[ ${PV} == 9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/performancecopilot/pcp.git"
	KEYWORDS=""
	SRC_URI=""
else
	KEYWORDS="~amd64 ~x86"
	SRC_URI="https://github.com/performancecopilot/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
fi

LICENSE="LGPL-2.1+"
SLOT="0"
IUSE="activemq bind discovery doc infiniband influxdb json libvirt mysql nginx nutcracker perfevent pie podman postgres qt5 selinux snmp ssp systemd +threads X xls"
DOC="CHANGELOG README.md INSTALL.md"

BDEPEND="
	discovery? ( net-dns/avahi[dbus] )
	doc? ( app-text/xmlto )
	qt5? ( dev-qt/qtsvg:5 )
	systemd? ( sys-apps/systemd )
	X? ( x11-libs/libXt )
	dev-libs/libuv
"

DEPEND="
	activemq?  ( dev-perl/libwww-perl )
	bind? ( dev-perl/libwww-perl dev-perl/XML-LibXML dev-perl/File-Slurp )
	influxdb? ( dev-python/requests[${PYTHON_USEDEP}] )
	json? ( dev-python/jsonpointer[${PYTHON_USEDEP}] dev-python/six[${PYTHON_USEDEP}] )
	libvirt? ( dev-python/libvirt-python[${PYTHON_USEDEP}] dev-python/lxml[${PYTHON_USEDEP}] )
	mysql? ( dev-perl/DBD-mysql )
	nginx? ( dev-perl/libwww-perl )
	nutcracker? ( dev-perl/YAML-LibYAML virtual/perl-JSON-PP )
	perfevent? ( dev-libs/libpfm )
	podman? ( dev-libs/libvarlink )
	postgres? ( dev-python/psycopg:*[${PYTHON_USEDEP}] )
	snmp? ( dev-perl/Net-SNMP )
	xls? ( dev-python/openpyxl[${PYTHON_USEDEP}] )
"
RDEPEND="${DEPEND}
	acct-group/pcp
	acct-user/pcp
"

src_prepare() {
	eapply_user

	# gentooify systemd services
	sed \
	-e 's:sysconfig/:conf.d/:g' \
	-e 's:@PCP_SYSCONFIG_DIR@:/etc/conf.d:g' \
	-i "${S}"/*/*/*.service.in || die
}

src_configure() {
	local myconf=(
		"--localstatedir=${EPREFIX}/var"
		"--without-dstat-symlink"
		"--without-python"
		$(use_enable pie)
		$(use_enable ssp)
		$(use_with discovery)
		$(use_with infiniband)
		$(use_with json pmdajson)
		$(use_with nutcracker pmdanutcracker)
		$(use_with perfevent)
		$(use_with podman pmdapodman)
		$(use_with qt5 qt)
		$(use_with selinux)
		$(use_with snmp pmdasnmp)
		$(use_with systemd)
		$(use_with threads)
		$(use_with X x)
	)

	econf "${myconf[@]}"
}

src_compile() {
	emake
}

src_install() {
	emake DIST_ROOT="${D}" PCP_SYSCONFIG_DIR=/etc/conf.d install

	rm -rf "${D}/var/lib/pcp/testsuite"
}

pkg_postinst() {
	if use systemd; then
		elog ""
		elog "To install basic PCP tools and services and enable collecting performance data on systemd based distributions, run:"
		elog " - systemctl enable --now pmcd pmlogger"
		elog ""
		elog "To install pmfind to begin monitoring discovered metric sources, run:"
		elog " - systemctl enable --now pmfind"
		elog ""
		elog "To enable and start PMIE:"
		elog " - systemctl enable --now pmie"
		elog ""
		elog "To enable and start metrics series collection:"
		elog "- systemctl enable --now pmlogger pmproxy redis"
		elog ""
	fi
}
