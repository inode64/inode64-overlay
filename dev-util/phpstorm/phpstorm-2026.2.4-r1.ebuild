# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit desktop wrapper xdg-utils

MY_PV="262.11879.104"
MY_PN="PhpStorm"

DESCRIPTION="A complete toolset for web, mobile and enterprise development"
HOMEPAGE="https://www.jetbrains.com/phpstorm/"
SRC_URI="https://download.jetbrains.com/webide/${MY_PN}-${PV}.tar.gz"

S="${WORKDIR}/${MY_PN}-${MY_PV}"
LICENSE="|| ( IDEA IDEA_Academic IDEA_Classroom IDEA_OpenSource IDEA_Personal )
	Apache-1.1 Apache-2.0 BSD BSD-2 CC0-1.0 CDDL-1.1 CPL-0.5 CPL-1.0
	EPL-1.0 EPL-2.0 GPL-2 GPL-2-with-classpath-exception GPL-3 ISC JDOM
	LGPL-2.1+ LGPL-3 MIT MPL-1.0 MPL-1.1 public-domain PSF-2 UoI-NCSA ZLIB"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="30bits server"
RESTRICT="mirror"

BDEPEND="dev-util/patchelf"
RDEPEND="
	>=app-accessibility/at-spi2-core-2.46.0:2
	app-arch/brotli
	app-arch/zstd[lz4]
	dev-libs/nss
	dev-libs/openssl:0/3
	dev-libs/wayland
	media-fonts/dejavu
	media-libs/alsa-lib
	media-libs/harfbuzz[cairo,glib,graphite]
	media-libs/libpng:0=
	media-libs/mesa
	net-print/cups
	virtual/libudev
	virtual/zlib:=
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libXtst
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango
	server? (
		net-dns/avahi
		sys-libs/libselinux
		sys-process/audit
		x11-libs/libXfont2
		x11-libs/libxkbfile
		x11-libs/libxshmfence
	)
"

QA_PREBUILT="opt/${P}/*"

src_prepare() {
	default

	patchelf --set-rpath '$ORIGIN' \
		plugins/jcef-plugin/jcef/jcef_helper \
		plugins/jcef-plugin/jcef/libjcef.so || die

	local remove_me=(
		help/ReferenceCardForMac.pdf
		lib/async-profiler/amd64/jniSymbolsResolver.dll
		lib/async-profiler/amd64/dbghelp.dll
		lib/async-profiler/amd64/libasyncProfiler.dll
		lib/async-profiler/amd64/symsrv.dll
		lib/async-profiler/libasyncProfiler.dylib
		plugins/gateway-plugin/lib/remote-dev-workers/remote-dev-worker-darwin-amd64
		plugins/gateway-plugin/lib/remote-dev-workers/remote-dev-worker-darwin-arm64
		plugins/gateway-plugin/lib/remote-dev-workers/remote-dev-worker-windows-amd64.exe
		plugins/gateway-plugin/lib/remote-dev-workers/remote-dev-worker-linux-arm64
		plugins/gateway-plugin/lib/remote-dev-workers/remote-dev-worker-windows-arm64.exe
		plugins/platform-ijent-bundledBinaries/ijent-aarch64-unknown-linux-musl-release
		plugins/platform-ijent-bundledBinaries/ijent-x86_64-unknown-linux-musl-release
	)

	rm -rvf lib/async-profiler/aarch64 || die

	if ! use server; then
		remove_me+=( plugins/remote-dev-server/selfcontained )
	fi

	rm -rv "${remove_me[@]}" || die

	if use 30bits; then
		echo "-Dsun.java2d.opengl=true" >> bin/phpstorm64.vmoptions || die
	fi

	sed -i \
		-e "\$a\\\\" \
		-e "\$a#-----------------------------------------------------------------------" \
		-e "\$a# Disable automatic updates as these are handled through Gentoo's" \
		-e "\$a# package manager. See bug #704494" \
		-e "\$a#-----------------------------------------------------------------------" \
		-e "\$aide.no.platform.update=Gentoo" bin/idea.properties || die
}

src_install() {
	local DIR="/opt/${P}"
	local exe

	insinto "${DIR}"
	doins -r *

	# Set permissions for executables and libraries
	find -type f -name "*.so*" | while read exe; do
		fperms +x "${DIR}/${exe}"
	done
	find -type f -executable | while read exe; do
		fperms +x "${DIR}/${exe}"
	done

	make_wrapper "${PN}" "${DIR}/bin/${PN}"
	newicon "bin/${PN}.svg" "${PN}.svg"
	make_desktop_entry "${PN}" "phpstorm" "${PN}" "Development;IDE;" "StartupWMClass=jetbrains-phpstorm"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /usr/lib/sysctl.d/
	echo "fs.inotify.max_user_watches = 524288" > "${D}/usr/lib/sysctl.d/30-${PN}-inotify-watches.conf" || die

	# create configuration for revdep-rebuild
	echo "SEARCH_DIRS=\"${DIR}\"" > "${T}/80${PN}" || die
	insinto "/etc/revdep-rebuild"
	doins "${T}/80${PN}"
}

pkg_postinst() {
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_icon_cache_update
}
