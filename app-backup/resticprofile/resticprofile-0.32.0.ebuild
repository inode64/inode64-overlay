# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="Configuration profiles manager and scheduler for restic backup"
HOMEPAGE="https://github.com/creativeprojects/resticprofile"
SRC_URI="https://github.com/creativeprojects/resticprofile/archive/v${PV}.tar.gz -> ${P}.tar.gz
	https://raw.githubusercontent.com/inode64/inode64-overlay/main/dist/${P}-vendor.tar.xz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~riscv"

RDEPEND="
	app-backup/restic
	>=dev-lang/go-1.25.0
"

src_configure() {
	export CGO_ENABLED=1
	export CGO_CFLAGS="${CFLAGS}"
	export CGO_CPPFLAGS="${CPPFLAGS}"
	export CGO_CXXFLAGS="${CXXFLAGS}"
	export CGO_LDFLAGS="${LDFLAGS}"

	default
}

src_compile() {
	ego build -trimpath -ldflags "-s -w" || die
}

src_test() {
	ego test ./... || die "test failed"
}

src_install() {
	dobin resticprofile
	dodoc *.md
}
