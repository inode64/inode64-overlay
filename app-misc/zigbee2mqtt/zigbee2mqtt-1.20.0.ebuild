# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit systemd

DESCRIPTION="It bridges events and allows you to control your Zigbee devices via MQTT"
HOMEPAGE="https://www.zigbee2mqtt.io/"
SRC_URI="https://github.com/Koenkk/zigbee2mqtt/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64"

DEPEND=""
RDEPEND="
	app-misc/mosquitto
	net-libs/nodejs
"
BDEPEND="
	net-libs/nodejs[npm]
"

# To enable download packages
RESTRICT="network-sandbox"

src_compile() {
	# nothing to compile here
	:
}

src_install() {
	local key=$(
		s=""
		for ((i = 1; i <= 16; i++)); do
			printf '%s' "${s}0x$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 2 | head -n 1)"
			s=", "
		done
	)

	echo -e "\nadvanced:\n  network_key: [ ${key} ]" >>data/configuration.yaml
	echo -e "  log_directory: /var/log/${PN}" >>data/configuration.yaml

	npm ci --production --progress false

	keepdir /var/log/${PN}

	insinto /var/lib/${PN}
	doins data/configuration.yaml

	insinto /opt/${PN}
	doins -r images lib node_modules
	doins *.js *.json

	dodoc *.md

	doinitd "${FILESDIR}"/${PN}
	systemd_dounit "${FILESDIR}/${PN}.service"

	dodir /etc/env.d
	echo "CONFIG_PROTECT=/var/lib/${PN}/configuration.yaml" >>"${ED}"/etc/env.d/90${PN} || die
}
