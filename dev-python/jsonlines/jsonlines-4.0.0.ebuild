# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517="setuptools"
PYTHON_COMPAT=( python3_{10..12} )
inherit distutils-r1 pypi

DESCRIPTION="Library with helpers for the jsonlines file format"
HOMEPAGE="https://pypi.org/project/jsonlines/"
if [[ ${PV} == "9999" ]] ; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/wbolster/jsonlines"
else
	KEYWORDS="~amd64 ~arm64"
fi
LICENSE="BSD"
SLOT="0"
IUSE="test"
RDEPEND="dev-python/attrs[${PYTHON_USEDEP}]"
BDEPEND=" test? ( ${RDEPEND} )"

distutils_enable_tests pytest

python_prepare_all() {
	sed -r -e "/packages *=/ s|\[[^]]*\]\+||" -i -- setup.py

	distutils-r1_python_prepare_all
}
