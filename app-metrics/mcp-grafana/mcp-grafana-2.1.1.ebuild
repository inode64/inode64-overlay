# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module systemd

DESCRIPTION="Model Context Protocol (MCP) server for Grafana"
HOMEPAGE="https://github.com/grafana/mcp-grafana"
SRC_URI="https://github.com/grafana/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz
	https://www.inode64.com/dist/${P}-vendor.tar.xz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND=">=dev-lang/go-1.26.9"

src_compile() {
	# Without cgo, as upstream does: the binary links no shared library.
	CGO_ENABLED=0 ego build -trimpath \
		-ldflags "-X github.com/grafana/${PN}/v2.version=${PV}" \
		-o ${PN} ./cmd/${PN}
}

src_test() {
	ego test -tags unit ./...
}

src_install() {
	dobin ${PN}
	einstalldocs

	newconfd "${FILESDIR}"/${PN}.confd ${PN}
	# It holds the bearer token that MCP clients must present.
	fperms 0600 /etc/conf.d/${PN}
	systemd_dounit "${FILESDIR}"/${PN}.service

	keepdir /etc/${PN}
	fperms 0700 /etc/${PN}
}

pkg_postinst() {
	elog "To run it as a service (streamable HTTP on 127.0.0.1:8000, read only):"
	elog "  1. Put a Grafana service account token in /etc/${PN}/token (mode 0600)"
	elog "  2. Review /etc/conf.d/${PN}"
	elog "  3. systemctl enable --now ${PN}"
	elog "Without a transport flag it speaks stdio, for a local MCP client."
}
