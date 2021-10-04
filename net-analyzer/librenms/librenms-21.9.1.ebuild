# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )
inherit python-single-r1

DESCRIPTION="A fully featured network monitoring system"
HOMEPAGE="https://www.librenms.org"

if [[ "${PV}" != 9999 ]] ; then
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

RDEPEND="
	app-arch/unzip
	dev-python/psutil
	dev-python/pymysql
	dev-python/pip
	dev-python/python-dotenv
	net-analyzer/nmap
	app-admin/sudo
	dev-php/composer
	redis? ( dev-db/redis )
	dev-python/redis-py
	>=dev-lang/php-7.3:*[bcmath,cli,curl,fpm,gd,json,mysqli,ldap?,pdo,session,snmp,xml,zip]
	dev-python/python-memcached
	amqp? ( dev-php/pecl-amqp )
	dev-php/pecl-imagick
	dev-php/pecl-memcache:7
	radius? ( dev-php/pecl-radius )
	>=net-analyzer/fping-4.2[suid,ipv6]
	net-analyzer/net-snmp
	net-analyzer/mtr
	net-analyzer/rrdtool
	net-misc/whois
	media-gfx/graphviz
	sys-apps/acl
	ipmi? ( sys-apps/ipmitool )
	dev-vcs/git
	virtual/mysql
"

DEPEND="${RDEPEND}
	acct-group/librenms
	acct-user/librenms
	app-shells/bash-completion
	virtual/cron
"

LIBRENMS_HOME="/opt/librenms"

pkg_setup() {
	use nginx && usermod -a -G librenms nginx
	use apache2 && usermod -a -G librenms apache

	python-single-r1_pkg_setup
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

	rm -r "${S}"/.github
	cp -r . "${D}"${LIBRENMS_HOME}

	python_optimize

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
	crontab -u librenms "${EROOT%/}"/${LIBRENMS_HOME}/librenms.nonroot.cron || die

	einfo "Installing composer deps ..."
	sudo -u librenms /opt/librenms/scripts/composer_wrapper.php install --no-dev
	if [ -e ${LIBRENMS_HOME}/config.php ]
	then
		einfo "Updating existing installation ..."
		sudo -u librenms /opt/librenms/lnms migrate

		einfo "Validation installation ..."
		sudo -u librenms /opt/librenms/validate.php
	fi

	einfo "All done."
}
