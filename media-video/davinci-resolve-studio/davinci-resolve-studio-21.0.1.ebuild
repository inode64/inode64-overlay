# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit check-reqs desktop udev xdg

PKG_NAME="DaVinci_Resolve_Studio_${PV}_Linux"
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
	libs/libcrypto.so.1.1
	libs/libcurl.so
	libs/libdns_sd.so.1
	libs/libgstapp-1.0.so
	libs/libgstapp-1.0.so.0
	libs/libgstapp-1.0.so.0.2003.0
	libs/libgstaudio-1.0.so
	libs/libgstaudio-1.0.so.0
	libs/libgstaudio-1.0.so.0.2003.0
	libs/libgstbase-1.0.so
	libs/libgstbase-1.0.so.0
	libs/libgstbase-1.0.so.0.2003.0
	libs/libgstcodecparsers-1.0.so
	libs/libgstcodecparsers-1.0.so.0
	libs/libgstcodecparsers-1.0.so.0.2003.0
	libs/libgstcodecs-1.0.so
	libs/libgstcodecs-1.0.so.0
	libs/libgstcodecs-1.0.so.0.2003.0
	libs/libgstnet-1.0.so
	libs/libgstnet-1.0.so.0
	libs/libgstnet-1.0.so.0.2003.0
	libs/libgstpbutils-1.0.so
	libs/libgstpbutils-1.0.so.0
	libs/libgstpbutils-1.0.so.0.2003.0
	libs/libgstreamer-1.0.so
	libs/libgstreamer-1.0.so.0
	libs/libgstreamer-1.0.so.0.2003.0
	libs/libgstrtp-1.0.so
	libs/libgstrtp-1.0.so.0
	libs/libgstrtp-1.0.so.0.2003.0
	libs/libgstsctp-1.0.so
	libs/libgstsctp-1.0.so.0
	libs/libgstsctp-1.0.so.0.2003.0
	libs/libgstsdp-1.0.so
	libs/libgstsdp-1.0.so.0
	libs/libgstsdp-1.0.so.0.2003.0
	libs/libgsttag-1.0.so
	libs/libgsttag-1.0.so.0
	libs/libgsttag-1.0.so.0.2003.0
	libs/libgstvideo-1.0.so
	libs/libgstvideo-1.0.so.0
	libs/libgstvideo-1.0.so.0.2003.0
	libs/libgstwebrtc-1.0.so
	libs/libgstwebrtc-1.0.so.0
	libs/libgstwebrtc-1.0.so.0.2003.0
	libs/libjxl.so
	libs/libjxl.so.0.11
	libs/libjxl.so.0.11.1
	libs/libjxl_cms.so
	libs/libjxl_cms.so.0.11
	libs/libjxl_cms.so.0.11.1
	libs/libjxl_threads.so
	libs/libjxl_threads.so.0.11
	libs/libjxl_threads.so.0.11.1
	libs/libluajit-5.1.so.2
	libs/liborc-0.4.so
	libs/liborc-0.4.so.0
	libs/liborc-0.4.so.0.32.0
	libs/libpq.so.5
	libs/libsoxr.so
	libs/libsoxr.so.0
	libs/libsoxr.so.0.1.3
	libs/libsrtp2.so
	libs/libsrtp2.so.2.4.0
	libs/libssl.so.1.1
	libs/libtbb.so.2
	libs/libtbbmalloc.so.2
	libs/libtbbmalloc_proxy.so.2
	libs/libsharpyuv.so
	libs/libsharpyuv.so.0
	libs/libsharpyuv.so.0.1.1
	libs/libwebp.so
	libs/libwebp.so.7
	libs/libwebp.so.7.1.10
	libs/libwebpdecoder.so
	libs/libwebpdecoder.so.3
	libs/libwebpdecoder.so.3.1.10
	libs/libwebpdemux.so
	libs/libwebpdemux.so.2
	libs/libwebpdemux.so.2.0.16
	libs/libwebpmux.so
	libs/libwebpmux.so.3
	libs/libwebpmux.so.3.1.1
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
RESTRICT="fetch mirror strip test"

# x11-libs/libXtst required for libs/libFairlightPage.so

