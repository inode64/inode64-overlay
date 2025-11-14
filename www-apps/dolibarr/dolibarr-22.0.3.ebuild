# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit webapp

DESCRIPTION="Dolibarr ERP CRM: modern software package to manage your company"
HOMEPAGE="https://www.dolibarr.org/"
SRC_URI="https://github.com/Dolibarr/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
KEYWORDS="~amd64 ~x86"

IUSE="+mysql postgres sqlite"
REQUIRED_USE="|| ( mysql postgres sqlite )"

RDEPEND="dev-lang/php[calendar,curl,gd,intl,json(+),mysql?,postgres?,session,simplexml,sqlite?,xml,zip]
	media-fonts/dejavu
	virtual/cron
	virtual/httpd-php"

DOCS="ChangeLog *.md"

pkg_setup() {
	webapp_pkg_setup
}

src_install() {
	webapp_src_preinst

	local DATA="${MY_HOSTROOTDIR}"/documents
	dodir ${DATA}
	webapp_serverowned -R "${DATA}"

	insinto "${MY_HTDOCSDIR}"
	doins -r htdocs/*
	keepdir "${MY_HTDOCSDIR}"/data

	webapp_src_install
}
