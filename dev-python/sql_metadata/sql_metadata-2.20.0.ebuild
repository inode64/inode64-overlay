# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
DISTUTILS_USE_PEP517=poetry
inherit distutils-r1 pypi

DESCRIPTION="Uses tokenized query returned by python-sqlparse and generates query metadata"

HOMEPAGE="https://github.com/macbre/sql-metadata"
LICENSE="MIT"

SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND=">=dev-python/sqlparse-0.4.1[${PYTHON_USEDEP}]"

src_prepare() {
	sed -i -e 's/sqlparse = ">=0.4.1,<0.6.0"/sqlparse = ">=0.4.1"/' pyproject.toml || die
	distutils-r1_src_prepare
}
