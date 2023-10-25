# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

if [[ ${PV} == *9999* ]]; then
	EGIT_REPO_URI="https://github.com/kpetremann/mqtt-exporter"
	inherit git-r3
else
	SRC_URI="https://github.com/kpetremann/mqtt-exporter/archive/${PV}.tar.gz -> ${P}.tar.gz"
fi

PYTHON_COMPAT=( python3_{10..12} )

inherit python-single-r1 systemd

DESCRIPTION="Simple and generic Prometheus exporter for MQTT"
HOMEPAGE="https://github.com/kpetremann/mqtt-exporter"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	${PYTHON_DEPS}
	acct-user/mosquitto
	acct-group/mosquitto
	dev-python/paho-mqtt
	dev-python/prometheus_client
"
BDEPEND="
"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

src_prepare() {
	default
}

src_compile() {
	default
}

src_install() {
	insinto /usr/$(get_libdir)/${PN}

	doins exporter.py
	doins -r mqtt_exporter

	dodoc README.md

	keepdir /var/log/${PN}

	systemd_dounit "${FILESDIR}"/${PN}.service
	newinitd "${FILESDIR}"/${PN}.initd ${PN}
	newconfd "${FILESDIR}"/${PN}.confd ${PN}
}
