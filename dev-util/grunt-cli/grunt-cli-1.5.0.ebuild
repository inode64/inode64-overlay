# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit nodejs-mod

DESCRIPTION="The Grunt command line interface."
HOMEPAGE="https://github.com/gruntjs/grunt-cli"
SRC_URI="https://github.com/gruntjs/${PN}/archive/refs/tags/v${PV}.tar.gz  -> ${P}.tar.gz
		https://raw.githubusercontent.com/inode64/inode64-overlay/main/dist/${P}-node_modules.tar.xz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="net-libs/nodejs"
