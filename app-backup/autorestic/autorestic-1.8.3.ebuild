# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="High level CLI utility for restic"
HOMEPAGE="https://github.com/cupcakearmy/autorestic"
SRC_URI="https://github.com/cupcakearmy/autorestic/archive/v${PV}.tar.gz -> ${P}.tar.gz
	https://www.inode64.com/dist/${P}-vendor.tar.xz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~riscv"

RDEPEND="app-backup/restic"

src_compile() {
	ego build -trimpath -ldflags "-s -w" || die
}

src_test() {
	ego test ./... || die "test failed"
}

src_install() {
	dobin autorestic
	dodoc *.md
}
