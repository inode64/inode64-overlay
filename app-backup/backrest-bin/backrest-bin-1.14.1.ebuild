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
  !app-backup/backrest
"

src_install() {
	dobin backrest
	dodoc *.md

	dotmpfiles "${FILESDIR}/backrest.tmpfiles.conf"
	newinitd "${FILESDIR}/backrest.initd" backrest
	systemd_dounit "${FILESDIR}/backrest.service"
}

pkg_postinst() {
	tmpfiles_process backrest.tmpfiles.conf
}
