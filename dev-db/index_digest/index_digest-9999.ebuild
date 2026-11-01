# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1 git-r3

DESCRIPTION="Analyses database queries and schema and suggests improvements"
HOMEPAGE="https://github.com/macbre/index-digest"
EGIT_REPO_URI="https://github.com/macbre/index-digest"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
RESTRICT="test"

DOCS="CONTRIBUTING.md"

# Its linters import sql_metadata.compat, which 3.0 removed.
RDEPEND="dev-python/docopt[${PYTHON_USEDEP}]
	dev-python/mysqlclient[${PYTHON_USEDEP}]
	<dev-python/sql_metadata-3[${PYTHON_USEDEP}]
	dev-python/termcolor[${PYTHON_USEDEP}]
	dev-python/yamlloader[${PYTHON_USEDEP}]
"

src_prepare() {
	# yamlordereddictloader left the tree. A sed survives the pin changes in
	# setup.py, which broke the patch that did this on the live sources.
	sed -i \
		-e 's/^import yamlordereddictloader$/import yamlloader/' \
		-e 's/yamlordereddictloader\.Dumper/yamlloader.ordereddict.Dumper/' \
		indexdigest/formatters/yaml.py || die
	sed -i -e "s/'yamlordereddictloader==[^']*'/'yamlloader'/" setup.py || die

	distutils-r1_src_prepare
}
