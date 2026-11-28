# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..15} )
PYTHON_REQ_USE="sqlite"

inherit flag-o-matic git-r3 linux-info meson python-single-r1

DESCRIPTION="Reliability, Availability and Serviceability logging tool"
HOMEPAGE="https://github.com/mchehab/rasdaemon"
EGIT_REPO_URI="https://github.com/mchehab/rasdaemon.git"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""

# Meson feature options exposed as RASDAEMON_FEATURES. The ARM and RISC-V
# ones and cpu-fault-isolation (it only consumes ARM and RISC-V events) do
# nothing on the architectures in KEYWORDS.
RASDAEMON_DEFAULT_FEATURES=(
	aer devlink diskerror erst extlog mce memory-ce-pfa memory-failure
	memory-row-ce-pfa pcie-edpc
)
# Off by default: ABRT is not packaged in Gentoo, upstream marks the generic BMC
# reporter and the signal event as experimental, the signal event records
# unrelated signals while the service starts, and without CXL devices the cxl
# handler only logs a missing tracepoint for each of its events at startup.
RASDAEMON_OPTIONAL_FEATURES=( abrt-report bmc-generic cxl signal )
IUSE="
	${RASDAEMON_DEFAULT_FEATURES[@]/#/+rasdaemon_features_}
	${RASDAEMON_OPTIONAL_FEATURES[@]/#/rasdaemon_features_}
	selinux test
"
REQUIRED_USE="
	${PYTHON_REQUIRED_USE}
	rasdaemon_features_bmc-generic? ( rasdaemon_features_aer )
	rasdaemon_features_erst? ( rasdaemon_features_mce )
	rasdaemon_features_pcie-edpc? ( rasdaemon_features_aer )
"
RESTRICT="!test? ( test )"

DEPEND="
	dev-db/sqlite
	dev-libs/libtraceevent
	elibc_musl? ( sys-libs/argp-standalone )
	rasdaemon_features_aer? ( >=sys-apps/pciutils-3.10.0 )
	test? ( dev-util/cmocka )
"
RDEPEND="
	${PYTHON_DEPS}
	dev-db/sqlite
	dev-libs/libtraceevent
	$(python_gen_cond_dep '
		dev-python/sqlalchemy[sqlite,${PYTHON_USEDEP}]
	')
	sys-apps/dmidecode
	rasdaemon_features_aer? ( >=sys-apps/pciutils-3.10.0 )
	rasdaemon_features_bmc-generic? ( sys-apps/ipmitool )
	selinux? ( sec-policy/selinux-rasdaemon )
"
BDEPEND="
	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		dev-python/sqlalchemy[sqlite,${PYTHON_USEDEP}]
	')
"

# A board without DIMM labels makes ras-mc-ctl.service fail at every boot;
# proposed in https://github.com/mchehab/rasdaemon/pull/277. Shared with 1.0.1.
PATCHES=(
	"${FILESDIR}/${PN}-1.0.0-ras-mc-ctl-no-labels.patch"
)

pkg_setup() {
	python-single-r1_pkg_setup
	linux-info_pkg_setup
	local CONFIG_CHECK="~RAS ~TRACING"
	use rasdaemon_features_aer && CONFIG_CHECK+=" ~PCIEAER"
	use rasdaemon_features_bmc-generic && CONFIG_CHECK+=" ~IPMI_SI ~IPMI_DEVICE_INTERFACE"
	use rasdaemon_features_cxl && CONFIG_CHECK+=" ~CXL_BUS"
	use rasdaemon_features_devlink && CONFIG_CHECK+=" ~NET_DEVLINK"
	use rasdaemon_features_erst && CONFIG_CHECK+=" ~ACPI_APEI ~PSTORE"
	use rasdaemon_features_extlog && CONFIG_CHECK+=" ~ACPI_EXTLOG ~DEBUG_FS"
	use rasdaemon_features_mce && CONFIG_CHECK+=" ~X86_MCE"
	use rasdaemon_features_pcie-edpc && CONFIG_CHECK+=" ~PCIE_DPC"
	if use rasdaemon_features_memory-ce-pfa || use rasdaemon_features_memory-row-ce-pfa; then
		CONFIG_CHECK+=" ~MEMORY_FAILURE ~MEMORY_HOTPLUG"
	elif use rasdaemon_features_memory-failure; then
		CONFIG_CHECK+=" ~MEMORY_FAILURE"
	fi
	# TRACING has no prompt in menuconfig, so name the options that select it.
	local WARNING_TRACING="CONFIG_TRACING is not set: rasdaemon reads every event from tracefs and exits without it. Enable CONFIG_FTRACE and CONFIG_ENABLE_DEFAULT_TRACERS, which select it."
	local WARNING_DEBUG_FS="CONFIG_DEBUG_FS is not set: ACPI EXTLOG needs debugfs ras/daemon_active."
	local WARNING_MEMORY_HOTPLUG="CONFIG_MEMORY_HOTPLUG is not set: page and row offlining need its sysfs files."
	check_extra_config
}

src_prepare() {
	default
	python_fix_shebang util/ras-mc-ctl.py
}

src_configure() {
	use elibc_musl && append-libs -largp

	# Every feature without a USE flag stays off, including new ones a version
	# bump brings, instead of being built because it has no dependencies.
	local emesonargs=(
		--localstatedir="${EPREFIX}/var"
		-Dauto_features=disabled
		-Denable-arch=auto
		-Dsqlite3=enabled
		-Dmysql=disabled
		-Dpostgresql=disabled
		-Ddocs=false
		-Dsqlite3-database="${EPREFIX}/var/lib/${PN}/ras-mc_event.db"
		$(meson_use test tests)
	)
	local feature
	for feature in "${RASDAEMON_DEFAULT_FEATURES[@]}" "${RASDAEMON_OPTIONAL_FEATURES[@]}"; do
		emesonargs+=( $(meson_feature "rasdaemon_features_${feature}" "${feature}") )
	done
	meson_src_configure
}

src_install() {
	meson_src_install
	python_optimize "${ED}/usr/share/${PN}"
	# The syslog-ng snippet logs from a source named s_sys, which Gentoo's
	# syslog-ng.conf does not define, and that file does not include conf.d.
	rm -r "${ED}/etc/syslog-ng" || die
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
	if use rasdaemon_features_extlog; then
		elog "Keep debugfs available for ACPI EXTLOG events (ras/daemon_active)."
	fi
}
