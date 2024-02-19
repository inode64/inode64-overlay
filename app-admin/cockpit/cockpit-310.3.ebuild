# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{8..12} )
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
SRC_URI="${SRC_URI} https://www.gentoo.org/assets/img/logo/gentoo-logo.png"

LICENSE="LGPL-2.1+"
SLOT="0"
IUSE="debug doc firewalld +networkmanager old-bridge pcp selinux test tuned udisks"

REQUIRED_USE="old-bridge? ( ${PYTHON_REQUIRED_USE} )"
RESTRICT="!test? ( test )"

BDEPEND="
	>=app-crypt/mit-krb5-1.11
	>=dev-libs/glib-2.50
	>=dev-libs/json-glib-1.4
	>=net-libs/gnutls-3.6.0
	>=net-libs/libssh-0.8.5[server]
	>=sys-apps/systemd-235[policykit]
	>=sys-auth/polkit-0.105[systemd]
	doc? (
		app-text/xmlto
		dev-util/gtk-doc
	)
	!old-bridge? (
		${PYTHON_DEPS}
		dev-python/pip
		test? (
			dev-python/pytest-asyncio
			dev-python/pytest-cov
			dev-python/pytest-timeout
		)
	)
"
DEPEND="
	dev-libs/libpwquality
	dev-python/dbus-python
	net-libs/nodejs[npm]
	networkmanager? (
		firewalld? (
			net-firewall/firewalld
		)
		net-misc/networkmanager[policykit,systemd]
	)
	pcp? (
		app-metrics/pcp
	)
	sys-apps/accountsservice[systemd]
	udisks? (
		sys-fs/udisks[lvm,systemd]
	)
	tuned? (
		sys-apps/tuned
	)
	virtual/libcrypt:=
	!old-bridge? (
		${PYTHON_DEPS}
	)
"

RDEPEND="${DEPEND}
	acct-group/cockpit-ws
	acct-group/cockpit-wsinstance
	acct-user/cockpit-ws
	acct-user/cockpit-wsinstance
	app-crypt/sscg
	dev-libs/libgudev
	net-libs/glib-networking[ssl]
	virtual/krb5
"

PATCHES=(
	"${FILESDIR}/pip_install.patch"
)

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
		$(use_enable pcp)
		$(use_enable doc)
		$(use_enable old-bridge)
		--with-pamdir="/$(get_libdir)/security"
		--with-cockpit-user=cockpit-ws
		--with-cockpit-ws-instance-user=cockpit-wsinstance
		--with-cockpit-group=cockpit-ws
		--localstatedir="${EPREFIX}/var"
	)
	econf "${myconf[@]}"
}

src_install() {
	default

	use old-bridge || python_optimize

	if ! use selinux; then
		rm -rf "${ED}"/usr/share/cockpit/selinux
		rm -rf "${ED}"/usr/share/metainfo/org.cockpit-project.cockpit-selinux.metainfo.xml
	fi

	rm -rf "${ED}"/usr/share/cockpit/{packagekit,playground,sosreport}
	rm -rf "${ED}"/usr/share/metainfo/org.cockpit-project.cockpit-sosreport.metainfo.xml

	insinto /usr/share/cockpit/branding/gentoo
	doins "${FILESDIR}/branding.css"
	newins "${DISTDIR}/gentoo-logo.png" logo.png
	newins "${DISTDIR}/gentoo-logo.png" apple-touch-icon.png
	newins "${DISTDIR}/gentoo-logo.png" favicon.ico

	# Remove branding from others distros
	rm -rf "${ED}"/usr/share/cockpit/branding/{arch,centos,debian,fedora,opensuse,rhel,scientific,ubuntu}

	ewarn "Installing experimental pam configuration file"
	ewarn "use at your own risk"
	newpamd "${FILESDIR}/cockpit.pam" cockpit
	dodoc README.md AUTHORS

	# Required for store self-signed certificates
	keepdir /etc/cockpit/ws-certs.d/
}

pkg_postinst() {
	tmpfiles_process cockpit-tempfiles.conf

	elog ""
	elog "To enable Cockpit run:"
	elog " - systemctl enable --now cockpit.socket"
	elog ""
}
