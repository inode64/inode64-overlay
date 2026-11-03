# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=uv-build
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1

DESCRIPTION="RESPX-like HTTP mocking for niquests"
HOMEPAGE="
	https://github.com/0x12th/niquests-mock
	https://pypi.org/project/niquests-mock/
"
# The PyPI sdist leaves out tests/ and examples/, which pytest collects.
SRC_URI="https://github.com/0x12th/niquests-mock/archive/refs/tags/v${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/niquests-3.17.0[${PYTHON_USEDEP}]
	>=dev-python/orjson-3.10.18[${PYTHON_USEDEP}]
"

# The tests use the package's own pytest plugin, also from pytester runs.
EPYTEST_PLUGIN_LOAD_VIA_ENV=1
EPYTEST_PLUGINS=( "${PN}" )
distutils_enable_tests pytest
