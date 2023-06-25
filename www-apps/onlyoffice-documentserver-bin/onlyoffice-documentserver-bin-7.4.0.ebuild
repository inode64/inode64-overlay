# Copyright 2020-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker systemd tmpfiles

MY_P="ONLYOFFICE-DocumentServer-"${PV}""

DESCRIPTION="Online office suite comprising viewers and editors for texts, spreadsheets and presentations (binary version)"
HOMEPAGE="https://www.onlyoffice.com/"
SRC_URI="
	amd64? (
		https://github.com/ONLYOFFICE/DocumentServer/releases/download/v"${PV}"/onlyoffice-documentserver_amd64.deb
		-> "${P}"_amd64.deb
	)
"

LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror strip test"

RDEPEND="
"
DEPEND="${RDEPEND}
	acct-group/ds
	acct-user/ds
"

S="${WORKDIR}"

QA_PREBUILT="*"

src_prepare() {
    default

    sed -i 's|/var/www/onlyoffice|/usr/share/onlyoffice|g' etc/onlyoffice/documentserver/production-linux.json usr/lib/systemd/system/*.service usr/bin/*.sh || die

    rm -rf var/www/onlyoffice/documentserver/server/schema/mysql || die
}

src_install() {
    insinto /etc/logrotate.d/
    doins etc/onlyoffice/documentserver/logrotate/ds.conf

    insinto /etc/onlyoffice/documentserver
    doins etc/onlyoffice/documentserver/{default.json,production-linux.json}
    insinto /etc/onlyoffice/documentserver/log4js
    doins etc/onlyoffice/documentserver/log4js/production.json

    insinto /usr/bin
    doins usr/bin/{documentserver-generate-allfonts.sh,documentserver-jwt-status.sh}

    insinto /usr/share/onlyoffice
    doins -r var/www/onlyoffice/documentserver

    fperms +x /usr/share/onlyoffice/documentserver/npm/json
    fperms +x /usr/share/onlyoffice/documentserver/server/DocService/docservice
    fperms +x /usr/share/onlyoffice/documentserver/server/FileConverter/bin/{docbuilder,x2t}
    fperms +x /usr/share/onlyoffice/documentserver/server/FileConverter/converter
    fperms +x /usr/share/onlyoffice/documentserver/server/Metrics/metrics
    fperms +x /usr/share/onlyoffice/documentserver/server/Metrics/node_modules/modern-syslog/build/Release/core.node
    fperms +x /usr/share/onlyoffice/documentserver/server/tools/{allfontsgen,allthemesgen,pluginsmanager}

    fowners ds:ds -R /usr/share/onlyoffice/documentserver

    local lib
    for lib in libPdfFile.so libXpsFile.so libDjVuFile.so libHtmlRenderer.so libkernel_network.so libDocxRenderer.so libdoctrenderer.so libHtmlFile2.so \
	     libUnicodeConverter.so libgraphics.so libFb2File.so libEpubFile.so libkernel.so libicudata.so.58 libicuuc.so.58; do
	    dosym -r "/usr/share/onlyoffice/documentserver/server/FileConverter/bin/${lib}" "/usr/$(get_libdir)/${lib}" || die
	    fperms +x "/usr/share/onlyoffice/documentserver/server/FileConverter/bin/${lib}" || die
    done

    systemd_dounit usr/lib/systemd/system/ds-converter.service
    systemd_dounit usr/lib/systemd/system/ds-docservice.service
    systemd_dounit usr/lib/systemd/system/ds-metrics.service
    dotmpfiles "${FILESDIR}"/onlyoffice-documentserver.tmpfiles
}

pkg_postinst() {
    tmpfiles_process onlyoffice-documentserver.tmpfiles
}