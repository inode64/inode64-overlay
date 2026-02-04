# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"

PHP_EXT_NAME="opentelemetry"
PHP_EXT_INI="yes"
PHP_EXT_ZENDEXT="no"

USE_PHP="php8-2 php8-3"

inherit php-ext-pecl-r3

DESCRIPTION="OpenTelemetry auto-instrumentation support extension"
LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""
PHP_EXT_ECONF_ARGS=""