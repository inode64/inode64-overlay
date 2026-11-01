# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
PYTHON_COMPAT=( python3_{11..14} )
DISTUTILS_USE_PEP517=setuptools
inherit python-single-r1 tmpfiles

DESCRIPTION="Performance Co-Pilot, system performance and analysis framework"
HOMEPAGE="https://pcp.io"

if [[ ${PV} == 9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/performancecopilot/pcp.git"
else
	KEYWORDS=""
	SRC_URI="https://github.com/performancecopilot/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
fi

LICENSE="LGPL-2.1+"
SLOT="0"
IUSE="activemq bind doc infiniband influxdb json libvirt mysql nginx nutcracker perfevent pie podman postgres qt6 selinux snmp ssp +threads X xls"
DOC="CHANGELOG README.md INSTALL.md"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"
BDEPEND="
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig
	doc? ( app-text/xmlto )
"

DEPEND="
	${PYTHON_DEPS}
	app-arch/xz-utils
	dev-db/sqlite:3
	dev-lang/perl:=
	dev-libs/inih
	dev-libs/libuv:=
	dev-libs/openssl:=
	sys-apps/systemd:=
	sys-libs/ncurses:=
	sys-libs/readline:=
	virtual/libelf:=
	virtual/zlib:=
	X? ( x11-libs/libXt )
	qt6? (
		dev-qt/qtbase:6[network,widgets]
		dev-qt/qtsvg:6
	)
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
	acct-user/pcp
	!sys-process/atop
	!sys-process/htop
	!sys-apps/dstat
"

src_prepare() {
	default
	eapply_user

	# pmview.ui wires its actions to custom slots of the top-level window.
	# Qt6 uic generates pointer-to-member connections by default, which
	# resolve against QMainWindow and fail ('optionsMenubar' is not a member
	# of 'QMainWindow'). Fall back to the string based SIGNAL/SLOT syntax.
	# pmview is disabled below (--without-qt3d); kept so it builds if enabled.
	# https://github.com/inode64/inode64-overlay/issues/34
	echo 'QMAKE_UIC_FLAGS += -connections string' >> src/pmview/pmview.pro || die
}

src_configure() {
	local myconf=(
		"--localstatedir=${EPREFIX}/var"
		"--with-sysconfigdir=${EPREFIX}/etc/conf.d"
		"--with-systemd"
		"--without-dstat-symlink"
		"--with-python3"
		$(use_enable pie)
		$(use_enable ssp)
		$(use_with infiniband)
		$(use_with nutcracker pmdanutcracker)
		$(use_with perfevent)
		$(use_with qt6 qt)
		# pmview (developer preview) needs Coin3/SoQt, which is not packaged;
		# do not let configure pick it up automagically
		--without-qt3d
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
	emake DIST_ROOT="${ED}" install
	python_optimize

	find "${ED}" -type f -name '*.la' -delete || die
	find "${ED}" -type f -name '*.a' -delete || die
	find "${ED}/usr/share/man" -type f -name "*.bz2" -exec bunzip2 {} + || die

	dotmpfiles "${FILESDIR}"/${PN}.conf
	mv -vnT "${ED}"/usr/share/doc/pcp-doc/html "${ED}/usr/share/doc/pcp-${PVR}/html" || die

	rm -rf "${ED}"/var/lib/pcp/testsuite || die
	rm -r "${ED}"/var/lib/pcp/pmcd || die
	rm -r "${ED}"/var/lib/pcp/config/{pmchart,pmda,pmie} || die
	rm -rf "${ED}"/var/lib/pcp/tmp || die
	rm -r "${ED}"/usr/share/doc/pcp-doc || die
	rm -rf "${ED}"/var/log || die
	rm -rf "${ED}"/run || die
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
