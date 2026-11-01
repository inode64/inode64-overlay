# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )
inherit distutils-r1 systemd

DESCRIPTION="Simple and generic Prometheus exporter for MQTT"
HOMEPAGE="https://github.com/kpetremann/mqtt-exporter"
if [[ ${PV} == *9999* ]]; then
	EGIT_REPO_URI="https://github.com/kpetremann/mqtt-exporter"
	inherit git-r3
else
	SRC_URI="https://github.com/kpetremann/mqtt-exporter/archive/${PV}.tar.gz -> ${P}.tar.gz"
fi

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	acct-user/mosquitto
	dev-python/paho-mqtt[${PYTHON_USEDEP}]
	dev-python/prometheus-client[${PYTHON_USEDEP}]
"

EPYTEST_PLUGINS=( pytest-mock )
distutils_enable_tests pytest

src_prepare() {
	# Upstream declares no build backend, which the eclass requires
	cat >> pyproject.toml <<-EOF || die

		[build-system]
		requires = ["setuptools"]
		build-backend = "setuptools.build_meta"
	EOF

	distutils-r1_src_prepare
}

python_install_all() {
	distutils-r1_python_install_all

	keepdir /var/log/${PN}

	systemd_dounit "${FILESDIR}"/${PN}.service
	newinitd "${FILESDIR}"/${PN}.initd ${PN}
	newconfd "${FILESDIR}"/${PN}.confd ${PN}
}
