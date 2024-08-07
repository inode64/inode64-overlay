# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# TODO:
#	Panel Daemon is don't installed

EAPI=8
inherit check-reqs desktop udev xdg

PKG_NAME="DaVinci_Resolve_Studio_19.0b6_Linux"
PKG_HOME="/opt/resolve"
PKG_MOUNT="squashfs-root"

LIBS_SYM="
	DaVinci Control Panels Setup/libavahi-common.so.3
	DaVinci Control Panels Setup/libavahi-client.so.3
	DaVinci Control Panels Setup/libdns_sd.so.1
	libs/libapr-1.so
	libs/libapr-1.so.0
	libs/libapr-1.so.0.7.0
	libs/libaprutil-1.so
	libs/libaprutil-1.so.0
	libs/libaprutil-1.so.0.6.1
	libs/libcdt.so
	libs/libcdt.so.5
	libs/libcgraph.so
	libs/libcgraph.so.6
	libs/libcrypto.so.1.1
	libs/libcurl.so
	libs/libgvc.so
	libs/libgvc.so.6
	libs/libgvpr.so
	libs/libgvpr.so.2
	libs/liborc-0.4.so
	libs/liborc-0.4.so.0
	libs/liborc-0.4.so.0.32.0
	libs/libpathplan.so
	libs/libpathplan.so.4
	libs/libpq.so.5
	libs/libsoxr.so
	libs/libsoxr.so.0
	libs/libsoxr.so.0.1.3
	libs/libsrtp2.so
	libs/libsrtp2.so.2.4.0
	libs/libssl.so.1.1
	libs/libtbb.so.2
	libs/libtbb_debug.so.2
	libs/libtbbmalloc.so.2
	libs/libtbbmalloc_proxy.so.2
	libs/libxdot.so
	libs/libxdot.so.4
	libs/libxdot.so.4.0.0
	libs/libxmlsec1-openssl.so
	libs/libxmlsec1.so
	Fairlight Studio Utility/libavahi-common.so.3
	Fairlight Studio Utility/libavahi-client.so.3
	Fairlight Studio Utility/libdns_sd.so.1
"

DESCRIPTION="Professional A/V post-production software suite from Blackmagic Design"
HOMEPAGE="https://www.blackmagicdesign.com/support/family/davinci-resolve-and-fusion"
SRC_URI="${PKG_NAME}.zip"

S="${WORKDIR}"
LICENSE="Blackmagic"
SLOT="0"
KEYWORDS="~amd64"
IUSE="bundled-libs developer video_cards_amdgpu video_cards_nvidia"
RESTRICT="mirror strip test"

DEPEND="
	app-arch/brotli
	app-arch/lz4
	app-crypt/argon2
	app-crypt/mit-krb5
	dev-libs/glib
	dev-libs/icu
	dev-libs/libltdl
	dev-libs/nspr
	dev-libs/nss
	dev-qt/qt3d:5[gamepad,qml]
	dev-qt/qtvirtualkeyboard:5
	gnome-base/librsvg
	media-gfx/graphite2
	media-libs/harfbuzz
	media-libs/libpng-compat:1.2
	net-dns/libidn2
	net-libs/nghttp2
	sys-apps/dbus
	sys-devel/gcc[openmp]
	sys-process/numactl
	virtual/libcrypt
	virtual/opencl
	virtual/opengl
	x11-libs/libX11
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXtst
	x11-libs/libxcb
	!bundled-libs? (
		<dev-libs/openssl-3.0
		dev-cpp/tbb
		dev-lang/orc
		dev-libs/apr
		dev-libs/xmlsec
		media-gfx/graphviz
		media-libs/freeglut
		media-libs/soxr
		net-dns/avahi[mdnsresponder-compat]
		net-libs/libsrtp
		net-misc/curl
	    dev-db/postgresql
	    gnome-base/gnome-shell
	)
	video_cards_amdgpu? ( >=dev-libs/rocm-opencl-runtime-5.5.1 )
	video_cards_nvidia? ( x11-drivers/nvidia-drivers )
"
RDEPEND="${DEPEND}"
BDEPEND="app-arch/unzip"

QA_PREBUILT="*"

include_dir() {
	local _dir
	local exe

	_dir="$1"

	doins -r "${_dir}"

	# Reset permissions for executables
	find "${_dir}" -type f | while read exe; do
		fperms -x "${PKG_HOME}"/"${exe}"
	done
	# Set permissions for executables and libraries
	find "${_dir}" -type f -name "*.so*" | while read exe; do
		fperms +x "${PKG_HOME}"/"${exe}"
	done
	find "${_dir}" -type f -executable | while read exe; do
		fperms +x "${PKG_HOME}"/"${exe}"
	done
}

pkg_pretend() {
	CHECKREQS_DISK_BUILD="24G"

	check-reqs_pkg_pretend
}
pkg_setup() {
	CHECKREQS_DISK_BUILD="24G"

	check-reqs_pkg_pretend
}

src_unpack() {
	default

	# Extract the archive from squashfs
	./${PKG_NAME}.run --appimage-extract
}

