# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
MY_VER=72

DESCRIPTION="Run just one instance of a command and its args at a time"
HOMEPAGE="https://launchpad.net/run-one"
SRC_URI="https://bazaar.launchpad.net/~run-one/run-one/trunk/tarball/${MY_VER} -> ${P}.tar.gz"

S="${WORKDIR}/~run-one/run-one/trunk"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="${DEPEND}
	sys-process/lsof
"

src_install() {
	exeinto /usr/bin
	doexe run-one
	doexe keep-one-running
	doexe run-one-constantly
	doexe run-one-until-failure
	doexe run-one-until-success
	doexe run-this-one

	doman run-one.1
}
