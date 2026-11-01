# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit nodejs nodejs-mod systemd tmpfiles

DESCRIPTION="It bridges events and allows you to control your Zigbee devices via MQTT"
HOMEPAGE="https://www.zigbee2mqtt.io/"
COMMIT="3c3d8c1a71cabb31f1b97ad268681dd3f747ce19"

if [[ ${PV} == *9999* ]]; then
	EGIT_REPO_URI="https://github.com/Koenkk/zigbee2mqtt"
	EGIT_BRANCH="dev"
	inherit git-r3
else
	SRC_URI="https://github.com/Koenkk/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz
		https://www.inode64.com/dist/${P}-node_modules.tar.xz"
fi

LICENSE="0BSD Apache-2.0 BSD-2 CC-BY-4.0 GPL-3 ISC MIT PYTHON"
SLOT="0"
KEYWORDS="~amd64"
IUSE="homeassistant"

RDEPEND="
	acct-group/zigbee2mqtt
	acct-user/zigbee2mqtt
	app-misc/mosquitto
	net-libs/nodejs:=
	homeassistant? ( || (
		>=app-misc/homeassistant-2024.4[mosquitto]
		>=app-misc/homeassistant-min-2024.4[mosquitto]
		>=app-misc/homeassistant-full-2024.4[mosquitto]
	) )
"

pkg_pretend() {
	if [[ -e "${EROOT}/etc/env.d/90${PN}" ]] && \
	    ! grep -q "CONFIG_PROTECT=\"/var/lib/${PN}\"" "${EROOT}/etc/env.d/90${PN}" 2>/dev/null; then
		eerror "Bad CONFIG_PROTECT"
		eerror "update ${EROOT}/etc/env.d/90${PN} to include CONFIG_PROTECT=\"/var/lib/${PN}\""
		eerror ""
		eerror ""
		die "Bad CONFIG_PROTECT"
	fi
}

src_install() {
	echo "${COMMIT}" > dist/.hash

	# Upstream only ships the example now, which also sets the MQTT server, the
	# frontend and the configuration version that a bare "advanced:" would lack.
	sed -e "/^advanced:/a\\    log_directory: /var/log/${PN}" \
		data/configuration.example.yaml > data/configuration.yaml || die

	nodejs-mod_src_install

	keepdir "/var/log/${PN}"

	insinto "/var/lib/${PN}"
	doins data/configuration.yaml

	dotmpfiles "${FILESDIR}/zigbee2mqtt.conf"

	doinitd "${FILESDIR}/${PN}"
	systemd_newunit "${FILESDIR}/${PN}-r1.service" "${PN}.service"

	dodir /etc/env.d
	echo "CONFIG_PROTECT=\"/var/lib/${PN}"\" >>"${ED}/etc/env.d/90${PN}" || die

	# Hack to gzip frontend files to permit "Accept-Encoding: gzip": upstream only
	# ships brotli, which browsers do not request over plain HTTP.
	local frontend
	for frontend in zigbee2mqtt-frontend zigbee2mqtt-windfront; do
		gzip -k "${ED}$(nodejs_modules)/node_modules/${frontend}"/dist/{*.html,assets/*.js} || die
	done
}

pkg_postinst() {
	tmpfiles_process zigbee2mqtt.conf
}
