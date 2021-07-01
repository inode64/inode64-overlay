# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PHP_EXT_NAME="smbclient"
PHP_EXT_INI="yes"
PHP_EXT_ZENDEXT="no"
DOCS=( README.md )

USE_PHP="php7-3 php7-4 php8-0"

inherit php-ext-pecl-r3

KEYWORDS="~arm amd64 ~x86"

DESCRIPTION="Provides support for CIFS/SMB via samba's libsmbclient libary"
LICENSE="BSD-2"
SLOT="0"
IUSE=""

DEPEND="
	net-fs/samba[client]
"

RDEPEND="${DEPEND}
"
