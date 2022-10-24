# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module systemd

DESCRIPTION="High-performance HTTP server that implements restic's REST backend API"
HOMEPAGE="https://github.com/restic/rest-server"

SRC_URI="https://github.com/restic/rest-server/archive/v${PV}.tar.gz -> ${P}.tar.gz
	https://raw.githubusercontent.com/inode64/inode64-overlay/main/dist/${P}-vendor.tar.xz"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="app-admin/apache-tools"
DEPEND=""

src_prepare() {
	sed -i -e 's|/usr/local/bin/rest-server|/usr/bin/rest-server|g' examples/systemd/rest-server.service || die
	sed -i -e 's|/path/to/backups|/srv/backups|g' examples/systemd/rest-server.service || die

	default
}

src_compile() {
	CGO_ENABLED=0 ego build -o rest-server ./cmd/rest-server || die
}

src_install() {
	dobin rest-server

	dodoc *.md

	systemd_dounit examples/systemd/rest-server.{service,socket}
}
