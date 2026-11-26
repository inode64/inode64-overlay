# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd tmpfiles

MY_PN="${PN/-bin/}"

DESCRIPTION="Grafana Alloy: A modern distribution of the OpenTelemetry Collector"
HOMEPAGE="https://github.com/grafana/alloy"
SRC_URI="https://github.com/grafana/${MY_PN}/releases/download/v${PV}/${MY_PN}-linux-amd64.zip -> ${P}.zip"

S="${WORKDIR}"
LICENSE="Apache-2.0"
# Dependent licenses. The logql packages of Loki are AGPL-3.
LICENSE+=" 0BSD AGPL-3 BSD BSD-2 ISC MIT MIT-0 MPL-2.0"
LICENSE+=" CC-BY-4.0 OFL-1.1"
SLOT="0"
KEYWORDS="-* amd64"
RESTRICT="mirror"

RDEPEND="
	acct-user/alloy
	!app-metrics/alloy
"
BDEPEND="app-arch/unzip"

QA_PREBUILT="usr/bin/alloy"

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
