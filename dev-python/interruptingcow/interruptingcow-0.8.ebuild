# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..11} )

inherit distutils-r1

DESCRIPTION="A watchdog that interrupts long running code"
HOMEPAGE="https://bitbucket.org/evzijst/interruptingcow"
SRC_URI="
	https://files.pythonhosted.org/packages/64/3a/1e58f9e38acb38d42584872150400ddafb6d669700fd9b99f079adce00f6/${P}.tar.gz
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
