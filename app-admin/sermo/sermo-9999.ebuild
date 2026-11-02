# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3 go-env go-module tmpfiles

DESCRIPTION="Sermo is a safe service monitoring and control system for Linux"
HOMEPAGE="https://github.com/inode64/sermo"
EGIT_REPO_URI="https://github.com/inode64/Sermo.git"

LICENSE="Apache-2.0"
# Dependent licenses
LICENSE+=" BSD BSD-2 ISC LGPL-3 MIT MPL-2.0 public-domain"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"
BDEPEND+=" >=dev-lang/go-1.27.3"

RESTRICT="!test? ( test )"

src_unpack() {
	git-r3_src_unpack
	# go-module_src_unpack is what sets GOFLAGS (-buildmode=pie among them) and
	# the cgo flags, and this path does not go through it.
	go-env_set_compile_environment
	# Fetch modules during unpack, where live ebuilds may access the network.
	go-module_live_vendor
}

src_compile() {
	# Not "ego build": the Makefile embeds the version and the catalog path,
	# and "make install" always rebuilds through this target.
	emake build
}

src_test() {
	ego test ./... || die "test failed"
}

pkg_postinst() {
	tmpfiles_process sermo.conf
}
