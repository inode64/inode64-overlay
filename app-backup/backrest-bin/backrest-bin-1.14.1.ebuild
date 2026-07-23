# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd tmpfiles

DESCRIPTION="A web UI and orchestrator for restic backup"
HOMEPAGE="https://github.com/garethgeorge/backrest"
SRC_URI="https://github.com/garethgeorge/backrest/releases/download/v${PV}/backrest_Linux_x86_64.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
RDEPEND="
  app-backup/restic
  !app-backupt/backrest
"

src_install() {
	dobin backrest
	dodoc *.md

	dotmpfiles "${FILESDIR}/${PN}.tmpfiles.conf"
	newinitd "${FILESDIR}/${PN}.initd" ${PN}
	systemd_dounit "${FILESDIR}/${PN}.service"
}

pkg_postinst() {
	tmpfiles_process backrest.tmpfiles.conf
}
