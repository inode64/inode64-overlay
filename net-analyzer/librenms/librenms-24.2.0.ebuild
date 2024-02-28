# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="A fully featured network monitoring system"
HOMEPAGE="https://www.librenms.org"

if [[ "${PV}" != 9999 ]]; then
	SRC_URI="https://github.com/${PN}/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64"
else
	inherit git-r3
	EGIT_REPO_URI="https://github.com/${PN}/${PN}"
fi

LICENSE="GPL-3+"
SLOT="0"
IUSE="amqp apache2 ipmi ldap nginx postgres radius redis"
REQUIRED_USE="^^ ( apache2 nginx )"

DEPEND="
	acct-group/librenms
	acct-user/librenms
"

BDEPEND="
	dev-php/composer
"
RDEPEND="${BDEPEND}
	amqp? ( dev-php/pecl-amqp )
	app-admin/sudo
	>=dev-lang/php-8.1:*[bcmath,cli,curl,fpm,gd,mysqli,ldap?,pdo,session,simplexml,snmp,xml,zip]
	dev-php/pecl-imagick
	dev-php/pecl-memcache
	ipmi? ( sys-apps/ipmitool )
	media-gfx/graphviz
	>=net-analyzer/fping-4.2[suid]
	net-analyzer/mtr
	net-analyzer/net-snmp
	net-analyzer/nmap
	net-analyzer/rrdtool[rrdcached]
	net-misc/whois
	radius? ( dev-php/pecl-radius )
	redis? ( dev-db/redis )
	sys-apps/acl
	virtual/cron
	virtual/mysql
	dev-python/command-runner
	dev-python/pip
	dev-python/psutil
	dev-python/pymysql
	dev-python/python-dotenv
	dev-python/python-memcached
	dev-python/redis
"

LIBRENMS_HOME="/opt/librenms"

pkg_setup() {
	use nginx && usermod -a -G librenms nginx
	use apache2 && usermod -a -G librenms apache
}

src_compile() {
	return
}

src_install() {
	diropts -m 0770
	insinto ${LIBRENMS_HOME}

	dosym ${LIBRENMS_HOME}/lnms /usr/bin/lnms

	insinto /etc/logrotate.d/
	newins misc/librenms.logrotate librenms

	insinto /etc/bash_completion.d
	doins misc/lnms-completion.bash

	dodoc AUTHORS.md CHANGELOG.md CODE_OF_CONDUCT.md CONTRIBUTING.md README.md SECURITY.md

	// Remove developer files
	rm *.md LICENSE.txt || die
	find -type f -regex '.*\.gitignore$' -delete || die
	find -type d -iwholename '*.github' -exec rm -rvf {} + || die
	rm {.codeclimate.yml,.editorconfig,.git-blame-ignore-revs,.php-cs-fixer.php,.scrutinizer.yml,.styleci.yml,mkdocs.yml} || die
	rm {phpstan-baseline-deprecated.neon,phpstan-baseline.neon,phpstan-deprecated.neon,phpstan.neon,phpunit.xml} || die
	rm -rf {.github,doc,licenses,tests} || die
	cp -r . "${D}"${LIBRENMS_HOME}

	fowners librenms:librenms -R ${LIBRENMS_HOME}
}

pkg_postinst() {
	einfo
	einfo "Check final steps in https://docs.librenms.org/Installation/"
	einfo
	einfo
	einfo "You have to configure your MySQL instance to create"
	einfo "and grant some privileges to finish the installation."
	einfo "You can run the following commands at the MySQL prompt: "
	einfo
	einfo "> CREATE USER 'librenms'@'localhost' IDENTIFIED BY 'password';"
	einfo "> CREATE DATABASE librenms CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
	einfo "> GRANT ALL PRIVILEGES ON librenms.* TO 'librenms'@'localhost';"
	einfo "> FLUSH PRIVILEGES;"
	einfo
	sleep 5
	einfo
	einfo "Run 'emerge --config =${CATEGORY}/${PF}' to finish setup."
	einfo
}

pkg_config() {
	einfo "Installing cronjobs ..."
	crontab -u librenms "${EROOT}"/${LIBRENMS_HOME}/dist/librenms.cron || die

	einfo "Installing composer deps ..."
	sudo -u librenms /opt/librenms/scripts/composer_wrapper.php install --no-dev
	if [ -e ${LIBRENMS_HOME}/config.php ]; then
		einfo "Updating existing installation ..."
		sudo -u librenms /opt/librenms/lnms migrate

		einfo "Validation installation ..."
		sudo -u librenms /opt/librenms/validate.php
	fi

	einfo "All done."
}