src_prepare() {
	default
	cd ${PKG_MOUNT}

	# Set installation directory
	sed -i -e "s|RESOLVE_INSTALL_LOCATION|${PKG_HOME}|g" share/*.desktop share/*.directory || die

	# Fix categories
	sed -i -e "s|=Video|=AudioVideo|g" share/*.desktop || die

	# Remove 32bits apps
	rm LUT/GenOutputLut LUT/GenLut || die

	# Remove glib-2.0 compiled with old pango
	# And fix Davinci Resolve: libpango undefined symbol: g_string_free_and_steal
	# https://www.reddit.com/r/Fedora/comments/12z32r1/davinci_resolve_libpango_undefined_symbol_g/
	rm libs/{libgio*,libglib*,libgmodule*,libgobject*} || die

	# Fix undefined symbol: krb5int_c_deprecated_enctype, version k5crypto_3_MIT
	rm "DaVinci Control Panels Setup"/libk5crypto.so.3 || die

	# Remove sqlite because it requires ncurses 5.x
	rm bin/sqlite3 || die

	# remove dev files
	rm -rf libs/pkgconfig || die

	# Remove bundled libraries
	if use !bundled-libs; then
		local remove
		echo "${LIBS_SYM}" | while read remove; do
			if [ "${remove}" ]; then
				rm "${remove}" || die
			fi
		done

		# remove some libraries
		rm -rf libs/graphviz || die
		find -name "libgcc_s.so.1" -delete || die
		find -name "libusb*" -delete || die
	fi

	# Remove license files
	rm "BlackmagicRAWSpeedTest/Third Party Licenses.rtf" || die
	rm "BlackmagicRAWPlayer/Third Party Licenses.rtf" || die
}

src_install() {
	cd ${PKG_MOUNT}

	insinto "${PKG_HOME}"
	local _dir
	for _dir in bin BlackmagicRAWPlayer BlackmagicRAWSpeedTest Certificates Control "DaVinci Control Panels Setup" \
		    "Fairlight Studio Utility" Fusion graphics libs LUT plugins UI_Resource; do
		include_dir "${_dir}"
	done

	if use developer; then
		include_dir Developer
	fi

	insinto "${PKG_HOME}"/share
	doins share/{default-config.dat,default_cm_config.bin,log-conf.xml}

	dodoc docs/{DaVinci_Resolve_Manual.pdf,ReadMe.html,Welcome.txt}
	dodoc "Technical Documentation"/{"DaVinci Remote Panel.txt","User Configuration folders and customization.txt"}

	insinto "$(get_udevdir)"/rules.d
	doins share/etc/udev/rules.d/*.rules

	insinto /usr/share/desktop-directories
	doins share/*.directory

	insinto /etc/xdg/menus
	doins share/*.menu

	insinto /usr/share/mime/packages/
	doins share/{blackmagicraw.xml,resolve.xml}

	diropts -m 0777
	keepdir "${PKG_HOME}/"{configs,DolbyVision,easyDCP,Fairlight,GPUCache,logs,Media,"Resolve Disk Database",.crashreport,.license,.LUT}

	keepdir "/var/BlackmagicDesign/DaVinci Resolve"

	# Install desktop shortcut
	newmenu share/DaVinciControlPanelsSetup.desktop com.blackmagicdesign.resolve-Panels.desktop
	newmenu share/DaVinciResolve.desktop com.blackmagicdesign.resolve.desktop
	newmenu share/DaVinciResolveCaptureLogs.desktop com.blackmagicdesign.resolve-CaptureLogs.desktop
	newmenu share/blackmagicraw-player.desktop com.blackmagicdesign.rawplayer.desktop
	newmenu share/blackmagicraw-speedtest.desktop com.blackmagicdesign.rawspeedtest.desktop

	newmenu "${FILESDIR}"/defaults.list com.blackmagicdesign.list

	# Installing Application icons
	local res
	for res in 64 128; do
		newicon -s ${res} graphics/DV_Resolve.png DaVinci-Resolve.png
		newicon -s ${res} graphics/DV_ResolveProj.png DaVinci-ResolveProj.png
		newicon -s ${res} graphics/DV_ServerAccess.png DaVinci-ResolveDbKey.png
	done

	for res in 48 256; do
		newicon -s ${res} graphics/blackmagicraw-speedtest_${res}x${res}_apps.png blackmagicraw-speedtest.png
		newicon -s ${res} graphics/blackmagicraw-player_${res}x${res}_apps.png blackmagicraw-player.png
		newicon -s ${res} -c mimetypes graphics/application-x-braw-clip_${res}x${res}_mimetypes.png application-x-braw-clip
	done

	for res in 64 128; do
		newicon -s ${res} -c mimetypes graphics/DV_ResolveBin.png application-x-resolvebin
		newicon -s ${res} -c mimetypes graphics/DV_ResolveProj.png application-x-resolveproj
		newicon -s ${res} -c mimetypes graphics/DV_ResolveTimeline.png application-x-resolvetimeline
		newicon -s ${res} -c mimetypes graphics/DV_ServerAccess.png application-x-resolvedbkey
		newicon -s ${res} -c mimetypes graphics/DV_TemplateBundle.png application-x-resolvetemplatebundle
	done

	# create configuration for revdep-rebuild
	echo "SEARCH_DIRS=\"${PKG_HOME}\"" > "${T}/80${PN}" || die
	echo "LD_LIBRARY_MASK=\"libsonyxavcenc.so\"" >> "${T}/80${PN}" || die
	insinto "/etc/revdep-rebuild"
	doins "${T}/80${PN}"
}

pkg_preinst() {
	xdg_pkg_preinst
}

pkg_postinst() {
	udev_reload
	xdg_pkg_postinst
}

pkg_postrm() {
	udev_reload
	xdg_pkg_postrm
}
