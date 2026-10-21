# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

MY_PN="bifrost-http"

DESCRIPTION="AI gateway with virtual keys, budgets and usage logging (prebuilt binary)"
HOMEPAGE="
	https://getbifrost.ai/
	https://github.com/maximhq/bifrost
"
# Same binary the official npx wrapper fetches; built from tag transports/v${PV}.
SRC_URI="https://downloads.getmaxim.ai/bifrost/v${PV}/linux/amd64/${MY_PN} -> ${P}-linux-amd64"
S="${WORKDIR}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="-* ~amd64"
RESTRICT="strip"

RDEPEND="
	acct-group/bifrost
	acct-user/bifrost
"

QA_PREBUILT="usr/bin/${MY_PN}"

src_unpack() {
	cp "${DISTDIR}/${P}-linux-amd64" "${S}/${MY_PN}" || die
}

src_install() {
	dobin "${MY_PN}"

	keepdir /var/lib/bifrost
	fowners bifrost:bifrost /var/lib/bifrost
	fperms 0750 /var/lib/bifrost

	newinitd "${FILESDIR}/bifrost.initd" bifrost
	newconfd "${FILESDIR}/bifrost.confd" bifrost
	systemd_dounit "${FILESDIR}/bifrost.service"
}

pkg_postinst() {
	elog "Start the gateway with 'rc-service bifrost start' or"
	elog "'systemctl enable --now bifrost'. It listens on 127.0.0.1:8080:"
	elog "  web UI:            http://127.0.0.1:8080/"
	elog "  OpenAI API:        http://127.0.0.1:8080/v1"
	elog "  Anthropic API:     http://127.0.0.1:8080/anthropic"
	elog "Configuration lives in /var/lib/bifrost/config.json and is also"
	elog "editable through the UI/API (providers, virtual keys, budgets)."
	elog "Clients authenticate with their virtual key:"
	elog "  Authorization: Bearer <virtual key>   (or x-bf-vk header)"
	elog ""
	elog "The admin API and dashboard are open until an admin account exists."
	elog "Creating it needs a one-time BIFROST_SETUP_TOKEN: set it in"
	elog "/etc/conf.d/bifrost (OpenRC) or /etc/default/bifrost (systemd),"
	elog "restart, then create the account from the dashboard Security page."
	elog "Startup needs network access once to download the pricing catalog."
}
