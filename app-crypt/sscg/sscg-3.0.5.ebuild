# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson

if [[ ${PV} == *9999 ]] ; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/sgallagher/sscg.git"
else
	SRC_URI="https://github.com/sgallagher/${PN}/archive/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

DESCRIPTION="Simple Signed Certificate Generator"
HOMEPAGE="https://github.com/sgallagher/sscg"

LICENSE="GPL-3"
SLOT="0"
S="${WORKDIR}/${PN}-${P}"

RDEPEND="
	sys-libs/talloc
	dev-libs/ding-libs
	>=dev-libs/popt-1.14
	>=dev-libs/openssl-1.1.0:=
"
BDEPEND="
	sys-apps/help2man
"

src_configure() {
	local emesonargs=(
		--buildtype plain
	)
	meson_src_configure
}

DOCS=( README.md )
