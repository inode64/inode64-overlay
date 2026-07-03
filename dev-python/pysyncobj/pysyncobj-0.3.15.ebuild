# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 pypi

DESCRIPTION="A library for replicating between multiple servers, based on raft protocol"
HOMEPAGE="
	https://github.com/bakwc/PySyncObj
	https://pypi.org/project/pysyncobj
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
