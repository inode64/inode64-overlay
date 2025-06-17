# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker systemd tmpfiles

MY_P="ONLYOFFICE-DocumentServer-"${PV}""

DESCRIPTION="Online office suite comprising viewers and editors for texts, spreadsheets and presentations (binary version)"
HOMEPAGE="https://www.onlyoffice.com/"
SRC_URI="
	https://github.com/ONLYOFFICE/DocumentServer/releases/download/v"${PV}"/onlyoffice-documentserver_amd64.deb
		-> "${P}"_amd64.deb
"

S="${WORKDIR}"
LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror strip test"

DEPEND="
	acct-group/ds
	acct-user/ds
"
RDEPEND="${DEPEND}
	app-admin/sudo
	dev-db/postgresql
	dev-db/redis
	net-misc/rabbitmq-server
	www-servers/nginx
"

QA_PREBUILT="*"

src_prepare() {
	default

	sed -i 's|/var/www/onlyoffice|/usr/share/onlyoffice|g' \
		etc/onlyoffice/documentserver/production-linux.json \
		usr/lib/systemd/system/*.service usr/bin/*.sh || die

	rm -rf var/www/onlyoffice/documentserver/server/schema/{dameng,mysql} || die
}

src_install() {
	insinto /etc/logrotate.d/
	doins etc/onlyoffice/documentserver/logrotate/ds.conf

	insinto /etc/nginx/conf.d/
	newins "${FILESDIR}/nginx.conf" onlyoffice-documentserver.conf

	insinto /etc/onlyoffice/documentserver
	doins etc/onlyoffice/documentserver/{default.json,production-linux.json}
	insinto /etc/onlyoffice/documentserver/log4js
	doins etc/onlyoffice/documentserver/log4js/production.json

	insinto /usr/bin
	doins usr/bin/{documentserver-generate-allfonts.sh,documentserver-jwt-status.sh,documentserver-pluginsmanager.sh,documentserver-flush-cache.sh}

	insinto /usr/share/onlyoffice
	doins -r var/www/onlyoffice/documentserver

	keepdir /usr/share/onlyoffice/documentserver/fonts

	fperms +x /usr/bin/{documentserver-generate-allfonts.sh,documentserver-jwt-status.sh,documentserver-pluginsmanager.sh,documentserver-flush-cache.sh}

	fperms +x /usr/share/onlyoffice/documentserver/npm/json
	fperms +x /usr/share/onlyoffice/documentserver/server/DocService/docservice
	fperms +x /usr/share/onlyoffice/documentserver/server/FileConverter/bin/{docbuilder,x2t}
	fperms +x /usr/share/onlyoffice/documentserver/server/FileConverter/converter
	fperms +x /usr/share/onlyoffice/documentserver/server/Metrics/metrics
	fperms +x /usr/share/onlyoffice/documentserver/server/Metrics/node_modules/modern-syslog/build/Release/core.node
	fperms +x /usr/share/onlyoffice/documentserver/server/tools/{allfontsgen,allthemesgen,pluginsmanager}

	fowners ds:ds -R /usr/share/onlyoffice/documentserver

	local lib
	for lib in libDjVuFile.so libDocxRenderer.so libEpubFile.so libFb2File.so libHWPFile.so libHtmlFile2.so \
		libIWorkFile.so libPdfFile.so libUnicodeConverter.so libXpsFile.so libdoctrenderer.so libgraphics.so \
		libkernel.so libkernel_network.so libicudata.so.58 libicuuc.so.58; do
		dosym -r "/usr/share/onlyoffice/documentserver/server/FileConverter/bin/${lib}" "/usr/$(get_libdir)/${lib}" || die
		fperms +x "/usr/share/onlyoffice/documentserver/server/FileConverter/bin/${lib}" || die
	done

	# Generate an env.d entry
	insinto /etc/env.d/binutils
	cat <<-EOF >"${T}"/99onlyoffice
		    NODE_ENV="production-linux"
		    NODE_CONFIG_DIR="/etc/onlyoffice/documentserver"
		    NODE_DISABLE_COLORS="1"
		    APPLICATION_NAME="ONLYOFFICE"
	EOF
	doenvd "${T}"/99onlyoffice

	newinitd "${FILESDIR}/ds-converter.initd" ds-converter
	newinitd "${FILESDIR}/ds-docservice.initd" ds-docservice
	newinitd "${FILESDIR}/ds-metrics.initd" ds-metrics

	systemd_dounit usr/lib/systemd/system/ds-converter.service
	systemd_dounit usr/lib/systemd/system/ds-docservice.service
	systemd_dounit usr/lib/systemd/system/ds-metrics.service

	newtmpfiles "${FILESDIR}"/onlyoffice-documentserver.tmpfiles.conf onlyoffice-documentserver.conf
}

pkg_postinst() {
	tmpfiles_process onlyoffice-documentserver.conf

	einfo
	einfo "Execute the following command to setup for generate all fonts"
	einfo "> emerge --config =${CATEGORY}/${PF}"
	einfo

	einfo
	einfo "Execute the following commands to setup for PostgreSQL"
	einfo
	einfo "> sudo -i -u postgres psql -c \"CREATE USER onlyoffice WITH PASSWORD 'onlyoffice';\""
	einfo "> sudo -i -u postgres psql -c \"CREATE DATABASE onlyoffice OWNER onlyoffice;\""
	einfo "> psql -hlocalhost -Uonlyoffice -d onlyoffice -f ${EROOT}/usr/share/onlyoffice/documentserver/server/schema/postgresql/createdb.sql"
	einfo
	einfo "Fill in PORT, SERVER_NAME, SSL_CERT and SSL_KEY. in ${EROOT}/etc/nginx/sites-available/onlyoffice-documentserver"
}

pkg_config() {
	"${EROOT}/usr/bin/documentserver-generate-allfonts.sh"
}
