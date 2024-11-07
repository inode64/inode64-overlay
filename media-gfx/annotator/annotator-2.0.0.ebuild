# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit gnome.org gnome2-utils meson vala xdg

DESCRIPTION="Image annotation for Elementary OS"
HOMEPAGE="https://github.com/phase1geo/Annotator"
SRC_URI="https://github.com/phase1geo/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}/Annotator-${PV}"
LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"

DEPEND="
	dev-libs/libgee
	dev-libs/granite
	>=x11-libs/gtk+-3.22:3
	>=gui-libs/libhandy-1.6.0:1
"
RDEPEND="${DEPEND}
	x11-misc/xdg-utils
"
BDEPEND="
	$(vala_depend)
	dev-libs/libxml2:2
	virtual/pkgconfig
	gui-libs/libhandy:1[vala]
"

src_configure() {
	export VALAC="$(type -P valac-$(vala_best_api_version))"
	meson_src_configure
}

pkg_postinst() {
	xdg_pkg_postinst
	gnome2_schemas_update
}

pkg_postrm() {
	xdg_pkg_postrm
	gnome2_schemas_update
}
