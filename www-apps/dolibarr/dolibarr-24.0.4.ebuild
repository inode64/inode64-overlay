# Copyright 1999-2026 Gentoo Authors
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

# USE=mysql needs mysqli: htdocs/core/db has no PDO driver
RDEPEND=">=dev-lang/php-7.2:*[calendar,curl,gd,intl,json(+),postgres?,session,simplexml,sqlite?,xml,zip]
	media-fonts/dejavu
	mysql? ( dev-lang/php[mysqli] )
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

	# scripts/ reaches htdocs/ through ../../, as in the upstream tree
	insinto "${MY_HOSTROOTDIR}"
	doins -r scripts

	einstalldocs

	webapp_src_install
}
