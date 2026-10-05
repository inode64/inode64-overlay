# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
DISTUTILS_USE_PEP517=hatchling
inherit distutils-r1 pypi

DESCRIPTION="A high-level Web Crawling and Web Scraping framework"
HOMEPAGE="https://scrapy.org/"

LICENSE="BSD"
SLOT=0
KEYWORDS="~amd64 ~arm64"

# itemloaders supplies itemadapter and parsel (including cssselect and packaging).
# pyopenssl supplies cryptography; twisted[http2] supplies h2 and priority.
RDEPEND="
	>=app-arch/brotli-1.2.0[python,${PYTHON_USEDEP}]
	>=dev-python/aiohttp-3.13.3[${PYTHON_USEDEP}]
	>=dev-python/charset-normalizer-3.4.0[${PYTHON_USEDEP}]
	>=dev-python/defusedxml-0.7.1[${PYTHON_USEDEP}]
	>=dev-python/itemloaders-1.0.1[${PYTHON_USEDEP}]
	>=dev-python/lxml-4.6.4[${PYTHON_USEDEP}]
	>=dev-python/platformdirs-2.0.0[${PYTHON_USEDEP}]
	>=dev-python/protego-0.1.15[${PYTHON_USEDEP}]
	>=dev-python/pydispatcher-2.0.5[${PYTHON_USEDEP}]
	>=dev-python/pyopenssl-24.3.0[${PYTHON_USEDEP}]
	>=dev-python/queuelib-1.6.1[${PYTHON_USEDEP}]
	>=dev-python/service-identity-24.2.0[${PYTHON_USEDEP}]
	dev-python/tldextract[${PYTHON_USEDEP}]
	>=dev-python/twisted-21.7.0[http2,${PYTHON_USEDEP}]
	>=dev-python/w3lib-2.1.1[${PYTHON_USEDEP}]
	>=dev-python/zope-interface-5.1.0[${PYTHON_USEDEP}]
	$(python_gen_cond_dep '
		>=dev-python/backports-zstd-1.3.0[${PYTHON_USEDEP}]
	' python3_{12,13})
"
BDEPEND="
	test? (
		dev-python/botocore[${PYTHON_USEDEP}]
		dev-python/pexpect[${PYTHON_USEDEP}]
		>=dev-python/pyftpdlib-2.0.1[${PYTHON_USEDEP}]
		dev-python/uvloop[${PYTHON_USEDEP}]
	)
"

EPYTEST_PLUGINS=( pytest-rerunfailures pytest-twisted )
distutils_enable_tests pytest

EPYTEST_DESELECT=(
	# these require (local) network access
	tests/test_command_check.py
	tests/test_feedexport.py
	tests/test_pipeline_files.py::TestFTPFileStore::test_persist
	# Flaky test: https://github.com/scrapy/scrapy/issues/6193
	tests/test_crawl.py::CrawlTestCase::test_start_requests_laziness
	# Missing dependencies
	tests/test_spidermiddleware_output_chain.py
	)
EPYTEST_IGNORE=( docs )
