# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit desktop unpacker xdg

DESCRIPTION="ITACA administrative management of centers"
HOMEPAGE="https://ceice.gva.es/webitaca/es/index.asp"
SRC_URI="https://lliurex.net/focal/pool/main/i/itaca/${PN}_${PV}_amd64.deb"

S="${WORKDIR}"
LICENSE="Itaca"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror strip"

RDEPEND="
		app-accessibility/at-spi2-core
		dev-libs/nss
		gnome-base/gvfs
		media-libs/mesa
		x11-libs/gtk+:3
		x11-libs/libXtst
		x11-libs/libdrm
		x11-libs/libnotify
		x11-libs/libxcb
"

src_install() {
	insinto /usr/$(get_libdir)
	doins -r usr/lib/itaca

	fperms 0755 /usr/$(get_libdir)/itaca/{ITACA,chrome-sandbox,libEGL.so,libGLESv2.so,libffmpeg.so,libvk_swiftshader.so,libvulkan.so}
	fperms 0755 /usr/$(get_libdir)/itaca/swiftshader/{libEGL.so,libGLESv2.so}

	dosym -r /usr/$(get_libdir)/itaca/ITACA /usr/bin/itaca || die

	newmenu usr/share/applications/itaca.desktop itaca.desktop

	newicon -s 512 usr/share/pixmaps/itaca.png itaca.png
}

pkg_preinst() {
	xdg_pkg_preinst
}

pkg_postinst() {
	xdg_pkg_postinst
}

pkg_postrm() {
	xdg_pkg_postrm
}
