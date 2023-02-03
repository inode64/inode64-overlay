# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

if [[ ${PV} == *9999* ]]; then
	EGIT_REPO_URI="https://github.com/Koenkk/zigbee2mqtt"
	EGIT_BRANCH="dev"
	inherit git-r3
else
	SRC_URI="https://github.com/Koenkk/zigbee2mqtt/archive/${PV}.tar.gz -> ${P}.tar.gz"
fi

NODEJS_TYPESCRIPT=true

inherit nodejs systemd

DESCRIPTION="It bridges events and allows you to control your Zigbee devices via MQTT"
HOMEPAGE="https://www.zigbee2mqtt.io/"
COMMIT="bb3e8f6d414f126cd7f57686e0e9798f285eb78e"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	acct-group/zigbee2mqtt
	acct-user/zigbee2mqtt
	app-misc/mosquitto
	net-libs/nodejs:=
"
BDEPEND="
"

# To enable download packages
RESTRICT="network-sandbox"

src_install() {
    enpm_install

	dodir /usr/lib64/node_modules/${PN}/dist
	cp -r lib "${D}/usr/lib64/node_modules/${PN}" || die
	cp tsconfig.json "${D}/usr/lib64/node_modules/${PN}" || die

	cd "${D}/usr/lib64/node_modules/${PN}"
	enpm --prefix . install || die
	enpm run build || die
	enpm_clean

	echo "{\"hash\": \"${COMMIT}\"}" > dist/.hash.json

	echo -e "\nadvanced:" >>data/configuration.yaml
	echo -e "  network_key: GENERATE" >>data/configuration.yaml
	echo -e "  pan_id: GENERATE" >>data/configuration.yaml
	echo -e "  log_directory: /var/log/${PN}" >>data/configuration.yaml

	keepdir /var/log/${PN}

	insinto /var/lib/${PN}
	doins data/configuration.yaml

	fowners zigbee2mqtt:zigbee2mqtt /var/lib/${PN}
	fowners zigbee2mqtt:zigbee2mqtt /var/log/${PN}
	fowners zigbee2mqtt:zigbee2mqtt /var/lib/${PN}/configuration.yaml

	doinitd "${FILESDIR}"/${PN}
	systemd_dounit "${FILESDIR}/${PN}.service"

	dodir /etc/env.d
	echo "CONFIG_PROTECT=/var/lib/${PN}" >>"${ED}"/etc/env.d/90${PN} || die

	dodoc *.md

	rm -rf "${ED}"/usr/lib64/node_modules/${PN}/data || die
	rm "${ED}"/usr/lib64/node_modules/${PN}/{update.sh,LICENSE,*.md} || die
}
