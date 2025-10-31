# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYPI_NO_NORMALIZE=1
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 optfeature pypi

DESCRIPTION="py.test fixture for benchmarking code"
HOMEPAGE="https://github.com/ionelmc/pytest-benchmark"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="dev-python/pytest[${PYTHON_USEDEP}]
	dev-python/py-cpuinfo[${PYTHON_USEDEP}]"
BDEPEND="test? ( dev-python/aspectlib[${PYTHON_USEDEP}]
		dev-python/freezegun[${PYTHON_USEDEP}]
		dev-python/elasticsearch[${PYTHON_USEDEP}]
		dev-python/pygal[${PYTHON_USEDEP}]
		dev-python/pygaljs[${PYTHON_USEDEP}] )"

EPYTEST_XDIST=1
distutils_enable_tests pytest

EPYTEST_DESELECT=(
	# Failed: fnmatch:
	tests/test_cli.py::test_help
	tests/test_cli.py::test_help_compare
)

python_prepare_all() {
	# disable nbmake plugin
	sed -i '/--nbmake/d' pytest.ini || die "sed failed for pytest.ini"

	distutils-r1_python_prepare_all
}

pkg_postinst() {
	optfeature "integration with Elasticsearch" dev-python/elasticsearch
	optfeature "support of histogram" dev-python/pygal dev-python/pygaljs
	optfeature "support of aspect" dev-python/aspectlib
}
