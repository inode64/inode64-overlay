# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
DISTUTILS_USE_PEP517=standalone

inherit distutils-r1 git-r3

DESCRIPTION="Analyses your database queries and schema and suggests indices and schema improvements"
HOMEPAGE="https://github.com/macbre/index-digest"
EGIT_REPO_URI="https://github.com/macbre/index-digest"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
RESTRICT="test"

DOCS="CONTRIBUTING.md"

RDEPEND="dev-python/docopt[${PYTHON_USEDEP}]
	dev-python/pyyaml[${PYTHON_USEDEP}]
	dev-python/mysqlclient[${PYTHON_USEDEP}]
	dev-python/sql_metadata[${PYTHON_USEDEP}]
	dev-python/termcolor[${PYTHON_USEDEP}]
	dev-python/yamlloader[${PYTHON_USEDEP}]
"

PATCHES=(
	"${FILESDIR}/0001-migrate-to-yamlloader.patch"
)
