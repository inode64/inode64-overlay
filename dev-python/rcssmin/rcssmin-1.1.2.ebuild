# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( pypy3 python3_{10..13} )
inherit distutils-r1 pypi

DESCRIPTION="CSS minifier written in python"
HOMEPAGE="http://opensource.perlig.de/rcssmin/"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

distutils_enable_tests pytest

src_configure() {
    export SETUP_CEXT_REQUIRED=1
}

python_install_all() {
    distutils-r1_python_install_all
    mv "${D}/usr/share/doc/${PN}" "${D}/usr/share/doc/${PF}"
}
