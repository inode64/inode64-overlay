# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=uv-build
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1

DESCRIPTION="The bidirectional mapping library for Python"
HOMEPAGE="https://bidict.readthedocs.io"
SRC_URI="https://github.com/jab/bidict/archive/refs/tags/v${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND="test? (
	dev-python/sortedcollections[${PYTHON_USEDEP}]
	)
"

# pyproject.toml passes --hypothesis-profile and --numprocesses.
EPYTEST_PLUGINS=( hypothesis )
EPYTEST_XDIST=1
distutils_enable_tests pytest
distutils_enable_sphinx docs dev-python/furo dev-python/sphinx-copybutton
