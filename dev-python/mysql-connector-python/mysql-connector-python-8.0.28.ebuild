# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1

HOMEPAGE="https://dev.mysql.com/doc/connector-python/en/"
DESCRIPTION="MySQL driver written in Python"
LICENSE="MIT"
RESTRICT="test"
SLOT="0"
KEYWORDS="~amd64 ~x86"
SRC_URI="https://dev.mysql.com/get/Downloads/Connector-Python/${P}-src.tar.gz"

IUSE=""
DEPENDENCIES="dev-python/dnspython[${PYTHON_USEDEP}]"
BDEPEND="${DEPENDENCIES}"
RDEPEND="${DEPENDENCIES}"

S="${WORKDIR}/${P}-src"
