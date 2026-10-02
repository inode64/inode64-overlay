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
	libs/libcrypto.so.3
	libs/libcurl.so
	libs/libluajit-5.1.so.2
	libs/libpq.so.5
	libs/libsoxr.so
	libs/libsoxr.so.0
	libs/libsoxr.so.0.1.3
	libs/libssl.so.3
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

# Runtime dependencies of the prebuilt executables and Qt plugins.
RDEPEND="
	app-arch/brotli
	app-arch/bzip2
	app-arch/lz4
	app-arch/xz-utils
	app-crypt/mit-krb5
	>=dev-libs/glib-2.82
	dev-libs/icu
	dev-libs/libltdl
	dev-libs/libusb:1
	dev-libs/nss
	gnome-base/librsvg
	media-gfx/graphite2
	media-libs/alsa-lib
	media-libs/glu
	sys-apps/dbus
	sys-apps/pciutils
	sys-devel/gcc
	sys-libs/glibc
	sys-libs/libxcrypt[compat]
	sys-libs/mtdev
	virtual/opencl
	virtual/udev
	x11-libs/libXrandr
	x11-libs/libXt
	x11-libs/libXtst
	x11-libs/libXxf86vm
	x11-libs/libdrm
	x11-libs/libxkbcommon[X]
	x11-libs/libxkbfile
	x11-libs/xcb-util-cursor
	x11-libs/xcb-util-keysyms
	x11-libs/xcb-util-wm
	x11-misc/xclip
	x11-misc/xdg-utils
	!bundled-libs? (
		dev-db/postgresql:*
		dev-lang/luajit
		dev-libs/apr-util:1
		dev-libs/openssl:0/3
		media-libs/libwebp
		media-libs/soxr
		net-dns/avahi[mdnsresponder-compat]
		net-misc/curl
	)
	video_cards_amdgpu? ( >=dev-libs/rocm-opencl-runtime-5.5.1 media-libs/mesa[-video_cards_radeon] )
	video_cards_nvidia? ( >=x11-drivers/nvidia-drivers-580.119.02 )
"
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
	./"${PKG_NAME}".run --appimage-extract || die "failed to extract AppImage"
	# The extracted installer is over 10 GiB and is no longer needed.
	rm "${PKG_NAME}.run" || die
}

