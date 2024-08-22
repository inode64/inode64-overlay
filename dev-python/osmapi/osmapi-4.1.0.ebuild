# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( pypy3 python3_{10..13} )
DISTUTILS_USE_PEP517=setuptools
inherit distutils-r1 pypi

DESCRIPTION="Python wrapper for the OSM API"
HOMEPAGE="https://github.com/metaodi/osmapi
	    https://pypi.org/project/osmapi/"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"
RESTRICT="test"

DOCS="README.md"

RDEPEND="
	dev-python/requests[${PYTHON_USEDEP}]
"

src_prepare() {
	default

	# tests are broken
	rm -rf tests || die
}
