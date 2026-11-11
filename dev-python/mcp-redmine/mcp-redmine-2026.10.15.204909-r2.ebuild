# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi systemd

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
	acct-user/mcp-redmine
	dev-python/httpx[${PYTHON_USEDEP}]
	>=dev-python/mcp-2[${PYTHON_USEDEP}]
	<dev-python/mcp-3[${PYTHON_USEDEP}]
	dev-python/pyyaml[${PYTHON_USEDEP}]
"

EPYTEST_PLUGINS=()
distutils_enable_tests pytest

src_prepare() {
	distutils-r1_src_prepare
	# Drop the exact version pins so the system packages satisfy them.
	sed -i -E 's/^(\s*"[][A-Za-z0-9_-]+)==[0-9.]+(",?)$/\1\2/' pyproject.toml || die
	# Declared upstream but never imported: the server reads its OpenAPI
	# spec with PyYAML.
	sed -i -e '/"openapi-core/d' pyproject.toml || die
}

python_install_all() {
	distutils-r1_python_install_all

	# Shared by the systemd unit and the OpenRC script. It can hold a
	# Redmine API key.
	insinto /etc/${PN}
	doins "${FILESDIR}"/${PN}.conf
	fperms 0600 /etc/${PN}/${PN}.conf
	fperms 0700 /etc/${PN}

	insinto /etc/logrotate.d
	newins "${FILESDIR}"/${PN}.logrotate ${PN}

	systemd_dounit "${FILESDIR}"/${PN}.service
	newinitd "${FILESDIR}"/${PN}.initd ${PN}
}

pkg_postinst() {
	elog "mcp-redmine is configured through the environment:"
	elog "  REDMINE_URL=https://redmine.example.com"
	elog "  REDMINE_API_KEY=<API key>            (My account -> API access key)"
	elog "  REDMINE_REQUEST_INSTRUCTIONS=/path/to/instructions.md   (optional)"
	elog "  REDMINE_ALLOWED_DIRECTORIES=/tmp     (optional, for attachments)"
	elog "  REDMINE_READ_ONLY=1                  (optional, refuses non-GET requests)"
	elog "Register it in your MCP client, e.g. for Claude Code:"
	elog "  claude mcp add redmine -e REDMINE_URL=... -e REDMINE_API_KEY=... -- mcp-redmine"
	elog
	elog "To run it as a shared service (streamable HTTP on 127.0.0.1:8000):"
	elog "  1. Set REDMINE_URL in /etc/${PN}/${PN}.conf"
	elog "  2. systemctl enable --now ${PN}, or rc-update add ${PN} default"
	elog "Each client then sends its own Redmine API key:"
	elog "  claude mcp add --transport http redmine http://127.0.0.1:8000/mcp \\"
	elog "    --header 'X-Redmine-API-Key: <API key>'"
}