DEPEND="
	app-arch/brotli
	app-arch/lz4
	app-crypt/mit-krb5
	dev-libs/glib
	dev-libs/icu
	dev-libs/libltdl
	dev-libs/nspr
	dev-libs/nss
	gnome-base/librsvg
	media-gfx/graphite2
	media-libs/harfbuzz
	sys-apps/dbus
	sys-devel/gcc
	virtual/libcrypt
	virtual/opencl
	virtual/opengl
	x11-libs/libX11
	x11-libs/libXext
	x11-libs/libXrandr
	x11-libs/libXtst
	x11-libs/libxcb
	!bundled-libs? (
		dev-libs/openssl-compat:1.1.1
		dev-cpp/tbb
		dev-lang/luajit
		dev-lang/orc
		dev-libs/apr
		dev-libs/xmlsec
		media-libs/freeglut
		media-libs/gst-plugins-bad
		media-libs/gst-plugins-base
		media-libs/gstreamer
		media-libs/libjxl
		media-libs/libwebp
		media-libs/soxr
		net-dns/avahi[mdnsresponder-compat]
		net-libs/libsrtp
		net-misc/curl
	    dev-db/postgresql
	    gnome-base/gnome-shell
	)
	video_cards_amdgpu? ( >=dev-libs/rocm-opencl-runtime-5.5.1 media-libs/mesa[-video_cards_radeon] )
	video_cards_nvidia? ( >=x11-drivers/nvidia-drivers-550.40.07 )
"
RDEPEND="${DEPEND}"
BDEPEND="
	app-arch/unzip
	dev-util/patchelf
"

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
	CHECKREQS_DISK_BUILD="30G"

	check-reqs_pkg_pretend
}
pkg_setup() {
	CHECKREQS_DISK_BUILD="30G"

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

		# NOTE: graphviz is kept bundled even with -bundled-libs. DaVinci ships an
		# old graphviz (libcdt.so.5 / libcgraph.so.6 / libgvc.so.6 / libgvcodec.so)
		# whose sonames are ABI-incompatible with current media-gfx/graphviz
		# (libcdt.so.6 / libcgraph.so.8 / libgvc.so.7). The bundled libs/graphviz/
		# plugins (config6) are self-contained, so they must not be removed.

		# remove some libraries
		find -name "libgcc_s.so.1" -delete || die
		find -name "libusb*" -delete || die
	fi

	# Remove license files
	rm "BlackmagicRAWSpeedTest/Third Party Licenses.rtf" || die
	rm "BlackmagicRAWPlayer/Third Party Licenses.rtf" || die
}

