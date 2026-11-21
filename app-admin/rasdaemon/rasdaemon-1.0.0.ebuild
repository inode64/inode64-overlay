# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..15} )
PYTHON_REQ_USE="sqlite"

inherit flag-o-matic linux-info meson python-single-r1 systemd

DESCRIPTION="Reliability, Availability and Serviceability logging tool"
HOMEPAGE="https://github.com/mchehab/rasdaemon"
SRC_URI="https://github.com/mchehab/rasdaemon/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE="selinux test"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"
RESTRICT="!test? ( test )"

DEPEND="
	dev-db/sqlite
	dev-libs/libtraceevent
	>=sys-apps/pciutils-3.10.0
	elibc_musl? ( sys-libs/argp-standalone )
	test? ( dev-util/cmocka )
"
RDEPEND="
	${PYTHON_DEPS}
	dev-db/sqlite
	dev-libs/libtraceevent
	>=sys-apps/pciutils-3.10.0
	$(python_gen_cond_dep '
		dev-python/sqlalchemy[sqlite,${PYTHON_USEDEP}]
	')
	sys-apps/dmidecode
	selinux? ( sec-policy/selinux-rasdaemon )
"
BDEPEND="
	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		dev-python/sqlalchemy[sqlite,${PYTHON_USEDEP}]
	')
"

PATCHES=(
	"${FILESDIR}/${P}-meson-install.patch"
	"${FILESDIR}/${P}-services.patch"
)

pkg_setup() {
	python-single-r1_pkg_setup
	linux-info_pkg_setup
	local CONFIG_CHECK="~RAS ~TRACING"
	check_extra_config
}

src_prepare() {
	default
	python_fix_shebang util/ras-mc-ctl.py
}

src_configure() {
	use elibc_musl && append-libs -largp

	local emesonargs=(
		--localstatedir="${EPREFIX}/var"
		-Denable-arch=auto
		-Daer=enabled
		-Dpcie-edpc=enabled
		-Dsqlite3=enabled
		-Dmysql=disabled
		-Dpostgresql=disabled
		-Ddocs=disabled
		-Dsystemd-unit-dir="$(systemd_get_systemunitdir)"
		-Dsqlite3-database="${EPREFIX}/var/lib/${PN}/ras-mc_event.db"
		$(meson_feature test tests)
	)
	meson_src_configure
}

src_install() {
	meson_src_install
	python_optimize "${ED}/usr/share/${PN}"
	keepdir "/var/lib/${PN}"

	newinitd "${FILESDIR}/rasdaemon.openrc" rasdaemon
	newinitd "${FILESDIR}/ras-mc-ctl.openrc" ras-mc-ctl
	newconfd "${FILESDIR}/rasdaemon.confd" rasdaemon
}

pkg_postinst() {
	elog "ras-mc-ctl 1.0 uses subcommands: dimm --register-labels,"
	elog "database --summary and database --errors. See ras-mc-ctl --help."
	elog "Daemon settings are in /etc/sysconfig/rasdaemon."
	elog "The service mounts tracefs at /sys/kernel/tracing."
	elog "Keep debugfs available for ACPI EXTLOG events (ras/daemon_active)."
}
