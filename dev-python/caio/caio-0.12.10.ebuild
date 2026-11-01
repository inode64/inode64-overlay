# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
DISTUTILS_EXT=1
PYTHON_COMPAT=( python3_{12..15} )

inherit distutils-r1 pypi

DESCRIPTION="Asynchronous file IO for Linux and macOS"
HOMEPAGE="https://pypi.org/project/caio/"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND="
	>=dev-python/setuptools-77[${PYTHON_USEDEP}]
"

# The asyncio adapter tests need aiomisc, which is not packaged.
EPYTEST_IGNORE=( tests/test_asyncio_adapter.py )
EPYTEST_PLUGINS=()
distutils_enable_tests pytest

src_prepare() {
	distutils-r1_src_prepare

	# Debug info is up to CFLAGS.
	sed -i -E '/extra_compile_args/s/,\s*"-g"|"-g",\s*|"-g"//g' setup.py || die
}

python_test() {
	# The source tree has no extensions and would shadow the built package.
	rm -rf caio || die
	epytest
}
