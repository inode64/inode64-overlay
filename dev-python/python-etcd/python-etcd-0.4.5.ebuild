# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYPI_NO_NORMALIZE=1
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 pypi

DESCRIPTION="A python client for etcd"
HOMEPAGE="
	https://github.com/jplana/python-etcd
	https://pypi.org/project/python-etcd/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-python/urllib3[${PYTHON_USEDEP}]
	dev-python/dnspython[${PYTHON_USEDEP}]
"
