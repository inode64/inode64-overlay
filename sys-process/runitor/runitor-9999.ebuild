# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3 go-module

DESCRIPTION="A command runner with healthchecks.io integration"
HOMEPAGE="https://github.com/bdd/runitor/"
#SRC_URI="
#	https://www.inode64.com/dist/runitor-1.4.1-vendor.tar.xz"
EGIT_REPO_URI="https://github.com/bdd/runitor.git"

LICENSE="0BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"

PATCHES=( "${FILESDIR}/0001-Initial-pidfile-version.patch" )

src_unpack() {
	git-r3_src_unpack
	go-module_live_vendor
}

src_compile() {
	local ld_flags="-s -w"

	ego build -trimpath -ldflags "-s -w" ./cmd/${PN} || die
}

src_test() {
	ego test ./... || die "test failed"
}

src_install() {
	dobin "${PN}"
}
