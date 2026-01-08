# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd tmpfiles

MY_PN="${PN/-bin/}"

DESCRIPTION="Grafana Alloy: A modern distribution of the OpenTelemetry Collector"
HOMEPAGE="https://github.com/grafana/alloy"
LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"

RESTRICT="mirror strip"
SRC_URI="https://github.com/grafana/${MY_PN}/releases/download/v${PV}/${MY_PN}-linux-amd64.zip -> ${P}.zip"

S="${WORKDIR}"

RDEPEND="${DEPEND}
	acct-user/alloy
	acct-group/alloy
"

src_install() {
	newbin alloy-linux-amd64 alloy

	insinto /etc/alloy
	doins "${FILESDIR}/config.alloy"

	newconfd "${FILESDIR}/${MY_PN}.confd" ${MY_PN}
	newinitd "${FILESDIR}/${MY_PN}.initd" ${MY_PN}
	systemd_dounit "${FILESDIR}/${MY_PN}.service"
	newtmpfiles "${FILESDIR}"/${MY_PN}.tmpfiles.conf ${MY_PN}.conf
}

pkg_postinst() {
	tmpfiles_process ${MY_PN}.conf
}
