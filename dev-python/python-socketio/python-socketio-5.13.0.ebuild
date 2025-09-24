# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1 pypi

DESCRIPTION="Python implementation of the Socket.IO realtime server"
HOMEPAGE="
    https://github.com/miguelgrinberg/python-socketio/
    https://pypi.org/project/python-socketio
    https://python-socketio.readthedocs.io/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="
    >=dev-python/aiohttp-3.4[${PYTHON_USEDEP}]
    >=dev-python/bidict-0.21.0[${PYTHON_USEDEP}]
    >=dev-python/python-engineio-4.11.0[${PYTHON_USEDEP}]
    >=dev-python/requests-2.21.0[${PYTHON_USEDEP}]
    >=dev-python/websocket-client-0.54.0[${PYTHON_USEDEP}]
"
BDEPEND="
    test? (
	${RDEPEND}
	dev-python/msgpack[${PYTHON_USEDEP}]
	dev-python/pytest-asyncio[${PYTHON_USEDEP}]
	dev-python/uvicorn[${PYTHON_USEDEP}]
    )
"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

distutils_enable_sphinx docs
distutils_enable_tests pytest