src_prepare() {
	default
	cd "${PKG_MOUNT}" || die
	eapply "${FILESDIR}/${PN}-21.1-capture-logs.patch"

	# run_bmdpaneld uses bash's $(<file) extension to read its lock file.
	sed -i '1s|^#!/bin/sh$|#!/bin/bash|' bin/run_bmdpaneld || die

	# Use the default PDF viewer. Both strings are exactly 15 bytes: the
	# executable passes a fixed length for the surrounding QString literal.
	LC_ALL=C sed -i 's|/usr/bin/evince|xdg-open       |g' bin/resolve || die

	# Set installation directory
	sed -i -e "s|RESOLVE_INSTALL_LOCATION|${PKG_HOME}|g" share/*.desktop share/*.directory || die

	# Fix categories
	sed -i -e "s|=Video|=AudioVideo|g" share/*.desktop || die

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

	# The welcome program imports QtQuick, Controls and Window only. These
	# unused QML modules were shipped without their matching private Qt libs.
	rm -r Onboarding/qml/Qt/labs/lottieqt Onboarding/qml/QtQml/RemoteObjects \
		Onboarding/qml/QtQuick/{Particles.2,Shapes,VirtualKeyboard} || die

	# Remove bundled libraries
	if use !bundled-libs; then
		local remove
		while read -r remove; do
			[[ -n ${remove} ]] || continue
			rm "${remove}" || die
		done <<< "${LIBS_SYM}"

		# NOTE: graphviz is kept bundled even with -bundled-libs. DaVinci ships an
		# old graphviz (libcdt.so.5 / libcgraph.so.6 / libgvc.so.6 / libgvcodec.so)
		# whose sonames are ABI-incompatible with current media-gfx/graphviz
		# (libcdt.so.6 / libcgraph.so.8 / libgvc.so.7). The bundled libs/graphviz/
		# plugins (config6) are self-contained, so they must not be removed.

		# Keep the bundled TBB 2020 (libtbb.so.2): oneTBB provides libtbb.so.12
		# and cannot satisfy the ABI used by OpenVDB, OpenImageIO and USD.
		# libgstreamer.so is now a private combined library, not the system
		# libgstreamer-1.0.so.0; it must also remain bundled.
		# Likewise keep JPEG XL 0.11 (newer releases change the SONAME), and
		# xmlsec 1.2: libfraunhoferdcp needs xmlSecOpenSSLAppKeyLoad, removed
		# in the system xmlsec 1.3 API.

		# remove some libraries
		find -name "libgcc_s.so.1" -delete || die
		find -name "libusb*" -delete || die
	fi

	# Remove license files
	rm "BlackmagicRAWSpeedTest/Third Party Licenses.rtf" || die
	rm "BlackmagicRAWPlayer/Third Party Licenses.rtf" || die
}

src_install() {
	cd "${PKG_MOUNT}" || die

	# Preserve vendor-relative lookup paths: replacing these with one global
	# path breaks USD plugins and mixes the private Qt builds of the utilities.
	# Large libraries and executables need fixing too (there is no size cutoff).
	local i entry rpath app_dir
	local -a old_rpath
	while IFS= read -r -d '' i; do
		[[ $(od -An -tx1 -N4 "${i}") == *"7f 45 4c 46"* ]] || continue
		rpath='$ORIGIN'
		IFS=: read -r -a old_rpath <<< "$(patchelf --print-rpath "${i}")"
		for entry in "${old_rpath[@]}"; do
			case ${entry} in
				'$ORIGIN/'*) rpath+=":${entry}" ;;
			esac
		done
		case ${i#./} in
			libs/Fusion/Plugins/USD/*)
				rpath+=":${PKG_HOME}/libs/Fusion/Plugins/USD"
				;;
			"DaVinci Control Panels Setup/"*|"Fairlight Studio Utility/"*)
				app_dir=${i#./}
				rpath+=":${PKG_HOME}/${app_dir%%/*}"
				;;
			BlackmagicRAWPlayer/*|BlackmagicRAWSpeedTest/*)
				app_dir=${i#./}
				rpath+=":${PKG_HOME}/${app_dir%%/*}/lib"
				;;
		esac
		rpath+=":${PKG_HOME}/libs:${PKG_HOME}/libs/Fusion:${PKG_HOME}/bin"
		patchelf --set-rpath "${rpath}" "${i}" || die "patchelf failed on ${i}"
	done < <(find . -type f -print0)

	# Fix QA Notice: Unresolved soname dependencies:
	einfo "Fixing libsonyxavcenc.so"
	patchelf --replace-needed "${PKG_HOME}"/libs/libsonyxavcenc.so libsonyxavcenc.so "${S}/${PKG_MOUNT}"/bin/resolve \
		|| die "patchelf failed on resolve"
	patchelf --set-soname libsonyxavcenc.so libs/libsonyxavcenc.so \
		|| die "failed to set the Sony encoder SONAME"

	insinto "${PKG_HOME}"
	doins DaVinciResolve.mcpb
	local _dir
	for _dir in "Apple Immersive" bin BlackmagicRAWPlayer BlackmagicRAWSpeedTest \
		    Certificates Control "DaVinci Control Panels Setup" \
		    "Fairlight Studio Utility" Onboarding ResolvePython Fusion graphics libs LUT plugins UI_Resource; do
		include_dir "${_dir}"
	done

	if use developer; then
		include_dir Developer
	fi

	# Required by the Capture Logs desktop entry and Resolve's diagnostics UI.
	exeinto "${PKG_HOME}/scripts"
	doexe scripts/script.getlogs.v4

	# The graphical installer unpacks the offline Extras bundles separately
	# from filelist.txt. Ship their contents so a fresh installation has them.
	dodir "${PKG_HOME}/Extras"
	LD_LIBRARY_PATH="${PWD}/libs" .ddm/ddmx \
		--src="${S}/${PKG_MOUNT}/.ddm" --dst="${ED}${PKG_HOME}/Extras" \
		|| die "failed to extract the offline Extras"
	# Resolve's download manager updates these files as the invoking user.
	fperms -R a+rwX "${PKG_HOME}/Extras"

	insinto "${PKG_HOME}"/share
	doins share/{default-config.dat,default_cm_config.bin,log-conf.xml}

	# DaVinci control-panel driver framework (libDaVinciPanelAPI.so etc.).
	# post_install.sh: install_dvpanel_libs() -> tar -xf ... -C /usr/lib64
	dodir "/usr/$(get_libdir)"
	tar -xf share/panels/dvpanel-framework-linux-x86_64.tgz \
		-C "${ED}/usr/$(get_libdir)" || die "failed to unpack dvpanel framework"
	# The archive contains clang-12 runtimes; the new panel API needs clang 20.
	# Copy the targets, not the relative symlinks into /opt/resolve/libs.
	cp -L libs/libc++{,abi}.so.1 "${ED}/usr/$(get_libdir)/lib/" \
		|| die "failed to update the panel C++ runtimes"

	# OFX render plugin, so other OFX hosts can use the Resolve renderer.
	# post_install.sh: install_resolve_plugin() -> /usr/OFX/Plugins
	insinto "/usr/OFX/Plugins"
	doins -r "share/DaVinci Resolve Renderer.ofx.bundle"
	fperms +x "/usr/OFX/Plugins/DaVinci Resolve Renderer.ofx.bundle/Contents/Linux-x86-64/DaVinci Resolve Renderer.ofx"

	dodoc docs/{DaVinci_Resolve_Manual.pdf,ReadMe.html,Welcome.txt}
	dodoc "Technical Documentation"/{"DaVinci Remote Panel.txt","User Configuration folders and customization.txt"}
	# Resolve's Help menu looks for this path beneath its installation root.
	docompress -x "/usr/share/doc/${PF}/DaVinci_Resolve_Manual.pdf"
	dosym -r "/usr/share/doc/${PF}/DaVinci_Resolve_Manual.pdf" \
		"${PKG_HOME}/docs/DaVinci_Resolve_Manual.pdf"

	insinto "$(get_udevdir)"/rules.d
	doins share/etc/udev/rules.d/*.rules

	# The SDX licensing dongle rule is generated by the upstream installer.
	printf '%s\n' 'SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="096e", MODE="0666"' \
		> "${T}/99-SDX.rules" || die
	doins "${T}/99-SDX.rules"

	insinto /usr/share/desktop-directories
	doins share/*.directory

	insinto /etc/xdg/menus
	doins share/*.menu

	insinto /usr/share/mime/packages/
	doins share/{blackmagicraw.xml,resolve.xml}

	fperms a+w "${PKG_HOME}/Apple Immersive"
	diropts -m 0777
	keepdir "${PKG_HOME}/"{configs,DolbyVision,easyDCP,Extras,Fairlight,GPUCache,Immersive,logs,Media}
	keepdir "${PKG_HOME}/"{"Resolve Disk Database",.crashreport,.license,.LUT,"Apple Immersive/Calibration"}

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
		newicon -s ${res} -c mimetypes \
			graphics/application-x-braw-sidecar_${res}x${res}_mimetypes.png application-x-braw-sidecar
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
	echo "LD_LIBRARY_MASK=\"libcuda.so.1\"" >> "${T}/80${PN}" || die
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
