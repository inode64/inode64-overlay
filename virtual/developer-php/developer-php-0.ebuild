# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Tools needed for developing applications in php"
SLOT="${PV}"
KEYWORDS="~amd64"

RDEPEND="
		|| ( dev-util/phpstorm app-editors/vscode )
		dev-lang/php
		dev-php/composer
		dev-php/PHP_CodeSniffer
		dev-php/xdebug
		dev-ruby/sass
		dev-util/uglifyjs
		net-libs/nodejs
		sys-apps/yarn
"
