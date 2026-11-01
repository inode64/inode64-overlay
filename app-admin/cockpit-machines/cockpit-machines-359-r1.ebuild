# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="This is the Cockpit user interface for virtual machines"
HOMEPAGE="https://cockpit-project.org/"
if [[ ${PV} == 9999* ]] ; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/cockpit-project/cockpit-machines.git"
else
	KEYWORDS="~amd64 ~x86"
	SRC_URI="https://github.com/cockpit-project/${PN}/releases/download/${PV}/${P}.tar.xz"
fi

S="${WORKDIR}/${PN}"
LICENSE="LGPL-2.1"
SLOT="0"

BDEPEND="
	sys-devel/gettext
"

# cockpit-machines and cockpit are versioned independently; upstream asks for
# cockpit-bridge >= 215. getOSList.py loads Libosinfo through GObject.
RDEPEND="
	>=app-admin/cockpit-215
	app-emulation/libvirt-dbus
	app-emulation/libvirt[firewalld,policykit]
	app-emulation/qemu[usbredir]
	app-emulation/virt-manager[policykit]
"

src_install() {
	emake DESTDIR="${D}" PREFIX="${EPREFIX}/usr" install
}
