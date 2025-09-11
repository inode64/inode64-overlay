# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic go-module

DESCRIPTION="A command runner with healthchecks.io integration"
HOMEPAGE="https://github.com/bdd/runitor/"
SRC_URI="https://github.com/bdd/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz
"

LICENSE="0BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"

src_configure() {
	filter-lto

	export CGO_ENABLED=1
	export CGO_CFLAGS="${CFLAGS}"
	export CGO_CPPFLAGS="${CPPFLAGS}"
	export CGO_CXXFLAGS="${CXXFLAGS}"
	export CGO_LDFLAGS="${LDFLAGS}"

	default
}

src_compile() {
	local ld_flags="-s -w"

	ego build -trimpath -ldflags "${ld_flags}" ./cmd/${PN} || die
}

src_test() {
	ego test ./... || die "test failed"
}

src_install() {
	dobin "${PN}"
}
