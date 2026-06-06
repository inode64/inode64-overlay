# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3 go-module

DESCRIPTION="Sermo is a safe service monitoring and control system for Linux."
HOMEPAGE="https://github.com/inode64/sermo"
EGIT_REPO_URI="https://github.com/inode64/Sermo.git"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
BDEPEND=">=dev-lang/go-1.26"

RESTRICT="network-sandbox"

src_unpack() {
    git-r3_src_unpack
}

src_compile() {
    ego build -trimpath -ldflags "-s -w" -o sermoctlr ./cmd/sermoctl || die
    ego build -trimpath -ldflags "-s -w" -o sermod ./cmd/sermod || die
}

src_test() {
    ego test || die "test failed"
}
