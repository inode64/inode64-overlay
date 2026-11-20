# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module shell-completion

DESCRIPTION="Configuration profiles manager and scheduler for restic backup"
HOMEPAGE="https://github.com/creativeprojects/resticprofile"
SRC_URI="https://github.com/creativeprojects/resticprofile/archive/v${PV}.tar.gz -> ${P}.tar.gz
	https://www.inode64.com/dist/${P}-vendor.tar.xz"

LICENSE="GPL-3"
# Dependent licenses
LICENSE+=" Apache-2.0 BSD BSD-2 ISC MIT MPL-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~riscv"

RDEPEND="app-backup/restic"
BDEPEND=">=dev-lang/go-1.26.2"

src_compile() {
	# main.go carries the next development version, the release one comes from
	# the linker. Updates belong to Portage, so leave "self-update" out.
	ego build -trimpath -tags no_self_update \
		-ldflags "-X main.version=${PV} -X main.builtBy=portage" || die
}

src_test() {
	# They need network, FUSE, D-Bus, systemctl or a regular user session. The
	# build tag stays off here: the completion tests expect "self-update".
	local skip="TestCannotStartTwice|TestCaffeinate|TestCreateTempDir|TestCurrentUser"
	skip+="|TestDownloadBinary|TestFixUnixPaths|TestMemFS|TestReadingSystemdScheduled"
	skip+="|TestStartProcessWithIOPriority|TestUpdate"
	ego test -skip "^(${skip})\$" ./... || die "test failed"
}

src_install() {
	dobin resticprofile
	dodoc *.md

	newbashcomp contrib/completion/bash-completion.sh resticprofile
	newfishcomp contrib/completion/fish-completion.fish resticprofile.fish
}
