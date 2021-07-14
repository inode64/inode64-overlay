# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit systemd

DESCRIPTION="Process manager for Node.js applications with a built-in load balancer"
HOMEPAGE="https://pm2.keymetrics.io/"
SRC_URI="https://github.com/Unitech/pm2/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="~amd64"

DEPEND=""
RDEPEND="
	net-libs/nodejs
"
BDEPEND="
	net-libs/nodejs[npm]
"

# To enable download packages
RESTRICT="network-sandbox"

src_compile() {
	# nothing to compile here
	:
}

src_install() {
	npm \
                --color false \
                --prefix "${ED}"/usr \
                --progress false \
                --verbose \
		install -g || die "npm install failed"

	# remove the link to /var/tmp/portage/...
	rm "${ED}"/usr/$(get_libdir)/node_modules/${PN} || die

	insinto /usr/$(get_libdir)/node_modules/${PN}
	doins -r bin lib node_modules pres
	doins *.js *.json
	fperms +x /usr/$(get_libdir)/node_modules/${PN}/bin/{pm2,pm2-dev,pm2-docker,pm2-runtime}

	dodoc *.md
}
