# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 git-r3

DESCRIPTION="OpenTelemetry Protobuf encoding"
HOMEPAGE="https://github.com/open-telemetry/opentelemetry-python"
EGIT_REPO_URI="https://github.com/open-telemetry/opentelemetry-python.git"
S="${WORKDIR}/${P}/explorer/${PN}"

LICENSE="Apache-2.0"
SLOT=0

RDEPEND="dev-python/opentelemetry-proto[${PYTHON_USEDEP}]"
BDEPEND="test? ( dev-python/opentelemetry-sdk[${PYTHON_USEDEP}]
		dev-python/opentelemetry-test-utils[${PYTHON_USEDEP}] )"

distutils_enable_tests unittest
