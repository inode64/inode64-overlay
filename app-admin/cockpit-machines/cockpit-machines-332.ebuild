# Copyright 1999-2025 Gentoo Authors
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
	sys-libs/libosinfo
"

RDEPEND="${DEPEND}
	>=app-admin/cockpit-${PV}
	app-emulation/libvirt-dbus
	app-emulation/libvirt[firewalld,policykit]
	app-emulation/qemu[usbredir]
	app-emulation/virt-manager[policykit]
"

src_install() {
	emake DESTDIR="${D}" PREFIX="${EPREFIX}/usr" install
}
