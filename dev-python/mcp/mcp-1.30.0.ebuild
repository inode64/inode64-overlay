# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 optfeature pypi

DESCRIPTION="Python SDK for Model Context Protocol"
HOMEPAGE="https://github.com/modelcontextprotocol/python-sdk"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/anyio-4.5[${PYTHON_USEDEP}]
	>=dev-python/cryptography-3.4.0[${PYTHON_USEDEP}]
	>=dev-python/httpx-0.27.1[${PYTHON_USEDEP}]
	>=dev-python/httpx-sse-0.4[${PYTHON_USEDEP}]
	>=dev-python/jsonschema-4.20.0[${PYTHON_USEDEP}]
	>=dev-python/pydantic-2.12.0[${PYTHON_USEDEP}]
	>=dev-python/pydantic-settings-2.5.2[${PYTHON_USEDEP}]
	>=dev-python/pyjwt-2.10.1[${PYTHON_USEDEP}]
	>=dev-python/python-dotenv-1.0.0[${PYTHON_USEDEP}]
	>=dev-python/python-multipart-0.0.9[${PYTHON_USEDEP}]
	>=dev-python/sse-starlette-1.6.1[${PYTHON_USEDEP}]
	>=dev-python/starlette-0.48.0[${PYTHON_USEDEP}]
	>=dev-python/typer-0.16.0[${PYTHON_USEDEP}]
	>=dev-python/typing-extensions-4.9.0[${PYTHON_USEDEP}]
	>=dev-python/typing-inspection-0.4.1[${PYTHON_USEDEP}]
	>=dev-python/uvicorn-0.31.1[${PYTHON_USEDEP}]
"
BDEPEND="
	dev-python/uv-dynamic-versioning[${PYTHON_USEDEP}]
	test? (
		dev-python/dirty-equals[${PYTHON_USEDEP}]
		dev-python/inline-snapshot[${PYTHON_USEDEP}]
	)
"

EPYTEST_PLUGINS=( anyio inline-snapshot )
distutils_enable_tests pytest

python_test() {
	# Exercise the FastMCP API used by reverse dependencies without network servers.
	epytest -o addopts= tests/server/fastmcp/test_func_metadata.py \
		tests/server/fastmcp/test_tool_manager.py \
		tests/server/fastmcp/prompts tests/server/fastmcp/resources
}

pkg_postinst() {
	optfeature "rich console output" dev-python/rich
	optfeature "WebSocket transport" dev-python/websockets
}
