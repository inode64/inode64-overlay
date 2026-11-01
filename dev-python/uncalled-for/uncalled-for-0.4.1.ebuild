# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="Async dependency injection for Python functions"
HOMEPAGE="https://pypi.org/project/uncalled-for/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND="
	dev-python/hatch-vcs[${PYTHON_USEDEP}]
"

EPYTEST_PLUGINS=( pytest-{asyncio,timeout} )
distutils_enable_tests pytest

export SETUPTOOLS_SCM_PRETEND_VERSION=${PV}

src_prepare() {
	# Coverage gates are for upstream's CI, not for validating the package.
	sed -i -e '/--cov/d' pyproject.toml || die
	distutils-r1_src_prepare
}
