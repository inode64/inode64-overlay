# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Manages the default slot of net-libs/nodejs"
HOMEPAGE="https://wiki.gentoo.org/wiki/No_homepage"
S="${WORKDIR}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm arm64 ~loong ppc64 ~riscv x86"

# The unslotted net-libs/nodejs installs /etc/env.d/50npm too, and this
# package is merged before the slot that blocks it.
RDEPEND="
	app-admin/eselect
	!!net-libs/nodejs:0
"

src_install() {
	insinto /usr/share/eselect/modules
	newins "${FILESDIR}"/nodejs.eselect-${PV} nodejs.eselect

	# Shared by every slot, so it cannot belong to any of them.
	keepdir /etc/npm
	echo "NPM_CONFIG_GLOBALCONFIG=${EPREFIX}/etc/npm/npmrc" > "${T}"/50npm || die
	doenvd "${T}"/50npm
}
