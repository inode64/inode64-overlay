# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module systemd

DESCRIPTION="A scalable overlay networking tool with a focus on performance, simplicity and security"
HOMEPAGE="https://github.com/slackhq/nebula"

SRC_URI="https://github.com/slackhq/nebula/archive/v${PV}.tar.gz -> ${P}.tar.gz
	https://raw.githubusercontent.com/inode64/inode64-overlay/main/dist/${P}-vendor.tar.xz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+client gencert"
REQUIRED_USE="|| ( client gencert )"

src_configure(	) {
	export CGO_ENABLED=1
	export CGO_CFLAGS="${CFLAGS}"
	export CGO_CPPFLAGS="${CPPFLAGS}"
	export CGO_CXXFLAGS="${CXXFLAGS}"
	export CGO_LDFLAGS="${LDFLAGS}"

	default
}

src_compile() {
	if use client; then
		ego build -trimpath -ldflags "-s -w" -o nebula ./cmd/nebula/ || die
	fi
	if use gencert; then
		ego build -trimpath -ldflags "-s -w" -o nebula-cert ./cmd/nebula-cert/|| die
	fi
}

src_test() {
  emake test
}

src_install() {
	dodoc *.md

  diropts -m0700
  insopts -m0600
  insinto /etc/nebula/
  newins examples/config.yml config.example.yml

	if use client; then
		dobin nebula
		newinitd "${FILESDIR}/nebula.initd" ${PN}
		systemd_newunit "${FILESDIR}/${PN}.service" "${PN}@.service"
	fi

	if use gencert; then
		dobin nebula-cert
	fi
}
