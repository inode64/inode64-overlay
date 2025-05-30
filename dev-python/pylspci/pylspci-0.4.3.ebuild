# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )
inherit distutils-r1 pypi

DESCRIPTION="A Python parser for the lspci command from the pciutils package"
HOMEPAGE="
		https://pypi.org/project/pylspci/
		https://tildegit.org/lucidiot/pylspci
"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~ppc64 ~x86"

RDEPEND=">=dev-python/cached-property-1.5.1"

distutils_enable_tests pytest
