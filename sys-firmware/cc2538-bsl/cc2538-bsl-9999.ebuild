# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..13} )
inherit python-single-r1

DESCRIPTION="Script to communicate with Texas Instruments CC13xx/CC2538/CC26xx Serial Boot Loader"
HOMEPAGE="https://github.com/JelmerT/cc2538-bsl"

if [[ ${PV} == *9999* ]]; then
	EGIT_REPO_URI="https://github.com/JelmerT/${PN}"
	inherit git-r3
else
	SRC_URI="https://github.com/JelmerT/${PN}/archive/refs/tags/v${PV}.tar.gz  -> ${P}.gh.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

LICENSE="BSD"
SLOT="0"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		dev-python/pyserial[${PYTHON_USEDEP}]
		dev-python/python-magic[${PYTHON_USEDEP}]
		dev-python/intelhex[${PYTHON_USEDEP}]
	')
"

DOCS=( README.md )

src_prepare() {
	default
}

src_compile() {
	default
}

src_install() {
	dosbin cc2538-bsl.py
}
