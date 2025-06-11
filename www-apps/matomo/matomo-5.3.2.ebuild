# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"

inherit webapp

DESCRIPTION="Matomo is the leading Free/Libre open analytics platform."
HOMEPAGE="https://matomo.org"
SRC_URI="https://github.com/matomo-org/matomo/releases/download/${PV}/${P}.tar.gz"

S="${WORKDIR}/${PN}"
LICENSE="GPL-3"
KEYWORDS="~amd64 ~arm64"

RDEPEND=">=dev-lang/php-7.4[ctype,gd,iconv,mysqli,pcntl,pdo,posix,zip]
	virtual/httpd-php"

pkg_setup() {
	webapp_pkg_setup
}

src_install() {
	webapp_src_preinst

	insinto "${MY_HTDOCSDIR}"
	doins -r .

	keepdir "${MY_HTDOCSDIR}/config"
	keepdir "${MY_HTDOCSDIR}/js"
	keepdir "${MY_HTDOCSDIR}/tmp"

	webapp_serverowned -R "${MY_HTDOCSDIR}/config"
	webapp_serverowned -R "${MY_HTDOCSDIR}/js"
	webapp_serverowned -R "${MY_HTDOCSDIR}/matomo.js"
	webapp_serverowned -R "${MY_HTDOCSDIR}/plugins"
	webapp_serverowned -R "${MY_HTDOCSDIR}/tmp"

	# make executable for cli
	fperms 755 "${MY_HTDOCSDIR}/console"

	webapp_src_install
}
