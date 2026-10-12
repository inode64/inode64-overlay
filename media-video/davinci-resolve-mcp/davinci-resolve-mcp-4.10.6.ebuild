# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )

inherit optfeature python-single-r1

DESCRIPTION="MCP server and local control panel for DaVinci Resolve"
HOMEPAGE="https://github.com/samuelgursky/davinci-resolve-mcp"
SRC_URI="https://github.com/samuelgursky/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"
RESTRICT="!test? ( test )"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

# MCP 2.2.0 was tested: it removed the mcp.server.fastmcp API used upstream.
RDEPEND="
	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		>=dev-python/mcp-1.30.0[${PYTHON_USEDEP}]
		<dev-python/mcp-2[${PYTHON_USEDEP}]
	')
"
DEPEND="${RDEPEND}"
BDEPEND="test? ( $(python_gen_cond_dep 'dev-python/pytest[${PYTHON_USEDEP}]') )"

PATCHES=(
	"${FILESDIR}/${PN}-4.8.26-user-state.patch"
	"${FILESDIR}/${PN}-4.8.26-offline-path-tests.patch"
)

src_prepare() {
	default
	sed -e "s|@DATADIR@|${EPREFIX}/usr/share/${PN}|g" \
		-e "s|@RESOLVE_HOME@|${EPREFIX}/opt/resolve|g" \
		-e 's|@MODULE@|src.server|g' \
		"${FILESDIR}/${PN}.py" > "${T}/${PN}" || die
	sed -e "s|@DATADIR@|${EPREFIX}/usr/share/${PN}|g" \
		-e "s|@RESOLVE_HOME@|${EPREFIX}/opt/resolve|g" \
		-e 's|@MODULE@|src.control_panel|g' \
		"${FILESDIR}/${PN}.py" > "${T}/${PN}-control-panel" || die
}

src_test() {
	local -x DAVINCI_RESOLVE_MCP_STATE_DIR="${T}/state"
	local -x DAVINCI_RESOLVE_MCP_UPDATE_CHECK=0
	# Offline tests: never launch Resolve or access an operator's projects.
	"${EPYTHON}" -m pytest -q \
		tests/test_mcp_prompts.py tests/test_mcp_resources.py \
		tests/test_mcp_transport.py tests/test_mcp_transport_host_allowlist.py \
		tests/test_knowledge_tool.py tests/test_threaded_tool_dispatch.py \
		tests/test_platform_paths.py || die "Offline tests failed"
}

src_install() {
	local appdir=/usr/share/${PN}
	insinto "${appdir}"
	doins -r src docs scripts
	doins README.md package.json
	insinto "${appdir}/.agents"
	doins -r .agents/skills
	python_optimize "${ED}${appdir}/src"
	python_newscript "${T}/${PN}" "${PN}"
	python_newscript "${T}/${PN}-control-panel" "${PN}-control-panel"
	dodoc "${FILESDIR}/README.gentoo"
}

pkg_postinst() {
	einfo "Run davinci-resolve-mcp as the desktop user running Resolve."
	einfo "Enable Preferences > General > External scripting using > Local."
	einfo "MCP client command: ${EPREFIX}/usr/bin/${PN} (stdio; no arguments required)."
	einfo "Use ${PN}-control-panel for the local browser interface."
	optfeature "legacy scripting SDK and API documentation" "media-video/davinci-resolve-studio[developer]"
	optfeature "media analysis using ffmpeg and ffprobe" media-video/ffmpeg
}
