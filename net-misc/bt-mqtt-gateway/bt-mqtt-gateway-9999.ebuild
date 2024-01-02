# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )

inherit python-single-r1 git-r3

# see scripts/download_import_cldr.py
CLDR_PV=41.0
DESCRIPTION="Bluetooth MQTT gateway"
HOMEPAGE="https://github.com/zewelor/bt-mqtt-gateway"
EGIT_REPO_URI="https://github.com/zewelor/bt-mqtt-gateway.git"

LICENSE="MIT"
SLOT="0"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
	${PYTHON_DEPS}
	dev-lang/python[bluetooth]
	dev-python/APScheduler
	dev-python/interruptingcow
	dev-python/paho-mqtt
	dev-python/pyyaml
	dev-python/tenacity
"
BDEPEND="
	${RDEPEND}
"

DOCS=( README.md )

src_compile() {
	python_fix_shebang .
}

pkg_setup() {
	python-single-r1_pkg_setup
}

src_install() {
	python_optimize

	insinto /opt/btmqttgateway
	doins *.py logger.yaml config.yaml.example
	insinto /opt/btmqttgateway/workers
	doins workers/*.py
}
