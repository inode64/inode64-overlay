# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..13} python3_13t pypy3 )

inherit distutils-r1 optfeature

DESCRIPTION="Radically simplified static file serving for Python web apps"
HOMEPAGE="https://github.com/evansd/whitenoise"
SRC_URI="https://github.com/evansd/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
	dev-python/django[${PYTHON_USEDEP}]
"
BDEPEND="
	test? (
		app-arch/brotli[python,${PYTHON_USEDEP}]
	)
"

distutils_enable_tests pytest
distutils_enable_sphinx docs \
	dev-python/furo

pkg_postinst() {
	optfeature "brotli compression" "app-arch/brotli[python]"
}
