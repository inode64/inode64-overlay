# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
DISTUTILS_USE_PEP517=poetry
inherit distutils-r1 pypi

DESCRIPTION="Uses sqlglot to parse SQL queries and extract metadata"

HOMEPAGE="https://github.com/macbre/sql-metadata"
LICENSE="MIT"

SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND=">=dev-python/sqlglot-30.12.0[${PYTHON_USEDEP}]
	<dev-python/sqlglot-31[${PYTHON_USEDEP}]"
