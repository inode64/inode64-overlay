# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
DISTUTILS_USE_PEP517=hatchling
inherit distutils-r1 pypi

DESCRIPTION="Utility to extract data from XML/HTML documents using XPath or CSS selectors"
HOMEPAGE="
	https://scrapy.org/
	https://pypi.org/project/parsel/
	https://github.com/scrapy/parsel
"

LICENSE="BSD"
SLOT=0
KEYWORDS="~amd64 ~arm64 ~x86"

RDEPEND="
	dev-python/cssselect[${PYTHON_USEDEP}]
	dev-python/jmespath[${PYTHON_USEDEP}]
	dev-python/lxml[${PYTHON_USEDEP}]
	dev-python/w3lib[${PYTHON_USEDEP}]
"
BDEPEND="
	test? (
		dev-python/psutil[${PYTHON_USEDEP}]
		dev-python/sybil[${PYTHON_USEDEP}]
	)
"

EPYTEST_PLUGINS=()
EPYTEST_DESELECT=(
	# Expect the XPath of older cssselect, 1.6.0 adds a contains(@class, ...)
	# prefilter. Fixed upstream in 893eb22ff (#384), after 1.12.1.
	tests/test_selector_csstranslator.py::test_css2xpath
	docs/usage.rst::line:1280,column:1
	docs/usage.rst::line:1282,column:1
)
distutils_enable_tests pytest

distutils_enable_sphinx docs \
	dev-python/sphinx-notfound-page \
	dev-python/sphinx-rtd-theme
