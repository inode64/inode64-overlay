# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )
inherit distutils-r1 pypi

DESCRIPTION="CSS minifier written in python"
HOMEPAGE="https://opensource.perlig.de/rcssmin/"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

EPYTEST_PLUGINS=()
distutils_enable_tests pytest

python_compile() {
	# setup.py silently falls back to pure Python if the C extension fails.
	local -x SETUP_CEXT_REQUIRED=1
	distutils-r1_python_compile
}
