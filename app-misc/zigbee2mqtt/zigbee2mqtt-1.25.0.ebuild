# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

DESCRIPTION="It bridges events and allows you to control your Zigbee devices via MQTT"
HOMEPAGE="https://www.zigbee2mqtt.io/"
SRC_URI="https://github.com/Koenkk/zigbee2mqtt/archive/${PV}.tar.gz -> ${P}.tar.gz"
COMMIT="6f1460e47b430f8e1fe22819da56a238f8c92174"

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
	--progress false
	--save false
	--verbose
)

# To enable download packages
RESTRICT="network-sandbox"

src_compile() {
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

	dodir /usr/lib64/node_modules/${PN}/dist
	cp -r lib "${D}/usr/lib64/node_modules/${PN}" || die
	cp tsconfig.json "${D}/usr/lib64/node_modules/${PN}" || die

	cd "${D}/usr/lib64/node_modules/${PN}"
	npm --prefix . install --save-dev || die
	npm run build || die
	npm prune --production || die

	echo "{\"hash\": \"${COMMIT}\"}" > dist/.hash.json

	find ${pkgdir} -name "*.d.ts" -delete
	find ${pkgdir} -name "*.d.ts.map" -delete
	find ${pkgdir} -name "*.js.map" -delete

	echo -e "\nadvanced:\n	network_key: [ ${key} ]" >>data/configuration.yaml
	echo -e "  log_directory: /var/log/${PN}" >>data/configuration.yaml

	keepdir /var/log/${PN}

	insinto /var/lib/${PN}
	doins data/configuration.yaml

	fowners zigbee2mqtt:zigbee2mqtt /var/lib/${PN}
	fowners zigbee2mqtt:zigbee2mqtt /var/log/${PN}

	doinitd "${FILESDIR}"/${PN}-r1
	systemd_dounit "${FILESDIR}/${PN}-r1.service"

	dodir /etc/env.d
	echo "CONFIG_PROTECT=/var/lib/${PN}" >>"${ED}"/etc/env.d/90${PN} || die
}