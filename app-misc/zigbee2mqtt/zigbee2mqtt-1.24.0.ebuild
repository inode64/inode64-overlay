# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit systemd

DESCRIPTION="It bridges events and allows you to control your Zigbee devices via MQTT"
HOMEPAGE="https://www.zigbee2mqtt.io/"
SRC_URI="https://github.com/Koenkk/zigbee2mqtt/archive/${PV}.tar.gz -> ${P}.tar.gz"
COMMIT="41b67fdd07792a6c6569341d980ec60c1456c2d7"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	acct-group/zigbee2mqtt
	acct-user/zigbee2mqtt
	app-misc/mosquitto
	net-libs/nodejs
"
BDEPEND="
	dev-lang/typescript
	net-libs/nodejs[npm]
"

NPM_FLAGS=(
        --audit false
        --color false
        --foreground-scripts
        --global
        --offline
        --progress false
        --save false
        --verbose
)

# To enable download packages
RESTRICT="network-sandbox"

src_compile() {
	# nothing to compile here

	npm "${NPM_FLAGS[@]}" pack || die
}

src_install() {
    npm "${NPM_FLAGS[@]}" \
                --prefix "${ED}"/usr \
                install \
                ${P}.tgz || die

	local key=$(
		s=""
		for ((i = 1; i <= 16; i++)); do
			printf '%s' "${s}0x$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 2 | head -n 1)"
			s=", "
		done
	)

	echo -e "\nadvanced:\n	network_key: [ ${key} ]" >>data/configuration.yaml
	echo -e "  log_directory: /var/log/${PN}" >>data/configuration.yaml

	npm ci --production --progress false
	echo "{\"hash\": \"${COMMIT}\"}" > .hash.json

	keepdir /var/log/${PN}

	insinto /var/lib/${PN}
	doins data/configuration.yaml

	insinto /opt/${PN}
	doins -r images lib node_modules
	doins *.js *.json .hash.json

	dodoc *.md

	fowners zigbee2mqtt:zigbee2mqtt /var/lib/${PN}
	fowners zigbee2mqtt:zigbee2mqtt /var/log/${PN}
	fowners -R zigbee2mqtt:zigbee2mqtt /opt/${PN}

	doinitd "${FILESDIR}"/${PN}
	systemd_dounit "${FILESDIR}/${PN}.service"

	dodir /etc/env.d
	echo "CONFIG_PROTECT=/var/lib/${PN}" >>"${ED}"/etc/env.d/90${PN} || die
}
