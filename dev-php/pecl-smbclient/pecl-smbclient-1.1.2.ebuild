# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PHP_EXT_NAME="smbclient"
PHP_EXT_INI="yes"
PHP_EXT_ZENDEXT="no"
DOCS=( README.md )

USE_PHP="php7-4 php8-1 php8-2 php8-3 php8-4"

inherit php-ext-pecl-r3

DESCRIPTION="Provides support for CIFS/SMB via samba's libsmbclient library"
LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"

DEPEND="
	net-fs/samba[client]
"

RDEPEND="${DEPEND}
"
