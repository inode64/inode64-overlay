# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit nodejs-mod systemd

DESCRIPTION="Process manager for Node.js applications with a built-in load balancer"
HOMEPAGE="https://pm2.keymetrics.io/"
SRC_URI="
	https://github.com/Unitech/pm2/archive/v${PV}.tar.gz -> ${P}.tar.gz
	https://www.inode64.com/dist/${P}-node_modules.tar.xz
"

LICENSE="AGPL-3 Apache-2.0 BSD-2 ISC MIT public-domain"
SLOT="0"
KEYWORDS=""

NODEJS_EXTRA_FILES="bin constants.js index.js modules paths.js"

RDEPEND="net-libs/nodejs"

src_install() {
	nodejs-mod_src_install

	doinitd "${FILESDIR}"/${PN}
	systemd_douserunit "${FILESDIR}/${PN}.service"
}

pkg_postinst() {
	elog "Save your application list as its owner with: pm2 save"
	elog "Then enable the user service: systemctl --user enable --now pm2.service"
	elog "For startup at boot without logging in: loginctl enable-linger USER"
	elog "When upgrading, disable the old system pm2.service before starting the user service."
}
