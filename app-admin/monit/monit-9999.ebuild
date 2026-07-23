# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools bash-completion-r1 git-r3 pam systemd

DESCRIPTION="Monitoring and managing daemons or similar programs running on a Unix system"
HOMEPAGE="https://mmonit.com/monit/"
EGIT_REPO_URI="https://bitbucket.org/tildeslash/monit.git"

LICENSE="AGPL-3"
SLOT="0"
KEYWORDS=""
IUSE="pam ssl"

RDEPEND="virtual/zlib:=
	virtual/libcrypt:=
	pam? ( sys-libs/pam )
	ssl? ( dev-libs/openssl:0= )
"
DEPEND="${RDEPEND}"
BDEPEND="
	app-alternatives/yacc
	app-alternatives/lex
"
PATCHES=( "${FILESDIR}/monit_404.patch" )

src_prepare() {
	default
	./bootstrap
	sed -i -e '/^INSTALL_PROG/s/-s//' Makefile.in || die
}

src_configure() {
	local myeconfargs=(
		$(use_with pam)
		$(use_with ssl)
		--enable-optimized
	)
	econf "${myeconfargs[@]}"
}

src_install() {
	default

	insinto /etc/logrotate.d
	newins "${FILESDIR}"/monit.logrotate monit

	insinto /etc; insopts -m600; doins monitrc
	newinitd "${FILESDIR}"/monit.initd-5.0-r1 monit
	systemd_dounit system/startup/${PN}.service

	use pam && newpamd "${FILESDIR}"/${PN}.pamd ${PN}

	dobashcomp system/bash/monit
}

pkg_postinst() {
	elog "Sample configurations are available at:"
	elog "https://mmonit.com/monit/documentation/"
}
