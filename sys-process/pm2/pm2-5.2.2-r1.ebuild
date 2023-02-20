# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit nodejs systemd

DESCRIPTION="Process manager for Node.js applications with a built-in load balancer"
HOMEPAGE="https://pm2.keymetrics.io/"
SRC_URI="https://github.com/Unitech/pm2/archive/${PV}.tar.gz -> ${P}.tar.gz
    		https://raw.githubusercontent.com/inode64/inode64-overlay/main/dist/${P}-node_modules.tar.xz"

LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	net-libs/nodejs:=
"

src_install() {
    enpm_clean
	enpm_install

	doinitd "${FILESDIR}"/${PN}
	systemd_dounit "${FILESDIR}/${PN}.service"
}
