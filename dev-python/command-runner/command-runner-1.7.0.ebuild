# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PN="${PN/-/_}"
MY_P="${MY_PN}-${PV}"

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..13} python3_13t pypy3 )
inherit distutils-r1

DESCRIPTION="Platform agnostic command and shell execution tool"
HOMEPAGE="https://pypi.org/project/command-runner/
	https://github.com/netinvent/command_runner"
SRC_URI="https://github.com/netinvent/${MY_PN}/archive/refs/tags/v${PV}.tar.gz  -> ${P}.gh.tar.gz"

S="${WORKDIR}/${MY_P}"
LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND=">=dev-python/psutil-5.6.0"

DOCS=( CHANGELOG.md README.md )
