# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..13} python3_13t pypy3 )
inherit distutils-r1 pypi

DESCRIPTION="Compresses linked and inline JavaScript or CSS into single cached files"
HOMEPAGE="https://django-compressor.readthedocs.io/"
S="${WORKDIR}/${P/-/_}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-python/django-appconf[${PYTHON_USEDEP}]
	dev-python/rcssmin[${PYTHON_USEDEP}]
	dev-python/rjsmin[${PYTHON_USEDEP}]
	dev-python/six[${PYTHON_USEDEP}]
"

python_test() {
	django-admin.py test --settings=compressor.test_settings compressor ||
	die "Tests failed with ${EPYTHON}"
}
