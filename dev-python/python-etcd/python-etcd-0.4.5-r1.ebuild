# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYPI_NO_NORMALIZE=1
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 pypi

DESCRIPTION="A python client for etcd"
HOMEPAGE="
	https://github.com/jplana/python-etcd
	https://pypi.org/project/python-etcd/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-python/urllib3[${PYTHON_USEDEP}]
	dev-python/dnspython[${PYTHON_USEDEP}]
"
BDEPEND="
	test? (
		dev-python/mock[${PYTHON_USEDEP}]
	)
"

PATCHES=(
	# Unit test fixes from Debian 0.4.5-7
	"${FILESDIR}/${P}-fix_mock_InvalidSpecError.patch"
	"${FILESDIR}/${P}-ignore_urllib3.patch"
	"${FILESDIR}/${P}-pytest8.4.patch"
)

EPYTEST_PLUGINS=()
distutils_enable_tests pytest

python_prepare_all() {
	# unittest dropped assertEquals in Python 3.12
	sed -i -e 's/assertEquals/assertEqual/' src/etcd/tests/unit/*.py || die
	distutils-r1_python_prepare_all
}

python_test() {
	# The integration tests spawn a real etcd server.
	epytest src/etcd/tests/unit
}
