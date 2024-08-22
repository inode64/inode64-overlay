# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( pypy3 python3_{10..13} )
EGIT_REPO_URI="https://github.com/pydanny/${PN}.git"

inherit distutils-r1 git-r3

DESCRIPTION="A cached-property for decorating methods in classes"
HOMEPAGE="https://github.com/pydanny/cached-property"

LICENSE="BSD"
SLOT="0"

BDEPEND="test? ( dev-python/freezegun[${PYTHON_USEDEP}] )"

distutils_enable_tests pytest

DOCS=( {HISTORY,README}.md )

PATCHES=(
	# bug 638250
	"${FILESDIR}"/${PN}-1.5.1-test-failure.patch
	# @asyncio.coroutine removed in py3.11
	"${FILESDIR}"/${PN}-1.5.2-python311.patch
)
