# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

DESCRIPTION="Process manager for Node.js applications with a built-in load balancer"
HOMEPAGE="https://pm2.keymetrics.io/"
SRC_URI="https://github.com/Unitech/pm2/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"

RDEPEND="
	net-libs/nodejs:=
"
DEPEND="
	${RDEPEND}
	test? ( net-libs/nodejs[debug] )
"
BDEPEND="
	net-libs/nodejs[npm]
"

# To enable download packages
RESTRICT="network-sandbox !test? ( test )"

NPM_FLAGS=(
        --audit false
        --color false
        --foreground-scripts
        --global
        --progress false
        --save false
        --verbose
)

src_compile() {
	npm "${NPM_FLAGS[@]}" pack || die
}

src_test() {
	npm test
}

src_install() {
	npm "${NPM_FLAGS[@]}" \
		--prefix "${ED}"/usr \
		install pm2-${PV}.tgz|| die "npm install failed"

	dodoc *.md

	doinitd "${FILESDIR}"/${PN}
	systemd_dounit "${FILESDIR}/${PN}.service"
}
