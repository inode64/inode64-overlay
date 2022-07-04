# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{8..11} )

inherit distutils-r1 git-r3

# see scripts/download_import_cldr.py
CLDR_PV=41.0
DESCRIPTION="Bluetooth MQTT gateway"
HOMEPAGE="
	https://github.com/zewelor/bt-mqtt-gateway
"
SRC_URI="
"
EGIT_REPO_URI="https://github.com/zewelor/bt-mqtt-gateway.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-python/APScheduler[${PYTHON_USEDEP}]
	dev-python/interruptingcow[${PYTHON_USEDEP}]
	dev-python/paho-mqtt[${PYTHON_USEDEP}]
	dev-python/pyyaml[${PYTHON_USEDEP}]
	dev-python/tenacity[${PYTHON_USEDEP}]
"
BDEPEND="
	${RDEPEND}
"
