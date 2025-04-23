# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} python3_13t pypy3 )
DISTUTILS_USE_PEP517=poetry
PYPI_PN="portage-${PN}"
inherit distutils-r1 git-r3

DESCRIPTION="Tool to update ebuilds."
HOMEPAGE="https://pypi.org/project/portage-livecheck/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
EGIT_REPO_URI="https://github.com/Tatsh/livecheck.git"

RDEPEND="
	dev-python/click[${PYTHON_USEDEP}]
	dev-python/keyring[${PYTHON_USEDEP}]
	dev-python/platformdirs[${PYTHON_USEDEP}]
	dev-python/platformdirs[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}"
