# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..13} python3_13t pypy3 )
EGIT_REPO_URI="https://github.com/pydanny/${PN}.git"

inherit distutils-r1 git-r3

DESCRIPTION="A cached-property for decorating methods in classes"
HOMEPAGE="https://github.com/pydanny/cached-property"

LICENSE="BSD"
SLOT="0"

BDEPEND="test? ( dev-python/freezegun[${PYTHON_USEDEP}] )"

distutils_enable_tests pytest

DOCS=( {HISTORY,README}.md )
