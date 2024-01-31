# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1 pypi

HOMEPAGE="https://github.com/onegreyonewhite/pytimeparse2"
DESCRIPTION="MySQL driver written in Python"
LICENSE="MIT"
RESTRICT="test"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="~dev-python/python-dateutil-2.8.2[${PYTHON_USEDEP}]"
