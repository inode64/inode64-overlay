# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="This is the Cockpit user interface for sensors"
HOMEPAGE="https://github.com/ocristopfer/cockpit-sensors"
if [[ ${PV} == 9999* ]] ; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/ocristopfer/cockpit-sensors.git"
else
	KEYWORDS="~amd64 ~x86"
	SRC_URI="https://github.com/ocristopfer/${PN}/releases/download/v${PV}/cockpit-sensors.tar.xz -> ${P}.gh.tar.xz"
fi

LICENSE="LGPL-2.1"
SLOT="0"

RDEPEND="${DEPEND}
	app-admin/cockpit
	sys-apps/lm-sensors
"

S="${WORKDIR}/${PN}"

src_install() {
	emake DESTDIR="${D}" PREFIX="${EPREFIX}/usr" install
}
