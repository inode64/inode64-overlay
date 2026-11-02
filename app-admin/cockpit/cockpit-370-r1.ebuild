# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
inherit autotools pam python-single-r1 tmpfiles

DESCRIPTION="Server Administration Web Interface "
HOMEPAGE="https://cockpit-project.org/"
if [[ ${PV} == 9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/cockpit-project/cockpit.git"
else
	KEYWORDS="~amd64 ~x86"
	SRC_URI="https://github.com/cockpit-project/${PN}/releases/download/${PV}/${P}.tar.xz"
fi
# www.gentoo.org replaces the logo in place, which breaks the Manifest
GENTOO_LOGO_COMMIT="00e0cb3d363e2f78e47efb8deac18463b870442e"
GENTOO_LOGO="gentoo-logo-${GENTOO_LOGO_COMMIT:0:8}.png"
GENTOO_LOGO_URI="https://gitweb.gentoo.org/sites/www.git/plain/assets/img/logo/gentoo-logo.png"
SRC_URI="${SRC_URI}
	${GENTOO_LOGO_URI}?id=${GENTOO_LOGO_COMMIT} -> ${GENTOO_LOGO}"

LICENSE="LGPL-2.1+"
SLOT="0"
IUSE="debug doc firewalld +networkmanager pcp selinux test tuned udisks"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"
RESTRICT="!test? ( test )"

BDEPEND="
	sys-devel/gettext
	virtual/pkgconfig
	doc? ( dev-ruby/asciidoctor )
	test? (
		dev-util/gdbus-codegen
	)
	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		dev-python/pip[${PYTHON_USEDEP}]
		test? (
			dev-python/pytest-asyncio[${PYTHON_USEDEP}]
			dev-python/pytest-cov[${PYTHON_USEDEP}]
			dev-python/pytest-timeout[${PYTHON_USEDEP}]
		)
	')
"
DEPEND="
	>=app-crypt/mit-krb5-1.11
	>=dev-libs/json-glib-1.4
	>=net-libs/gnutls-3.6.0:=
	>=sys-apps/systemd-235:=[policykit]
	sys-libs/pam
	virtual/libcrypt:=
	${PYTHON_DEPS}
"
RDEPEND="${DEPEND}
	acct-user/cockpit-ws
	acct-user/cockpit-wsinstance
	app-crypt/sscg
	dev-libs/libgudev
	dev-libs/libpwquality
	>=sys-auth/polkit-0.105[systemd]
	net-libs/glib-networking[ssl]
	virtual/krb5
	networkmanager? (
		firewalld? (
			net-firewall/firewalld
		)
		net-misc/networkmanager[policykit,systemd]
	)
	pcp? (
		app-metrics/pcp
	)
	udisks? (
		sys-fs/udisks[lvm,systemd]
	)
	tuned? (
		sys-apps/tuned
	)
"

src_prepare() {
	default

	eapply_user
	eaclocal
	eautoreconf
	eautomake
}

src_configure() {
	local myconf=(
		$(use_enable debug)
		$(use_enable doc)
		--with-pamdir="/$(get_libdir)/security"
		--localstatedir="${EPREFIX}/var"
	)
	econf "${myconf[@]}"
}

src_install() {
	default

	python_optimize

	if ! use selinux; then
		rm -rf "${ED}"/usr/share/cockpit/selinux
		rm -f "${ED}"/usr/share/metainfo/org.cockpit_project.cockpit_selinux.metainfo.xml || die
	fi

	rm -rf "${ED}"/usr/share/cockpit/{packagekit,playground,sosreport}
	rm -f "${ED}"/usr/share/metainfo/org.cockpit_project.cockpit_sosreport.metainfo.xml || die
	rm -f "${ED}"/usr/share/icons/hicolor/64x64/apps/cockpit-sosreport.png || die

	insinto /usr/share/cockpit/branding/gentoo
	doins "${FILESDIR}/branding.css"
	newins "${DISTDIR}/${GENTOO_LOGO}" logo.png
	newins "${DISTDIR}/${GENTOO_LOGO}" apple-touch-icon.png
	newins "${DISTDIR}/${GENTOO_LOGO}" favicon.ico

	# Remove branding from others distros
	rm -rf "${ED}"/usr/share/cockpit/branding/{arch,centos,debian,fedora,opensuse,rhel,scientific,ubuntu}

	ewarn "Installing experimental pam configuration file"
	ewarn "use at your own risk"
	newpamd "${FILESDIR}/cockpit.pam" cockpit

	# Required for store self-signed certificates
	keepdir /etc/cockpit/ws-certs.d/
}

pkg_postinst() {
	tmpfiles_process cockpit-ws.conf

	elog ""
	elog "To enable Cockpit run:"
	elog " - systemctl enable --now cockpit.socket"
	elog ""
}
