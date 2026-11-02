# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module systemd

DESCRIPTION="Model Context Protocol (MCP) server for Grafana"
HOMEPAGE="https://github.com/grafana/mcp-grafana"
SRC_URI="https://github.com/grafana/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz
	https://www.inode64.com/dist/${P}-vendor.tar.xz"

LICENSE="Apache-2.0"
# Dependent licenses
LICENSE+=" BSD BSD-2 ISC MIT MIT-0 MPL-2.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	acct-group/mcp-grafana
	acct-user/mcp-grafana
"
BDEPEND=">=dev-lang/go-1.26.10"

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

	# Shared by the systemd unit and the OpenRC script. It holds the bearer
	# token that MCP clients must present.
	insinto /etc/${PN}
	doins "${FILESDIR}"/${PN}.conf
	fperms 0600 /etc/${PN}/${PN}.conf
	fperms 0700 /etc/${PN}

	systemd_dounit "${FILESDIR}"/${PN}.service
	newinitd "${FILESDIR}"/${PN}.initd ${PN}
}

pkg_preinst() {
	# Up to 2.2.0 the settings, client token included, lived in
	# /etc/conf.d. Carry them over instead of starting with the defaults.
	local old="${EROOT}/etc/conf.d/${PN}"
	if [[ -f ${old} && ! -e ${EROOT}/etc/${PN}/${PN}.conf ]]; then
		cp "${old}" "${ED}/etc/${PN}/${PN}.conf" || die
		elog "Copied ${old} to ${EROOT}/etc/${PN}/${PN}.conf, the file the service"
		elog "reads now. The old one is no longer used and can be removed."
	fi
}

pkg_postinst() {
	elog "To run it as a service (streamable HTTP on 127.0.0.1:8000, read only):"
	elog "  1. Put a Grafana service account token in /etc/${PN}/token (mode 0600)"
	elog "  2. Review /etc/${PN}/${PN}.conf"
	elog "  3. systemctl enable --now ${PN}, or rc-update add ${PN} default"
	elog "Without a transport flag it speaks stdio, for a local MCP client."
}
