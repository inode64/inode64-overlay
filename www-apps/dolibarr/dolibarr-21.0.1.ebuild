# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit webapp

DESCRIPTION="Dolibarr ERP CRM: modern software package to manage your company"
HOMEPAGE="https://dolibarr.org/"
SRC_URI="https://github.com/Dolibarr/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

S=${WORKDIR}/${PN}

LICENSE="GPL-3"
KEYWORDS="~amd64 ~x86"

IUSE="+mysql postgres sqlite"
REQUIRED_USE="|| ( mysql postgres sqlite )"

RDEPEND="dev-lang/php[calendar,curl,gd,intl,json(+),mysql?,postgres?,session,simplexml,sqlite?,xml,zip]
	virtual/httpd-php"

pkg_setup() {
	webapp_pkg_setup
}

src_install() {
	webapp_src_preinst

	insinto "${MY_HTDOCSDIR}"
	doins -r .
	keepdir "${MY_HTDOCSDIR}"/data

	webapp_serverowned -R "${MY_HTDOCSDIR}"/apps
	webapp_serverowned -R "${MY_HTDOCSDIR}"/data
	webapp_serverowned -R "${MY_HTDOCSDIR}"/config
	webapp_configfile "${MY_HTDOCSDIR}"/.htaccess

	webapp_src_install
}
