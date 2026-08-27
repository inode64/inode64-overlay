# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="Instrumentation Tools for OpenTelemetry Python"
HOMEPAGE="https://github.com/open-telemetry/opentelemetry-python-contrib"

LICENSE="Apache-2.0"
SLOT=0
KEYWORDS="~amd64 ~x86"

RDEPEND="dev-python/opentelemetry-api[${PYTHON_USEDEP}]
	dev-python/opentelemetry-semantic-conventions[${PYTHON_USEDEP}]
	dev-python/packaging[${PYTHON_USEDEP}]
	dev-python/wrapt[${PYTHON_USEDEP}]"
BDEPEND="test? ( dev-python/opentelemetry-test-utils[${PYTHON_USEDEP}] )"

EPYTEST_PLUGINS=()
distutils_enable_tests pytest

EPYTEST_DESELECT=(
	# AssertionError: False is not true
	tests/test_utils.py::UnwrapTestCase::test_can_unwrap_object_attribute
	tests/test_utils.py::UnwrapTestCase::test_can_unwrap_object_attribute_as_string
	tests/test_utils.py::UnwrapTestCase::test_raises_import_error_if_cannot_find_module
	tests/test_utils.py::UnwrapTestCase::test_raises_import_error_if_cannot_find_object
	tests/test_utils.py::UnwrapTestCase::test_raises_import_error_if_path_not_well_formed
)
