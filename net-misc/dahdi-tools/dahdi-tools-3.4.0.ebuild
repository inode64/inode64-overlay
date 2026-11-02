# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools perl-functions shell-completion udev

DESCRIPTION="Userspace tools to configure the kernel modules from net-misc/dahdi"
HOMEPAGE="
	https://www.asterisk.org
	https://github.com/asterisk/dahdi-tools
"
SRC_URI="https://downloads.asterisk.org/pub/telephony/${PN}/releases/${P}.tar.gz"

# libtonezone is LGPL-2.1, the rest GPL-2 (README).
LICENSE="GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64"
IUSE="ppp"

DEPEND="
	dev-libs/newt
	net-misc/dahdi
	sys-kernel/linux-headers
	virtual/libusb:1
	ppp? ( net-dialup/ppp:= )
"
RDEPEND="
	${DEPEND}
	dev-lang/perl:=
"
BDEPEND="
	dev-lang/perl
"

PATCHES=(
	"${FILESDIR}"/dahdi-nondigium-blacklist.patch
	"${FILESDIR}"/dahdi-tools-3.1.0-parallel-make-no-config.patch
	"${FILESDIR}"/dahdi-tools-3.1.0-execinfo.patch
	"${FILESDIR}"/dahdi-tools-3.1.0-cplusplusexternc.patch
	# Upstream after 3.4.0 (5c59c97abe, "xpp: Add static to get_ver").
	"${FILESDIR}"/dahdi-tools-3.2.0-lto.patch
)

src_prepare() {
	default
	# A new compiler warning must not break the build.
	sed -i -e '/^[[:space:]]*-Werror[[:space:]]*\\$/d' -e 's/[[:space:]]-Werror\b//' \
		xpp/oct612x/Makefile.am xpp/xtalk/Makefile.am || die
	eautoreconf
}

src_configure() {
	econf --disable-static $(use_with ppp) --with-perllib="$(perl_get_vendorlib)"
}

src_install() {
	local bashcompdir="$(get_bashcompdir)"

	emake DESTDIR="${D}" bashcompdir="${bashcompdir}" udevrulesdir="$(get_udevdir)/rules.d" install
	emake DESTDIR="${D}" install-config
	einstalldocs

	dosbin patgen pattest patlooptest hdlcstress hdlctest hdlcgen hdlcverify timertest

	newinitd "${FILESDIR}"/dahdi.init2 dahdi
	newinitd "${FILESDIR}"/dahdi-autoconf.init-3.1.0-r4 dahdi-autoconf
	newconfd "${FILESDIR}"/dahdi-autoconf.conf2 dahdi-autoconf

	bashcomp_alias dahdi $(sed -nre 's/^complete -F .* //p' "${ED}${bashcompdir}/dahdi" ||
		die "Error parsing dahdi bash completion file for commands")

	find "${ED}" -name '*.la' -delete || die
}

pkg_postinst() {
	udev_reload
}

pkg_postrm() {
	udev_reload
}
