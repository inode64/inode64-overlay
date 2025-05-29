# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
DISTUTILS_USE_PEP517=pdm-backend
PYPI_PN=${PN}
PYPI_NO_NORMALIZE=1

inherit distutils-r1 pypi

DESCRIPTION="Tool to generate peer configuration files for WireGuard mesh networks"
HOMEPAGE="
	https://github.com/k4yt3x/wg-meshconf
	https://pypi.org/project/wg-meshconf/
"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
	dev-python/rich[${PYTHON_USEDEP}]
	dev-python/cryptography[${PYTHON_USEDEP}]
"
RDEPEND="${DEPEND}"
