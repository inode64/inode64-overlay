# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3 go-env go-module

DESCRIPTION="A command runner with healthchecks.io integration"
HOMEPAGE="https://github.com/bdd/runitor/"
#SRC_URI="
#	https://www.inode64.com/dist/runitor-1.4.1-vendor.tar.xz"
EGIT_REPO_URI="https://github.com/bdd/runitor.git"

LICENSE="0BSD"
# Dependent licenses
LICENSE+=" BSD BSD-2 CC0-1.0"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"

BDEPEND=">=dev-lang/go-1.27"

PATCHES=( "${FILESDIR}/0001-Initial-pidfile-version.patch" )

src_unpack() {
	git-r3_src_unpack
	# go-module_src_unpack is what sets GOFLAGS (-buildmode=pie among them) and
	# the cgo flags, and this path does not go through it.
	go-env_set_compile_environment
	go-module_live_vendor
}

src_compile() {
	ego build -trimpath -ldflags "-X main.Version=${PV}-${EGIT_VERSION:0:8}" ./cmd/${PN} || die
}

src_test() {
	ego test ./... || die "test failed"
}

src_install() {
	dobin "${PN}"
}
