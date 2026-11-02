# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
PYTHON_REQ_USE="bluetooth"

inherit python-single-r1 git-r3

DESCRIPTION="Bluetooth MQTT gateway"
HOMEPAGE="https://github.com/zewelor/bt-mqtt-gateway"
EGIT_REPO_URI="https://github.com/zewelor/bt-mqtt-gateway.git"

LICENSE="MIT"
SLOT="0"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		dev-python/apscheduler[${PYTHON_USEDEP}]
		dev-python/interruptingcow[${PYTHON_USEDEP}]
		dev-python/paho-mqtt[${PYTHON_USEDEP}]
		dev-python/pyyaml[${PYTHON_USEDEP}]
		dev-python/tenacity[${PYTHON_USEDEP}]
	')
"
BDEPEND="
	${PYTHON_DEPS}
"

DOCS=( README.md )

src_compile() {
	python_fix_shebang .
}

pkg_setup() {
	python-single-r1_pkg_setup
}

src_install() {
	insinto /opt/btmqttgateway
	doins *.py logger.yaml config.yaml.example
	insinto /opt/btmqttgateway/workers
	doins workers/*.py

	python_optimize "${ED}"/opt/btmqttgateway
	einstalldocs
}
