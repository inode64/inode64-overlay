# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit nodejs-mod systemd

DESCRIPTION="Process manager for Node.js applications with a built-in load balancer"
HOMEPAGE="https://pm2.keymetrics.io/"
SRC_URI="
	https://github.com/Unitech/pm2/archive/v${PV}.tar.gz -> ${P}.tar.gz
	https://raw.githubusercontent.com/inode64/inode64-overlay/main/dist/${P}-node_modules.tar.xz
"

LICENSE="AGPL-3 Apache-2.0 BSD-2 ISC MIT public-domain"
SLOT="0"
KEYWORDS="~amd64"

NODEJS_EXTRA_FILES="bin constants.js index.js paths.js"

RDEPEND="net-libs/nodejs"

src_install() {
	nodejs-mod_src_install

	doinitd "${FILESDIR}"/${PN}
	systemd_dounit "${FILESDIR}/${PN}.service"
}
