# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="A filesystem browser for Cockpit"
HOMEPAGE="https://cockpit-project.org/"
if [[ ${PV} == 9999* ]] ; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/cockpit-project/cockpit-files.git"
else
	KEYWORDS="~amd64 ~x86"
	SRC_URI="https://github.com/cockpit-project/${PN}/releases/download/${PV}/${P}.tar.xz"
fi

S="${WORKDIR}/${PN}"
LICENSE="LGPL-2.1"
SLOT="0"

RDEPEND="
	>=app-admin/cockpit-318
"

src_install() {
	emake DESTDIR="${D}" PREFIX="${EPREFIX}/usr" install
}
