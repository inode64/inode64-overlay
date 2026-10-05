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

# httpx2 supplies anyio; mcp-types supplies pydantic and its typing dependencies.
# sse-starlette supplies starlette, which also requires python-multipart.
# PyJWT only suggests cryptography, so its crypto extra needs an explicit dep.
RDEPEND="
	dev-python/cryptography[${PYTHON_USEDEP}]
	>=dev-python/httpx2-2.10.0[${PYTHON_USEDEP}]
	>=dev-python/jsonschema-4.20.0[${PYTHON_USEDEP}]
	~dev-python/mcp-types-${PV}[${PYTHON_USEDEP}]
	>=dev-python/opentelemetry-api-1.28.0[${PYTHON_USEDEP}]
	>=dev-python/pyjwt-2.10.1[${PYTHON_USEDEP}]
	>=dev-python/python-dotenv-1.0.0[${PYTHON_USEDEP}]
	>=dev-python/sse-starlette-3.0.0[${PYTHON_USEDEP}]
	>=dev-python/typer-0.16.0[${PYTHON_USEDEP}]
	>=dev-python/uvicorn-0.31.1[${PYTHON_USEDEP}]
"
BDEPEND="
	dev-python/uv-dynamic-versioning[${PYTHON_USEDEP}]
"

# Tests require unpackaged logfire and pytest-examples.
RESTRICT="test"

pkg_postinst() {
	optfeature "support rich" dev-python/rich
	optfeature "support ws" dev-python/websockets
}
