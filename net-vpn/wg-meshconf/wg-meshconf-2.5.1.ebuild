# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} python3_13t pypy3 )
DISTUTILS_USE_PEP517=pdm-backend

inherit distutils-r1 pypi

DESCRIPTION="Tool to generate peer configuration files for WireGuard mesh networks"
HOMEPAGE="
	https://github.com/k4yt3x/wg-meshconf
	https://pypi.org/project/wg-meshconf/
"
SRC_URI="https://files.pythonhosted.org/packages/e9/27/e6c4ed83f23b2825b4bbee1881be0872f7714fc6663046c884ad0d3f804b/${P}.tar.gz"

S="${WORKDIR}/${P}"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
	dev-python/rich[${PYTHON_USEDEP}]
	dev-python/cryptography[${PYTHON_USEDEP}]
"
RDEPEND="${DEPEND}"
