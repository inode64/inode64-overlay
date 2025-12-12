# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd tmpfiles

DESCRIPTION="Server-sent live updates: protocol and reference implementation"
HOMEPAGE="https://mercure.rocks"
SRC_URI="https://github.com/dunglas/${PN}/releases/download/v${PV}/${PN}_Linux_x86_64.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}"
LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	acct-group/mercure
	acct-user/mercure
	app-admin/sudo
	app-crypt/certbot
	dev-java/openjdk-bin
	dev-libs/nss
"

DOCS=(README.md)

src_install() {
	default

	insinto /usr/bin
	dobin mercure

	insinto /etc/logrotate.d
	newins "${FILESDIR}/mercure.logrotate" mercure

	insinto /etc/${PN}
	doins Caddyfile dev.Caddyfile
	fowners -R mercure:mercure /etc/${PN}

	newinitd "${FILESDIR}/mercure.initd" mercure
	dotmpfiles "${FILESDIR}"/${PN}.conf

	systemd_newunit "${FILESDIR}/${PN}.service" "${PN}.service"
}

pkg_postinst() {
	tmpfiles_process mercure.conf
}
