# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
DISTUTILS_USE_PEP517=hatchling
PYPI_PN="portage-${PN}"

inherit distutils-r1 git-r3

DESCRIPTION="Tool to update ebuilds."
HOMEPAGE="https://pypi.org/project/livecheck/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
EGIT_REPO_URI="https://github.com/Tatsh/livecheck.git"

RDEPEND=">=dev-python/anyio-4.13.0[${PYTHON_USEDEP}]
	>=dev-python/bascom-0.1.2[${PYTHON_USEDEP}]
	>=dev-python/beautifulsoup4-4.14.3[${PYTHON_USEDEP}]
	>=dev-python/click-8.3.2[${PYTHON_USEDEP}]
	>=dev-python/defusedxml-0.7.1[${PYTHON_USEDEP}]
	>=dev-python/html5lib-1.1[${PYTHON_USEDEP}]
	>=dev-python/keyring-25.7.0[${PYTHON_USEDEP}]
	>=dev-python/niquests-3.18.6[${PYTHON_USEDEP}]
	>=dev-python/niquests-cache-0.2.2[${PYTHON_USEDEP}]
	>=dev-python/platformdirs-4.9.6[${PYTHON_USEDEP}]
	>=sys-apps/portage-3.0.77
	>=dev-python/typing-extensions-4.15.0[${PYTHON_USEDEP}]"
DEPEND="${RDEPEND}"

distutils_enable_tests pytest
