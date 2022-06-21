# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{8..11} )
inherit distutils-r1

DESCRIPTION="Platform agnostic command and shell execution tool"
HOMEPAGE="https://pypi.org/project/command-runner/
https://github.com/netinvent/command_runner"
MY_PN="${PN/-/_}"
MY_P="${MY_PN}-${PV}"
SRC_URI="mirror://pypi/${MY_PN:0:1}/${MY_PN}/${MY_P}.tar.gz"

S="${WORKDIR}/${MY_P}"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=">=dev-python/psutil-5.6.0"
RDEPEND="${DEPEND}"
BDEPEND=""
