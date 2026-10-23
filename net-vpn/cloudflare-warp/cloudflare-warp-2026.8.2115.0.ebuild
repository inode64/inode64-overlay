# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop linux-info systemd unpacker xdg

DESCRIPTION="Cloudflare Warp Client"
HOMEPAGE="https://1.1.1.1"
SRC_URI="https://downloads.cloudflareclient.com/v1/download/jammy-intel/version/${PV} -> ${PN}_${PV}_amd64.deb"
S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="+gui"
RESTRICT="bindist mirror"

DEPEND="
	app-crypt/tpm2-tss
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	net-firewall/nftables
	net-libs/libpcap
	sys-apps/dbus
	gui? (
		app-accessibility/at-spi2-core:2
		dev-libs/ayatana-ido
		dev-libs/libayatana-appindicator
		dev-libs/libayatana-indicator:3
		dev-libs/libdbusmenu
		media-libs/fontconfig
		media-libs/harfbuzz
		media-libs/libepoxy
		net-libs/libsoup:3.0
		net-libs/webkit-gtk:4.1
		net-misc/curl
		virtual/zlib
		x11-libs/cairo
		x11-libs/gdk-pixbuf:2
		x11-libs/gtk+:3[X]
		x11-libs/pango
	)
"
RDEPEND="${DEPEND}"
BDEPEND="
	app-admin/chrpath
	dev-util/patchelf
"

QA_PREBUILT="
	usr/bin/warp-.*
	usr/libexec/warp/.*
"

# Kernel features warp-svc relies on at runtime: TUN for the userspace
# WireGuard/MASQUE tunnel, nftables for the "inet cloudflare-warp" table and
# policy routing (fwmark rules) for IPv4 and IPv6. Since 2026.8 the IPv6 fwmark
# rule is installed unconditionally, so IPV6_MULTIPLE_TABLES is mandatory.
CONFIG_CHECK="
	~TUN
	~IP_ADVANCED_ROUTER
	~IP_MULTIPLE_TABLES
	~IPV6
	~IPV6_MULTIPLE_TABLES
	~NETFILTER
	~NF_TABLES
	~NF_TABLES_INET
	~NF_TABLES_IPV4
	~NF_TABLES_IPV6
	~NFT_REJECT
	~NFT_REJECT_INET
"
ERROR_TUN="CONFIG_TUN is required: warp-svc creates the tunnel interface in userspace"
ERROR_IP_MULTIPLE_TABLES="CONFIG_IP_MULTIPLE_TABLES is required: warp-svc installs IPv4 fwmark rules"
ERROR_IPV6_MULTIPLE_TABLES="CONFIG_IPV6_MULTIPLE_TABLES is required: since 2026.8 warp-svc installs an IPv6 fwmark rule"
ERROR_IPV6_MULTIPLE_TABLES+=" and fails with 'IPv6 fwmark rule install: Address family not supported by protocol'"
ERROR_NF_TABLES="CONFIG_NF_TABLES is required: warp-svc keeps its firewall in the nftables table 'inet cloudflare-warp'"
ERROR_NF_TABLES_INET="CONFIG_NF_TABLES_INET is required: the warp-svc nftables table is of family inet"
ERROR_NFT_REJECT_INET="CONFIG_NFT_REJECT_INET is required: warp-svc loads nft_reject_inet for its firewall rules"

pkg_setup() {
	linux-info_pkg_setup
}

src_prepare() {
	default
	# Fixup the library dependencies to match the ones in the system
	patchelf --replace-needed libpcap.so.0.8 libpcap.so.1 "${S}"/bin/warp-dex || die
	chrpath -d "${S}/usr/lib/warp/lib/crashpad_handler" || die
	rm "${S}/usr/lib/warp/lib/libdartjni.so" || die
}

src_install() {
	dobin bin/warp-{cli,dex,diag,svc}
	domenu usr/share/applications/com.cloudflare.warp.desktop
	systemd_dounit lib/systemd/system/warp-svc.service
	newinitd "${FILESDIR}"/warp-svc.initd warp-svc

	if use gui; then
		mkdir -p "${D}"/usr/libexec/warp || die
		cp -r "${S}"/usr/lib/warp/* "${D}"/usr/libexec/warp/ || die

		# Fix permissions
		fperms +x /usr/libexec/warp/lib/*.so || die

		dosym ../libexec/warp/warp-taskbar usr/bin/warp-taskbar
		systemd_douserunit usr/lib/systemd/user/warp-taskbar.service
		domenu usr/share/applications/com.cloudflare.WarpTaskbar.desktop

		doicon -s scalable usr/share/icons/hicolor/scalable/apps/*.svg

		insinto /usr/share/dbus-1/services
		doins usr/share/dbus-1/services/com.cloudflare.WarpTaskbar.service
	fi
}
