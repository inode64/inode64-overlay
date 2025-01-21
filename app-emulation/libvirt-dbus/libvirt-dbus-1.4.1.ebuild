# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson

DESCRIPTION="DBus protocol binding for libvirt native C API"
HOMEPAGE="https://libvirt.org"
SRC_URI="https://download.libvirt.org/dbus/${P}.tar.xz"

LICENSE="LGPL-2+"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="${DEPEND}
	sys-apps/dbus
	sys-auth/polkit
	acct-user/libvirtdbus
"
BDEPEND="
	>=dev-libs/glib-2.44.0
	>=app-emulation/libvirt-3.0.0
	>=app-emulation/libvirt-glib-0.0.7
"
