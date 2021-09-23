# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Runs an SMTP server, catches and displays email in a web interface."
HOMEPAGE="https://github.com/mailhog/MailHog/"
SRC_URI="https://github.com/mailhog/MailHog/releases/download/v${PV}/MailHog_linux_amd64 -> ${P}.bin"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

S="${WORKDIR}"

src_unpack() {
	return
}

src_compile() {
	return
}

src_prepare() {
	default

	# doins doesn't allow installing straight from DISTDIR.
	cp "${DISTDIR}"/${P}.bin ${PN} || die "Failed to prepare theme file."
}

src_install() {
	exeinto /usr/bin
	doexe ${PN}

	newinitd ${FILESDIR}/mailhog.init mailhog
	newconfd ${FILESDIR}/mailhog.conf mailhog
}
