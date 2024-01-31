# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )
DISTUTILS_USE_PEP517=standalone

inherit distutils-r1 pypi

DESCRIPTION="A simple Python tool to transfer data from SQLite 3 to MySQL"
HOMEPAGE="https://github.com/techouse/sqlite3-to-mysql"
LICENSE="MIT"
RESTRICT="test"
SLOT="0"
KEYWORDS="~amd64 ~x86"
DOCS="CHANGELOG.md"

RDEPEND=">=dev-python/click-8.1.3[${PYTHON_USEDEP}]
	dev-python/mysql-connector-python[${PYTHON_USEDEP}]
	dev-python/packaging[${PYTHON_USEDEP}]
	dev-python/pytimeparse2[${PYTHON_USEDEP}]
	>=dev-python/simplejson-3.19.1[${PYTHON_USEDEP}]
	dev-python/tabulate[${PYTHON_USEDEP}]
	>=dev-python/tqdm-4.65.0[${PYTHON_USEDEP}]
	dev-python/typing-extensions[${PYTHON_USEDEP}]
	>=dev-python/unidecode-1.3.6[${PYTHON_USEDEP}]"
