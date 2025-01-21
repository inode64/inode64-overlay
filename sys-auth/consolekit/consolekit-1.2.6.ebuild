# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit autotools linux-info pam xdg udev

MY_PN=ConsoleKit2
MY_P=${MY_PN}-${PV}

DESCRIPTION="Framework for defining and tracking users, login sessions and seats"
HOMEPAGE="https://github.com/ConsoleKit2/ConsoleKit2 https://www.freedesktop.org/wiki/Software/ConsoleKit/"
SRC_URI="https://github.com/${MY_PN}/${MY_PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

S=${WORKDIR}/${MY_P}
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="acl debug doc evdev kernel_linux pam policykit test udev"
RESTRICT="!test? ( test )"

COMMON_DEPEND=">=dev-libs/glib-2.40:2=[dbus]
	>=sys-devel/gettext-0.19
	sys-apps/dbus
	sys-libs/zlib:=
	x11-libs/libX11:=
	acl? (
		sys-apps/acl:=
		>=virtual/udev-200
		)
	evdev? ( dev-libs/libevdev:= )
	udev? (
		virtual/libudev
		x11-libs/libdrm:=
	)
	pam? ( sys-libs/pam )
	policykit? ( >=sys-auth/polkit-0.110 )"
RDEPEND="${COMMON_DEPEND}
	kernel_linux? ( sys-apps/coreutils[acl?] )"
DEPEND="${COMMON_DEPEND}
	dev-libs/libxslt
	virtual/pkgconfig
	doc? ( app-text/xmlto )
	test? (
		app-text/docbook-xml-dtd:4.1.2
		app-text/xmlto
		)"

QA_MULTILIB_PATHS="usr/lib/ConsoleKit/.*"

pkg_setup() {
	if use kernel_linux; then
		# This is from https://bugs.gentoo.org/376939
		use acl && CONFIG_CHECK="~TMPFS_POSIX_ACL"
		# This is required to get login-session-id string with pam_ck_connector.so
		use pam && CONFIG_CHECK+=" ~AUDITSYSCALL"
		linux-info_pkg_setup
	fi
}

src_prepare() {
	default

	xdg_environment_reset

	sed -i -e '/SystemdService/d' data/org.freedesktop.ConsoleKit.service.in || die

	# patch needs autoreconf, so dont need libtoolize
	eautoreconf
	#elibtoolize # bug 593314
}

src_configure() {
	econf \
		XMLTO_FLAGS='--skip-validation' \
		--libexecdir="${EPREFIX}"/usr/lib/ConsoleKit \
		--localstatedir="${EPREFIX}"/var \
		$(use_enable pam pam-module) \
		$(use_enable doc docbook-docs) \
		$(use_enable test docbook-docs) \
		$(use_enable debug) \
		$(use_enable policykit polkit) \
		$(use_enable evdev libevdev) \
		$(use_enable acl udev-acl) \
		$(use_enable udev libdrm) \
		$(use_enable udev libudev) \
		$(use_enable test tests) \
		--with-dbus-services="${EPREFIX}"/usr/share/dbus-1/services \
		--with-pam-module-dir="$(getpam_mod_dir)" \
		--with-xinitrc-dir="${EPREFIX}"/etc/X11/xinit/xinitrc.d \
		--without-systemdsystemunitdir
}

src_install() {
	emake \
		DESTDIR="${D}" \
		htmldocdir="${EPREFIX}"/usr/share/doc/${PF}/html \
		install

	dosym ConsoleKit /usr/lib/${PN}

	dodoc AUTHORS HACKING NEWS README TODO

	newinitd "${FILESDIR}"/${PN}-1.0.0.initd consolekit

	keepdir /usr/lib/ConsoleKit/run-seat.d
	keepdir /usr/lib/ConsoleKit/run-session.d
	keepdir /etc/ConsoleKit/run-session.d
	keepdir /var/log/ConsoleKit

	exeinto /etc/X11/xinit/xinitrc.d
	newexe "${FILESDIR}"/90-consolekit-3 90-consolekit

	if use kernel_linux; then
		# bug 571524
		exeinto /usr/lib/ConsoleKit/run-session.d
		doexe "${FILESDIR}"/pam-foreground-compat.ck
	fi

	find "${ED}" -name '*.la' -delete || die

	rm -rf "${ED}"/var/run || die # let the init script create the directory
}

pkg_postinst() {
	udev_reload
	xdg_pkg_postinst
}

pkg_postrm() {
	udev_reload
	xdg_pkg_postrm
}
