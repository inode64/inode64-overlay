# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
DISTUTILS_USE_PEP517=hatchling

inherit distutils-r1 pypi

DESCRIPTION="Ordered YAML loader and dumper for PyYAML"
HOMEPAGE="https://github.com/Phynix/yamlloader https://pypi.org/project/yamlloader/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"

DOCS="README.rst"

RDEPEND="dev-python/pyyaml[${PYTHON_USEDEP}]"
BDEPEND="dev-python/hatch-vcs[${PYTHON_USEDEP}]"

EPYTEST_PLUGINS=( hypothesis )
distutils_enable_tests pytest
