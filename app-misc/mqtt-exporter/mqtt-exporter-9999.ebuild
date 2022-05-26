# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

if [[ ${PV} == *9999* ]]; then
	EGIT_REPO_URI="https://github.com/kpetremann/mqtt-exporter"
	inherit git-r3
else
	SRC_URI="https://github.com/kpetremann/mqtt-exporter/archive/${PV}.tar.gz -> ${P}.tar.gz"
fi

PYTHON_COMPAT=(python3_{8..11})

inherit python-single-r1

DESCRIPTION="Simple and generic Prometheus exporter for MQTT"
HOMEPAGE="https://github.com/kpetremann/mqtt-exporter"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
    ${PYTHON_DEPS}
    dev-python/paho-mqtt
    dev-python/prometheus_client
"
BDEPEND="
"

pkg_setup() {
	python-single-r1_pkg_setup
}

src_prepare() {
	default
}

src_compile() {
	default
}

src_install() {
	insinto /usr/lib64/${PN}

	doins exporter.py
	doins -r mqtt_exporter

	dodoc README.md
	python_optimize
}
