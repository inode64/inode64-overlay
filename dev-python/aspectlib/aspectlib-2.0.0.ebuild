# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1

MY_PN="python-${PN}"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Aspect-oriented programming, monkey-patch and decorators library"
HOMEPAGE="https://github.com/ionelmc/python-aspectlib"
SRC_URI="https://github.com/ionelmc/${MY_PN}/archive/v${PV}.tar.gz -> ${MY_P}.gh.tar.gz"
S="${WORKDIR}/${MY_P}"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"

BDEPEND="test? ( dev-python/process-tests[${PYTHON_USEDEP}]
		dev-python/tornado[${PYTHON_USEDEP}] )"

# test_pytestsupport.py needs the weave fixture of aspectlib's own plugin.
EPYTEST_PLUGINS=( "${PN}" )
distutils_enable_tests pytest

python_prepare_all() {
	# Its pytest_ignore_collect(path, config) hook is rejected by pytest 9, and
	# it only filters doctests in src/, which testpaths does not collect.
	rm tests/conftest.py || die

	distutils-r1_python_prepare_all
}
