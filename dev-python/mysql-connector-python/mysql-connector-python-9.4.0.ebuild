# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
PYTHON_COMPAT=( python3_{11..14} )
DISTUTILS_USE_PEP517=setuptools
inherit distutils-r1

DESCRIPTION="Python client library for MariaDB/MySQL"
HOMEPAGE="https://dev.mysql.com/downloads/connector/python/"
SRC_URI="https://github.com/mysql/mysql-connector-python/archive/refs/tags/${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"
RESTRICT="test"

RDEPEND="
	dev-python/dnspython[${PYTHON_USEDEP}]
	dev-python/typing-extensions[${PYTHON_USEDEP}]
"

DOCS=( README.txt CHANGES.txt README.rst )

python_compile() {
	pushd mysql-connector-python >/dev/null || die
	distutils-r1_python_compile
	popd >/dev/null || die

	pushd mysqlx-connector-python >/dev/null || die
	distutils-r1_python_compile
	popd >/dev/null || die
}
