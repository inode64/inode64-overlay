# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1 pypi

DESCRIPTION="MySQL driver written in Python"
HOMEPAGE="https://github.com/onegreyonewhite/pytimeparse2"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
RESTRICT="test"

RDEPEND="~dev-python/python-dateutil-2.8.2[${PYTHON_USEDEP}]"
