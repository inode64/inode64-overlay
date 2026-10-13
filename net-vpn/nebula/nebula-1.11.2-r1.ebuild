# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module linux-info systemd

DESCRIPTION="Nebula connects devices worldwide with a secure, simple, scalable network"
HOMEPAGE="https://github.com/slackhq/nebula"

SRC_URI="https://github.com/slackhq/nebula/archive/v${PV}.tar.gz -> ${P}.tar.gz
	https://www.inode64.com/dist/${P}-vendor.tar.xz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+client gencert"
REQUIRED_USE="|| ( client gencert )"

# Kernel features the nebula daemon relies on at runtime (overlay/tun_linux.go):
# a TUN device opened through /dev/net/tun with IFF_MULTI_QUEUE, addresses and
# routes managed over rtnetlink in the main table (no policy routing, no
# netfilter), and SO_MARK on its UDP socket. An IPv6 overlay additionally
# needs CONFIG_IPV6.
CONFIG_CHECK="~TUN"
ERROR_TUN="CONFIG_TUN is required: nebula creates its overlay interface through /dev/net/tun"

pkg_setup() {
	linux-info_pkg_setup
}

src_configure() {
	export EGO_LDFLAGS="-s -w -X main.Build=${PV}"

	default
}

src_compile() {
	if use client; then
		ego build -trimpath -ldflags "${EGO_LDFLAGS}" -o nebula ./cmd/nebula/ || die
	fi
	if use gencert; then
		ego build -trimpath -ldflags "${EGO_LDFLAGS}" -o nebula-cert ./cmd/nebula-cert/|| die
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

pkg_postinst() {
	chmod 0600 "${EROOT}"/etc/nebula/* 2>/dev/null

	if use client && use gencert; then
		ewarn "It is not recommended to use the same lighthouse server as the certificate generator."
	fi
}
