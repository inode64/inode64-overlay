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
	KEYWORDS="~amd64 ~x86"
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
# pgpool2 ships its own libpcp (the pgpool Communication Protocol library),
# so both packages install /usr/lib64/libpcp.so. https://bugs.gentoo.org/925483
RDEPEND="${DEPEND}
	!dev-db/pgpool2
	acct-user/pcp
"

PATCHES=(
	# Polling filesys.* keeps autofs mounts (USB backup disks) from expiring
	"${FILESDIR}/${PN}-7.1.5-filesys-automounts.patch"
)

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

	# configure compresses the man pages like those it finds on the build
	# host and names their links after it, so the result depends on the
	# host; leave the pages to ecompress
	sed -i -E 's/^(HAVE_(GZIPP|BZIP2|LZMA|XZ)ED_MANPAGES =).*/\1 false/' \
		src/include/builddefs || die
}

src_compile() {
	emake
}

src_install() {
	emake DIST_ROOT="${ED}" install
	python_optimize

	find "${ED}" -type f -name '*.la' -delete || die
	find "${ED}" -type f -name '*.a' -delete || die
	# Some links still get the .gz of MANPAGE_SUFFIX: without it ecompress
	# retargets them to the compressed pages instead of leaving them dangling
	local link target
	while IFS= read -r -d '' link; do
		target=$(readlink "${link}") || die
		rm "${link}" || die
		ln -s "${target%.gz}" "${link%.gz}" || die
	done < <(find "${ED}"/usr/share/man -type l -name '*.gz' -print0)

	# 7.2 makes pcp-atop a drop-in atop: commands, units and man pages
	# collide with sys-process/atop. Keep it as pcp-atop and pcp atop.
	rm "${ED}"/usr/bin/{atop,atopsar} \
		"${ED}"/usr/lib/systemd/system/atop{,-daily}.service \
		"${ED}"/usr/lib/systemd/system/atop-daily.timer \
		"${ED}"/usr/libexec/pcp/bin/atop-daily \
		"${ED}"/etc/conf.d/atop \
		"${ED}"/usr/share/man/man1/atop-daily.1 || die
	local page
	for page in atop atopsar; do
		mv -f "${ED}"/usr/share/man/man1/{${page},pcp-${page}}.1 || die
	done

	dotmpfiles "${FILESDIR}"/${PN}.conf
	mv -vnT "${ED}"/usr/share/doc/pcp-doc/html "${ED}/usr/share/doc/pcp-${PVR}/html" || die

	rm -rf "${ED}"/var/lib/pcp/testsuite || die
	rm -r "${ED}"/var/lib/pcp/pmcd || die
	rm -r "${ED}"/var/lib/pcp/config/{pmchart,pmda,pmie} || die
	rm -rf "${ED}"/var/lib/pcp/tmp || die
	rm -r "${ED}"/usr/share/doc/pcp-doc || die
	rm -rf "${ED}"/var/log || die
	rm -rf "${ED}"/run || die

	# pmdaopentelemetry fails at startup when its config.d is missing
	keepdir /var/lib/pcp/pmdas/opentelemetry/config.d
}

pkg_postinst() {
	# Both files, as at boot: processing ours alone used to leave pmcd's log
	# directory and config/ with the ownership upstream's file reverts on the
	# next reboot.
	tmpfiles_process pcp-reboot-init.conf pcp.conf libpcp_import.conf

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
