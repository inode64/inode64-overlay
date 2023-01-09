# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{8..11} )
inherit distutils-r1

DESCRIPTION="A Python parser for the lspci command from the pciutils package"
HOMEPAGE="
		https://pypi.org/project/pylspci
		https://gitlab.com/Lucidiot/pylspci
"
SRC_URI="https://gitlab.com/Lucidiot/${PN}/-/archive/${PV}/${P}.tar.bz2"

SLOT="0"
LICENSE="GPL-3"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86 ~amd64-linux ~x86-linux"

RDEPEND=">=dev-python/cached-property-1.5.1"
DEPEND="${RDEPEND}"

distutils_enable_tests setup.py
