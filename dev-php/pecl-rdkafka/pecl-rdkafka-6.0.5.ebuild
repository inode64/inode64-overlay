# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PHP_EXT_NAME="rdkafka"
USE_PHP="php8-2 php8-3 php8-4"

inherit php-ext-pecl-r3

DESCRIPTION="AProduction-ready, stable Kafka client for PHP"
HOMEPAGE="https://github.com/arnaud-lb/php-rdkafka"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"

RDEPEND="dev-libs/librdkafka"
DEPEND="
	${RDEPEND}
"
