# Copyright 1999-2026 Gentoo Authors
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

IUSE="amqp ipmi ldap radius redis"

DEPEND="
	acct-user/librenms
"

RDEPEND="${DEPEND}
	amqp? ( dev-php/pecl-amqp )
	app-admin/sudo
	>=dev-lang/php-8.2:*[bcmath,cli,ctype,curl,fileinfo,filter,fpm,gd,ldap?,mysql,mysqli,pdo,phar,posix,session,simplexml,snmp,sockets,ssl,tokenizer,unicode,xml,zip,zlib]
	dev-php/pecl-imagick
	dev-php/pecl-memcache
	ipmi? ( sys-apps/ipmitool )
	media-gfx/graphviz
	>=net-analyzer/fping-4.2[suid]
	net-analyzer/mtr
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
	dev-python/pymysql
	dev-python/python-dotenv
	dev-python/python-memcached
	dev-python/redis
"

LIBRENMS_HOME="/opt/librenms"

src_compile() {
	return
}

src_install() {
	diropts -m 0770
	dodir "${LIBRENMS_HOME}"

	dosym "${LIBRENMS_HOME}/lnms" /usr/bin/lnms

	insinto /etc/logrotate.d/
	newins misc/librenms.logrotate librenms

	insinto /etc/bash_completion.d
	doins misc/lnms-completion.bash

	dodoc AUTHORS.md CHANGELOG.md CODE_OF_CONDUCT.md CONTRIBUTING.md README.md SECURITY.md

	# Remove developer files
	rm *.md LICENSE.txt || die
	find -type d -iwholename '*.github' -exec rm -rvf {} + || die
	rm {.editorconfig,.git-blame-ignore-revs,mkdocs.yml} || die
	rm {phpstan-baseline-deprecated.neon,phpstan-legacy.neon,phpstan-deprecated.neon,phpstan.neon,phpunit.xml} || die
	rm -rf {.github,doc,licenses,tests} || die
	cp -r . "${ED}${LIBRENMS_HOME}" || die "Failed to install LibreNMS"

	fowners -R librenms:librenms "${LIBRENMS_HOME}"
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
	einfo "> CREATE DATABASE librenms CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
	einfo "> GRANT ALL PRIVILEGES ON librenms.* TO 'librenms'@'localhost';"
	einfo "> FLUSH PRIVILEGES;"
	einfo
	sleep 5
	einfo
	einfo "Run 'emerge --config =${CATEGORY}/${PF}' to finish setup."
	einfo
}

pkg_config() {
	# Only on the first setup: on every update it would wipe local changes to
	# the crontab, such as a healthchecks wrapper around daily.sh. Test the
	# output, not the exit code: fcrontab -l returns 0 for a user without one.
	local cron="${EROOT}${LIBRENMS_HOME}/dist"
	if [[ -n $(crontab -u librenms -l 2>/dev/null) ]]; then
		ewarn "librenms already has a crontab, leaving it untouched."
		ewarn "Compare it with ${cron}/librenms.cron and librenms-scheduler.cron"
	else
		einfo "Installing cronjobs ..."
		# librenms.cron has the user column of /etc/cron.d, which only fcrontab
		# tolerates in a user crontab. Upstream ships the scheduler as a systemd
		# timer plus this cron line; without it validate.php fails and the
		# maintenance tasks never run.
		sed -E 's/^(([^#[:space:]]+[[:space:]]+){5})librenms[[:space:]]+/\1/' \
			"${cron}"/librenms{,-scheduler}.cron | crontab -u librenms - || die
	fi

	einfo "Installing composer deps ..."
	sudo -u librenms /opt/librenms/scripts/composer_wrapper.php install --no-dev --ansi

	einfo "Updating existing installation ..."
	sudo -u librenms /opt/librenms/lnms migrate

	einfo "Validation installation ..."
	sudo -u librenms /opt/librenms/validate.php

	einfo "All done."
}
