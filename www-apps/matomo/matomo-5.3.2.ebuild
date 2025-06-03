# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"

inherit webapp

DESCRIPTION="Matomo is the leading Free/Libre open analytics platform."
HOMEPAGE="https://matomo.org"
SRC_URI="https://github.com/matomo-org/matomo/releases/download/${PV}/${P}.tar.gz"

S="${WORKDIR}/${PN}"
LICENSE="GPL-3"
KEYWORDS="~amd64 ~arm64"

DEPEND="dev-php/composer"
RDEPEND=">=dev-lang/php-7.4[gd,pdo]
	virtual/mysql
	virtual/httpd-php"

src_install() {
	webapp_src_preinst

	insinto "${MY_HTDOCSDIR}"
	doins -r .

	keepdir "${MY_HTDOCSDIR}/config"
	keepdir "${MY_HTDOCSDIR}/js"
	keepdir "${MY_HTDOCSDIR}/tmp"

	webapp_serverowned "${MY_HTDOCSDIR}/js"
	webapp_serverowned -R "${MY_HTDOCSDIR}/tmp"
	webapp_serverowned -R "${MY_HTDOCSDIR}/matomo.js"

	# make executable for cli
	fperms 755 "${MY_HTDOCSDIR}/console"

	webapp_src_install
}
