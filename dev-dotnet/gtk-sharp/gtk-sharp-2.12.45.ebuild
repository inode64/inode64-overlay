# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit dotnet

DESCRIPTION="gtk2 bindings for C#"
HOMEPAGE="https://www.mono-project.com/docs/gui/gtksharp/"
SRC_URI="https://download.mono-project.com/sources/gtk-sharp212/${P}.tar.gz"
LICENSE="GPL-2"

SLOT="2"
KEYWORDS="~amd64"
IUSE="debug glade"
RESTRICT="test"

RDEPEND="
	x11-libs/gtk+:2
	glade? ( dev-util/glade )
"

DEPEND="${RDEPEND}
"

PATCHES=( "${FILESDIR}/gtk-sharp2-2.12.12-gtkrange.patch" )

src_configure() {
	econf \
		--disable-static \
		--disable-dependency-tracking \
		--disable-maintainer-mode \
		$(use_enable debug)
}

src_install() {
	default
	find "${D}" -name '*.la' -delete || die
}
