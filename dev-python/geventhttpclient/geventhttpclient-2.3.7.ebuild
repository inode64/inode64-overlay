# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 pypi

DESCRIPTION="Coroutine-based network library"
HOMEPAGE="
    https://github.com/geventhttpclient/geventhttpclient
    https://pypi.org/project/geventhttpclient/
"
SRC_URI="https://github.com/${PN}/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
    app-arch/brotli[python]
    dev-python/certifi
    dev-python/gevent
    dev-python/urllib3
    net-libs/llhttp
"

PATCHES=(
    "${FILESDIR}"/update_llhttp.patch
)
