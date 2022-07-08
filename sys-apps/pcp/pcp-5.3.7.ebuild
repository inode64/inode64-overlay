# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
PYTHON_COMPAT=(python3_{7..10})
inherit systemd distutils-r1

DESCRIPTION="Performance Co-Pilot, system performance and analysis framework"
HOMEPAGE="http://pcp.io"

if [[ ${PV} == 9999* ]]; then
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
IUSE="activemq bind discovery doc infiniband influxdb json libvirt mysql nginx nutcracker perfevent +pie podman postgresql qt5 selinux snmp +ssp systemd +threads X xls"
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
	activemq?  ( dev-perl/perl-libwww )
	bind? ( dev-perl/perl-libwww dev-perl/XML-LibXML dev-perl/File-Slurp )
	influxdb? ( dev-python/requests[${PYTHON_USEDEP}] )
	json? ( dev-python/jsonpointer[${PYTHON_USEDEP}] dev-python/six[${PYTHON_USEDEP}] )
	libvirt? ( dev-python/libvirt-python[${PYTHON_USEDEP}] dev-python/lxml[${PYTHON_USEDEP}] )
	mysql? ( dev-perl/DBD-mysql )
	nginx? ( dev-perl/perl-libwww )
	nutcracker? ( dev-perl/YAML-LibYAML virtual/perl-JSON-PP )
	perfevent? ( dev-libs/libpfm )
	podman? ( dev-libs/libvarlink )
	postgresql? ( dev-python/psycopg[${PYTHON_USEDEP}] )
	snmp? ( dev-perl/Net-SNMP )
	xls? ( dev-python/openpyxl[${PYTHON_USEDEP}] )
"
RDEPEND="${DEPEND}
	acct-group/pcp
	acct-user/pcp
"

src_prepare() {
	eapply_user
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
	DIST_ROOT="${D}" emake install

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