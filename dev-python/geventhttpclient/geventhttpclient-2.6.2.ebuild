# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 pypi

DESCRIPTION="Coroutine-based network library"
HOMEPAGE="
	https://github.com/geventhttpclient/geventhttpclient
	https://pypi.org/project/geventhttpclient/
"
SRC_URI="https://github.com/${PN}/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="net-libs/llhttp:="
RDEPEND="
	${DEPEND}
	app-arch/brotli[python,${PYTHON_USEDEP}]
	dev-python/certifi[${PYTHON_USEDEP}]
	>=dev-python/gevent-25.9[${PYTHON_USEDEP}]
"

BDEPEND="
	dev-python/setuptools-scm[${PYTHON_USEDEP}]
	test? (
		dev-python/httplib2[${PYTHON_USEDEP}]
		dev-python/requests[${PYTHON_USEDEP}]
	)
"

PATCHES=(
	"${FILESDIR}"/${P}-system-llhttp.patch
)

# The GitHub archive has no git metadata, so setuptools-scm would report 0.0.0.
export SETUPTOOLS_SCM_PRETEND_VERSION=${PV}

# These need dpkt, which is not packaged.
EPYTEST_IGNORE=(
	tests/gevent_only/test_proxy.py
	tests/gevent_only/test_ssl.py
	tests/test_proxy.py
	tests/test_ssl.py
)
EPYTEST_PLUGINS=( pytest-rerunfailures )
distutils_enable_tests pytest

python_test() {
	epytest -m "not network"
}
