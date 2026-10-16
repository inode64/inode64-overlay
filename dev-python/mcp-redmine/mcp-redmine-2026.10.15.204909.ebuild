# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="MCP server covering the Redmine REST API (issues, projects, wiki, time entries)"
HOMEPAGE="
	https://github.com/runekaagaard/mcp-redmine
	https://pypi.org/project/mcp-redmine/
"

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="~amd64"

# Upstream pins exact versions; the API it uses is stable across them.
RDEPEND="
	dev-python/httpx[${PYTHON_USEDEP}]
	>=dev-python/mcp-2[${PYTHON_USEDEP}]
	<dev-python/mcp-3[${PYTHON_USEDEP}]
	dev-python/openapi-core[${PYTHON_USEDEP}]
	dev-python/pyyaml[${PYTHON_USEDEP}]
	dev-python/python-dotenv[${PYTHON_USEDEP}]
	dev-python/typer[${PYTHON_USEDEP}]
"

# Tests hit a live Redmine instance.
RESTRICT="test"

src_prepare() {
	distutils-r1_src_prepare
	# Drop the exact version pins so the system packages satisfy them.
	sed -i -E 's/^(\s*"[A-Za-z0-9_\[\]-]+)==[0-9.]+(",?)$/\1\2/' pyproject.toml || die
}

pkg_postinst() {
	elog "mcp-redmine is configured through the environment:"
	elog "  REDMINE_URL=https://redmine.example.com"
	elog "  REDMINE_API_KEY=<API key>            (My account -> API access key)"
	elog "  REDMINE_REQUEST_INSTRUCTIONS=/path/to/instructions.md   (optional)"
	elog "  REDMINE_ALLOWED_DIRECTORIES=/tmp     (optional, for attachments)"
	elog "Register it in your MCP client, e.g. for Claude Code:"
	elog "  claude mcp add redmine -e REDMINE_URL=... -e REDMINE_API_KEY=... -- mcp-redmine"
}