src_install() {
	cd ${PKG_MOUNT}

	while IFS= read -r -d '' i; do
	[[ -f "${i}" && $(od -t x1 -N 4 "${i}") == *"7f 45 4c 46"* ]] || continue
		einfo "Fixing RPATH of ${i}"
		patchelf --set-rpath \
"${PKG_HOME}"'/libs:'\
"${PKG_HOME}"'/libs/plugins/sqldrivers:'\
"${PKG_HOME}"'/libs/plugins/xcbglintegrations:'\
"${PKG_HOME}"'/libs/plugins/imageformats:'\
"${PKG_HOME}"'/libs/plugins/platforms:'\
"${PKG_HOME}"'/libs/Fusion:'\
"${PKG_HOME}"'/plugins:'\
"${PKG_HOME}"'/bin:'\
"${PKG_HOME}"'/BlackmagicRAWSpeedTest/BlackmagicRawAPI:'\
"${PKG_HOME}"'/BlackmagicRAWSpeedTest/plugins/platforms:'\
"${PKG_HOME}"'/BlackmagicRAWSpeedTest/plugins/imageformats:'\
"${PKG_HOME}"'/BlackmagicRAWSpeedTest/plugins/mediaservice:'\
"${PKG_HOME}"'/BlackmagicRAWSpeedTest/plugins/audio:'\
"${PKG_HOME}"'/BlackmagicRAWSpeedTest/plugins/xcbglintegrations:'\
"${PKG_HOME}"'/BlackmagicRAWSpeedTest/plugins/bearer:'\
"${PKG_HOME}"'/BlackmagicRAWPlayer/BlackmagicRawAPI:'\
"${PKG_HOME}"'/BlackmagicRAWPlayer/plugins/mediaservice:'\
"${PKG_HOME}"'/BlackmagicRAWPlayer/plugins/imageformats:'\
"${PKG_HOME}"'/BlackmagicRAWPlayer/plugins/audio:'\
"${PKG_HOME}"'/BlackmagicRAWPlayer/plugins/platforms:'\
"${PKG_HOME}"'/BlackmagicRAWPlayer/plugins/xcbglintegrations:'\
"${PKG_HOME}"'/BlackmagicRAWPlayer/plugins/bearer:'\
"${PKG_HOME}"'/Onboarding/plugins/xcbglintegrations:'\
"${PKG_HOME}"'/Onboarding/plugins/qtwebengine:'\
"${PKG_HOME}"'/Onboarding/plugins/platforms:'\
"${PKG_HOME}"'/Onboarding/plugins/imageformats:'\
"${PKG_HOME}"'/DaVinci Control Panels Setup/plugins/platforms:'\
"${PKG_HOME}"'/DaVinci Control Panels Setup/plugins/imageformats:'\
"${PKG_HOME}"'/DaVinci Control Panels Setup/plugins/bearer:'\
"${PKG_HOME}"'/DaVinci Control Panels Setup/AdminUtility/PlugIns/DaVinciKeyboards:'\
"${PKG_HOME}"'/DaVinci Control Panels Setup/AdminUtility/PlugIns/DaVinciPanels:'\
'$ORIGIN' "${i}" || die "patchelf failed on ${i}"
	done < <(find "${S}/${PKG_MOUNT}" -type f -size -32M -print0)

	# Fix QA Notice: Unresolved soname dependencies:
	einfo "Fixing libsonyxavcenc.so"
	patchelf --replace-needed "${PKG_HOME}"/libs/libsonyxavcenc.so libsonyxavcenc.so "${S}/${PKG_MOUNT}"/bin/resolve \
		|| die "patchelf failed on resolve"

	insinto "${PKG_HOME}"
	local _dir
	for _dir in "Apple Immersive" bin BlackmagicRAWPlayer BlackmagicRAWSpeedTest \
		    Certificates Control "DaVinci Control Panels Setup" \
		    "Fairlight Studio Utility" Fusion graphics libs LUT plugins UI_Resource; do
		include_dir "${_dir}"
	done

	if use developer; then
		include_dir Developer
	fi

	insinto "${PKG_HOME}"/share
	doins share/{default-config.dat,default_cm_config.bin,log-conf.xml}

	# DaVinci control-panel driver framework (libDaVinciPanelAPI.so etc.).
	# post_install.sh: install_dvpanel_libs() -> tar -xf ... -C /usr/lib64
	dodir "/usr/$(get_libdir)"
	tar -xf share/panels/dvpanel-framework-linux-x86_64.tgz \
		-C "${ED}/usr/$(get_libdir)" || die "failed to unpack dvpanel framework"

	# OFX render plugin, so other OFX hosts can use the Resolve renderer.
	# post_install.sh: install_resolve_plugin() -> /usr/OFX/Plugins
	insinto "/usr/OFX/Plugins"
	doins -r "share/DaVinci Resolve Renderer.ofx.bundle"
	fperms +x "/usr/OFX/Plugins/DaVinci Resolve Renderer.ofx.bundle/Contents/Linux-x86-64/DaVinci Resolve Renderer.ofx"

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
	keepdir "${PKG_HOME}/"{configs,DolbyVision,easyDCP,Extras,Fairlight,GPUCache,logs,Media,"Resolve Disk Database",.crashreport,.license,.LUT,"Apple Immersive/Calibration"}

	keepdir "/var/BlackmagicDesign/DaVinci Resolve"

	# Install desktop shortcut
	newmenu share/DaVinciControlPanelsSetup.desktop com.blackmagicdesign.resolve-Panels.desktop
	newmenu share/DaVinciResolve.desktop com.blackmagicdesign.resolve.desktop
	newmenu share/DaVinciResolveCaptureLogs.desktop com.blackmagicdesign.resolve-CaptureLogs.desktop
	newmenu share/blackmagicraw-player.desktop com.blackmagicdesign.rawplayer.desktop
	newmenu share/blackmagicraw-speedtest.desktop com.blackmagicdesign.rawspeedtest.desktop
	newmenu share/DaVinciRemoteMonitoring.desktop com.blackmagicdesign.resolve-DaVinciRemoteMonitoring.desktop

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
		newicon -s ${res} -c mimetypes graphics/application-x-braw-sidecar_${res}x${res}_mimetypes.png application-x-braw-sidecar
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
	echo "LD_LIBRARY_MASK=\"libsonyxavcenc.so libcuda.so.1\"" >> "${T}/80${PN}" || die
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
