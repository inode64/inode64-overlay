# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PN="CodeSniffer"

DESCRIPTION="Tokenizes PHP files and detects violations of a defined set of coding standards."
HOMEPAGE="https://github.com/PHPCSStandards/PHP_CodeSniffer"
SRC_URI="https://github.com/PHPCSStandards/PHP_CodeSniffer/archive/refs/tags/${PV}.tar.gz -> ${PN}-${PV}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

RDEPEND="dev-lang/php[tokenizer,xmlwriter,simplexml]"

src_install() {
	local SCRIPT
	# The PEAR eclass would install everything into the wrong location.
	insinto "/usr/share/php/${MY_PN}"
	doins -r src autoload.php
	doins requirements.php

	insinto "/usr/share/php/data/${MY_PN}"
	doins CodeSniffer.conf.dist
	# These load code via relative paths, so they have to be symlinked
	# and not dobin'd.
	exeinto "/usr/share/php/${MY_PN}/bin"
	for SCRIPT in phpcbf phpcs; do
		doexe "bin/${SCRIPT}"
		dosym "../share/php/${MY_PN}/bin/${SCRIPT}" "/usr/bin/${SCRIPT}"
	done
}
