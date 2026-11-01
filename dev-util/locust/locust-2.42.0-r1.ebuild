# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1

DESCRIPTION="Developer friendly load testing framework"
HOMEPAGE="https://locust.io
	https://github.com/locustio/locust"
SRC_URI="https://github.com/locustio/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.gh.tar.gz
	https://www.inode64.com/dist/${P}-node_modules.tar.xz
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND="
	dev-python/hatch-vcs[${PYTHON_USEDEP}]
	net-libs/nodejs
"

RDEPEND="
	dev-python/configargparse[${PYTHON_USEDEP}]
	dev-python/flask-cors[${PYTHON_USEDEP}]
	dev-python/flask-login[${PYTHON_USEDEP}]
	dev-python/gevent[${PYTHON_USEDEP}]
	dev-python/geventhttpclient[${PYTHON_USEDEP}]
	dev-python/msgpack[${PYTHON_USEDEP}]
	dev-python/paho-mqtt[${PYTHON_USEDEP}]
	dev-python/psutil[${PYTHON_USEDEP}]
	dev-python/pytest[${PYTHON_USEDEP}]
	dev-python/python-socketio[${PYTHON_USEDEP}]
	dev-python/pyzmq[${PYTHON_USEDEP}]
"

python_prepare_all() {
	distutils-r1_python_prepare_all

	export SETUPTOOLS_SCM_PRETEND_VERSION=${PV}

	rm -r locust/test || die

	# Same exclusions as the sdist: the wheel only needs the built web UI
	sed -i -e '/^\[tool.hatch.build.targets.wheel\]$/a exclude = ["/locust/webui/*"]' \
		pyproject.toml || die
}

src_compile() {
	# Upstream builds the web UI only for the sdist target, so a wheel made
	# straight from the sources would be left without it. These are the two
	# vite runs of "yarn build", which needs a yarn release not vendored here.
	pushd locust/webui >/dev/null || die
	node node_modules/.bin/vite build || die
	node node_modules/.bin/vite build --config vite.report.config.ts || die
	popd >/dev/null || die

	distutils-r1_src_compile
}
