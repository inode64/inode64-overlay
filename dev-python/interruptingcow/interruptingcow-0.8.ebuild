# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..13} python3_13t pypy3 )
inherit distutils-r1 pypi

DESCRIPTION="A watchdog that interrupts long running code"
HOMEPAGE="https://bitbucket.org/evzijst/interruptingcow"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
