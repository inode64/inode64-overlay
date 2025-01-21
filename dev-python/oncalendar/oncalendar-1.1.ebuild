# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..13} python3_13t pypy3 )
inherit distutils-r1 pypi

DESCRIPTION="Systemd OnCalendar expression parser and evaluator"
HOMEPAGE="https://github.com/cuu508/oncalendar"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"

distutils_enable_tests pytest
