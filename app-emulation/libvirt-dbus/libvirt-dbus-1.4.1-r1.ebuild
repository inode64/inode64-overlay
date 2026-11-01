# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson

DESCRIPTION="DBus protocol binding for libvirt native C API"
HOMEPAGE="https://libvirt.org/dbus.html"
SRC_URI="https://gitlab.com/libvirt/${PN}/-/archive/v${PV}/${PN}-v${PV}.tar.bz2 -> ${P}.tar.bz2"
S="${WORKDIR}/${PN}-v${PV}"

LICENSE="LGPL-2+"
SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="systemd"

DEPEND="
	>=app-emulation/libvirt-3.0.0:=
	>=app-emulation/libvirt-glib-0.0.7
	systemd? ( sys-apps/systemd )
"
RDEPEND="${DEPEND}
	acct-user/libvirtdbus
	sys-auth/polkit
"
BDEPEND="
	dev-python/docutils
"

src_configure() {
	local emesonargs=(
		-Dinit_script=$(usex systemd systemd other)
	)
	meson_src_configure
}
