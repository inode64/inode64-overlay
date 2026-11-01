# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-mod-r1 git-r3 toolchain-funcs

DESCRIPTION="Kernel driver for AMD Ryzen's System Management Unit"
HOMEPAGE="https://github.com/amkillam/ryzen_smu"
EGIT_REPO_URI="https://github.com/amkillam/ryzen_smu.git"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

src_compile() {
	local modlist=( ryzen_smu )
	local modargs=( KERNEL_BUILD="${KV_OUT_DIR}" )

	linux-mod-r1_src_compile

	# The upstream Makefile forces -march=native, which breaks binary packages
	# built on another host, and strips the result
	set -- $(tc-getCC) ${CPPFLAGS} ${CFLAGS} ${LDFLAGS} -Ilib \
		-o userspace/monitor_cpu userspace/monitor_cpu.c lib/libsmu.c -lm
	echo "$@"
	"$@" || die "building monitor_cpu failed"
}

src_install() {
	linux-mod-r1_src_install

	insinto /usr/lib/modules-load.d
	doins "${FILESDIR}"/ryzen_smu.conf

	dobin userspace/monitor_cpu
}
