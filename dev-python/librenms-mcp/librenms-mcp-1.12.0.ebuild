# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="MCP server exposing LibreNMS devices, ports, alerts and inventory"
HOMEPAGE="
	https://github.com/mhajder/librenms-mcp
	https://pypi.org/project/librenms-mcp/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/fastmcp-4.0.0[${PYTHON_USEDEP}]
	<dev-python/fastmcp-5[${PYTHON_USEDEP}]
	>=dev-python/httpx2-2.12.0[${PYTHON_USEDEP}]
	>=dev-python/pydantic-2.12.0[${PYTHON_USEDEP}]
	>=dev-python/python-dotenv-1.0.0[${PYTHON_USEDEP}]
"

# The suite needs a live LibreNMS instance.
RESTRICT="test"

pkg_postinst() {
	elog "librenms-mcp is configured through the environment (or a .env file):"
	elog "  LIBRENMS_URL=https://librenms.example.com"
	elog "  LIBRENMS_TOKEN=<API token>"
	elog "  LIBRENMS_READ_ONLY=true      # recommended: block write operations"
	elog "  MCP_TRANSPORT=stdio          # or sse / http for a network service"
	elog "Register it in your MCP client, e.g. for Claude Code:"
	elog "  claude mcp add librenms -e LIBRENMS_URL=... -e LIBRENMS_TOKEN=... -- librenms-mcp"
}
