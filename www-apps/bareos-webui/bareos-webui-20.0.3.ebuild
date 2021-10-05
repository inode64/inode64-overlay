# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CMAKE_WARN_UNUSED_CLI=no

inherit cmake eutils webapp

MY_PV=${PV/_/-}
MY_PN="bareos"
MY_P="${MY_PN}-${MY_PV}"

DESCRIPTION="Featureful client/server network backup suite"
HOMEPAGE="https://www.bareos.org/"
SRC_URI="https://github.com/${MY_PN}/${MY_PN}/archive/Release/${MY_PV}.tar.gz -> ${MY_P}.tar.gz"
RESTRICT="mirror"

LICENSE="AGPL-3"
KEYWORDS="~amd64 ~x86"

IUSE="mysql +postgres"
DEPEND=""
RDEPEND="${DEPEND}
	dev-lang/php[bzip2,ctype,curl,fileinfo,filter,gd,iconv,intl,json,mhash,mysql?,nls,pdo,postgres?,session,simplexml,ssl,xml,xmlreader,xmlwriter,zip]
	virtual/httpd-php
"
need_httpd_cgi

S=${WORKDIR}/${MY_PN}-Release-${PV}/webui

pkg_setup() {
	webapp_pkg_setup
}

src_install() {
	webapp_src_preinst

	dodoc README.md
	webapp_server_configfile nginx "${S}/install/nginx/bareos-webui.conf" bareos-webui.include
	webapp_server_configfile apache "${S}/install/apache/bareos-webui.conf" bareos-webui.conf

	insinto "${MY_HTDOCSDIR}"
	pushd "${BUILD_DIR}" >/dev/null || die
	DESTDIR="${D}/${MY_HTDOCSDIR}" ${CMAKE_MAKEFILE_GENERATOR} install "$@" || die "died running ${CMAKE_MAKEFILE_GENERATOR} install"
	popd >/dev/null || die

	mv "${D}/${MY_HTDOCSDIR}"/usr/share/bareos-webui/* "${D}/${MY_HTDOCSDIR}"/
	rmdir "${D}/${MY_HTDOCSDIR}"/usr/share/bareos-webui

	webapp_configfile "${MY_HTDOCSDIR}"/config/application.config.php
	webapp_configfile "${MY_HTDOCSDIR}"/config/autoload/global.php

	find "${D}/${MY_HTDOCSDIR}" -type f -name '*.in' -delete

	mv "${D}/${MY_HTDOCSDIR}/etc" "${D}/etc"
	rm -rf "${D}/etc/httpd"

	webapp_src_install
}
