# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
PYTHON_COMPAT=( python3_{10..12} )
DISTUTILS_USE_PEP517=setuptools
inherit python-single-r1 tmpfiles

DESCRIPTION="Performance Co-Pilot, system performance and analysis framework"
HOMEPAGE="https://pcp.io"
if [[ ${PV} == 9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/performancecopilot/pcp.git"
else
	KEYWORDS="~amd64 ~x86"
	SRC_URI="https://github.com/performancecopilot/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
fi

LICENSE="LGPL-2.1+"
SLOT="0"
IUSE="activemq bind discovery doc infiniband influxdb json libvirt mysql nginx nutcracker perfevent pie podman postgres qt5 selinux snmp ssp +threads X xls"
DOC="CHANGELOG README.md INSTALL.md"

REQUIRED_USE="
	influxdb? ( ${PYTHON_REQUIRED_USE} )
	json? ( ${PYTHON_REQUIRED_USE} )
	libvirt? ( ${PYTHON_REQUIRED_USE} )
	postgres? ( ${PYTHON_REQUIRED_USE} )
	xls? ( ${PYTHON_REQUIRED_USE} )
"
BDEPEND="
	X? ( x11-libs/libXt )
	dev-libs/libuv
	discovery? ( net-dns/avahi[dbus] )
	doc? ( app-text/xmlto )
	qt5? ( dev-qt/qtsvg:5 )
	sys-apps/systemd
"

DEPEND="
	${PYTHON_DEPS}
	dev-libs/openssl:=
	activemq? ( dev-perl/libwww-perl )
	bind? ( dev-perl/libwww-perl dev-perl/XML-LibXML dev-perl/File-Slurp )
	influxdb? (
		$(python_gen_cond_dep '
			dev-python/requests[${PYTHON_USEDEP}]
		')
	)
	json? (
		$(python_gen_cond_dep '
			dev-python/jsonpointer[${PYTHON_USEDEP}]
			dev-python/six[${PYTHON_USEDEP}]
		')
	)
	libvirt? (
		$(python_gen_cond_dep '
			dev-python/libvirt-python[${PYTHON_USEDEP}]
			dev-python/lxml[${PYTHON_USEDEP}]
		')
	)
	mysql? ( dev-perl/DBD-mysql )
	nginx? ( dev-perl/libwww-perl )
	nutcracker? ( dev-perl/YAML-LibYAML virtual/perl-JSON-PP )
	perfevent? ( dev-libs/libpfm )
	podman? ( app-containers/podman )
	postgres? (
		$(python_gen_cond_dep '
			dev-python/psycopg:*[${PYTHON_USEDEP}]
		')
	)
	snmp? ( dev-perl/Net-SNMP )
	xls? (
		$(python_gen_cond_dep '
			dev-python/openpyxl[${PYTHON_USEDEP}]
		')
	)
"
RDEPEND="${DEPEND}
	acct-group/pcp
	acct-user/pcp
"

pkg_setup() {
	use influxdb || use json || use libvirt || use postgres || use xls && python-single-r1_pkg_setup
}

src_prepare() {
	default
	eapply_user
}

src_configure() {
	local myconf=(
		"--localstatedir=${EPREFIX}/var"
		"--with-sysconfigdir=${EPREFIX}/etc/conf.d"
		"--with-systemd"
		"--without-dstat-symlink"
		"--without-python"
		$(use_enable pie)
		$(use_enable ssp)
		$(use_with discovery)
		$(use_with infiniband)
		$(use_with json pmdajson)
		$(use_with nutcracker pmdanutcracker)
		$(use_with perfevent)
		$(use_with qt5 qt)
		$(use_with selinux)
		$(use_with snmp pmdasnmp)
		$(use_with threads)
		$(use_with X x)
	)

	econf "${myconf[@]}"
}

src_compile() {
	emake
}

src_install() {
	emake DIST_ROOT="${D}" install
	use influxdb || use json || use libvirt || use postgres || use xls && python_optimize

	rm -rf "${D}/var/lib/pcp/testsuite" || die
	rm -rf "${D}/var/log" || die
	rm -rf "${D}/run" || die

	dotmpfiles "${FILESDIR}"/${PN}.conf

	mv -vnT "${ED}"/usr/share/doc/pcp-doc/" ${ED}"/usr/share/doc/pcp/html || die
}

pkg_postinst() {
	tmpfiles_process pcp.conf

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
}
