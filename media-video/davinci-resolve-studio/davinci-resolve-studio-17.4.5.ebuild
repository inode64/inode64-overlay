# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# TODO:
#	remove qt5 library in bundled mode (numerous errors and coredumps to open applications)
#	Panel Daemon is don't installed
#   amdgpu isn't tested

EAPI=8
inherit check-reqs desktop udev xdg

PKG_NAME="DaVinci_Resolve_Studio_${PV}_Linux"
PKG_HOME="/opt/resolve"
PKG_MOUNT="squashfs-root"

LIBS_SYM="
	DaVinci Control Panels Setup/libavahi-client.so.3
	DaVinci Control Panels Setup/libavahi-common.so.3
	DaVinci Control Panels Setup/libdns_sd.so.1
	DaVinci Control Panels Setup/libxcb.so.1
	libs/libapr-1.so.0.7.0
	libs/libaprutil-1.so.0.6.1
	libs/libcdt.so.5.0.0
	libs/libcgraph.so.6.0.0
	libs/libcrypto.so.1.1
	libs/libcurl.so
	libs/libgvc.so.6.0.0
	libs/libgvpr.so.2.0.0
	libs/libpathplan.so.4.0.0
	libs/libssl.so.1.1
	libs/libtbbmalloc.so.2
	libs/libtbbmalloc_proxy.so.2
	libs/libxcb-icccm.so.4
	libs/libxcb-image.so.0
	libs/libxcb-keysyms.so.1
	libs/libxcb-randr.so.0
	libs/libxcb-render-util.so.0
	libs/libxcb-render.so.0
	libs/libxcb-shape.so.0
	libs/libxcb-shm.so.0
	libs/libxcb-sync.so.1
	libs/libxcb-util.so.1
	libs/libxcb-xfixes.so.0
	libs/libxcb-xinerama.so.0
	libs/libxcb-xinput.so.0
	libs/libxcb-xkb.so.1
	libs/libxcb.so.1
	libs/libxdot.so.4.0.0
	libs/libxmlsec1-openssl.so
	libs/libxmlsec1.so
"

KEYWORDS="~amd64"
DESCRIPTION="Professional A/V post-production software suite from Blackmagic Design"
HOMEPAGE="https://www.blackmagicdesign.com/support/family/davinci-resolve-and-fusion"
SRC_URI="${PKG_NAME}.zip"
RESTRICT="mirror strip"
IUSE="bundled-libs developer video_cards_amdgpu video_cards_nvidia"

DEPEND="
	app-arch/brotli
	app-arch/lz4
	app-arch/zstd
	app-crypt/argon2
	app-crypt/libmd
	dev-libs/fribidi
	dev-libs/glib
	dev-libs/icu
	dev-libs/json-c
	dev-libs/libbsd
	dev-libs/libgpg-error
	dev-libs/libltdl
	dev-libs/libunistring
	dev-libs/nspr
	dev-libs/nss
	dev-libs/ocl-icd
	gnome-base/librsvg
	media-gfx/graphite2
	media-libs/alsa-lib
	media-libs/flac
	media-libs/harfbuzz
	media-libs/libogg
	media-libs/libpng-compat:1.2
	media-libs/libsndfile
	media-libs/libvorbis
	media-libs/opus
	media-sound/pulseaudio
	net-dns/libidn2
	net-libs/libasyncns
	net-libs/nghttp2
	sys-apps/dbus
	virtual/libcrypt
	virtual/opengl
	x11-libs/libX11
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrender
	x11-libs/libXtst
	x11-libs/libxcb
	!bundled-libs? (
		dev-cpp/tbb
		dev-libs/apr
		dev-libs/xmlsec
		media-gfx/graphviz
		media-libs/freeglut
		media-libs/soxr
		net-dns/avahi
		net-misc/curl
	)
	video_cards_amdgpu? ( dev-libs/amdgpu-pro-opencl )
	video_cards_nvidia? ( x11-drivers/nvidia-drivers )
"
RDEPEND="${DEPEND}"

LICENSE="Blackmagic"
SLOT="0"

S="${WORKDIR}"

include_dir() {
	local _dir
	local exe

	_dir="$1"

	doins -r "${_dir}"
	# Set permissions for executables and libraries
	find "${_dir}" -type f -name "*.so" | while read exe; do
		fperms +x "${PKG_HOME}"/"${exe}"
	done
	find "${_dir}" -type f -executable | while read exe; do
		fperms +x "${PKG_HOME}"/"${exe}"
	done
}

pkg_pretend() {
	CHECKREQS_DISK_BUILD="13G"

	check-reqs_pkg_pretend
}
pkg_setup() {
	CHECKREQS_DISK_BUILD="13G"

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
	sed -i -e "s|RESOLVE_INSTALL_LOCATION|${PKG_HOME}|g" share/*.desktop share/*.directory

	# Remove 32bits apps
	rm LUT/GenOutputLut \
		LUT/GenLut || die

	# Remove bundled libraries
	if use !bundled-libs; then
		local remove
		echo "${LIBS_SYM}" | while read remove; do
			if [ "${remove}" ]; then
				rm "${remove}" || die
			fi
		done

		rm -rf libs/pkgconfig || die

		# remove some libraries
		rm libs/libsoxr.so* || die

		rm libs/graphviz/libgvplugin_core.so.6.0.0 || die
		rm libs/graphviz/libgvplugin_dot_layout.so.6.0.0 || die

		rm "DaVinci Control Panels Setup/AdminUtility/PlugIns/DaVinciKeyboards/lib/libusb-1.0.so.0" || die
		rm "DaVinci Control Panels Setup/AdminUtility/PlugIns/DaVinciPanels/lib/libusb-1.0.so.0" || die
		rm bin/libusb* || die
	fi

	# Remove license files
	rm "BlackmagicRAWSpeedTest/Third Party Licenses.rtf"
	rm "BlackmagicRAWPlayer/Third Party Licenses.rtf"

	# Fix categories
	sed -i -e "s|=Video|=AudioVideo|g" share/*.desktop
}

src_install() {
	cd ${PKG_MOUNT}

	insinto "${PKG_HOME}"
	local _dir
	for _dir in bin BlackmagicRAWPlayer BlackmagicRAWSpeedTest Control "DaVinci Control Panels Setup" Fusion graphics libs LUT Onboarding plugins UI_Resource; do
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
	keepdir "${PKG_HOME}/"{.license,easyDCP,Fairlight,logs}
	keepdir "/var/BlackmagicDesign/DaVinci Resolve"

	if use !bundled-libs; then
		# symlink of libusb
		dosym -r /usr/$(get_libdir)/libusb-1.0.so "${PKG_HOME}DaVinci Control Panels Setup/AdminUtility/PlugIns/DaVinciKeyboards/lib/libusb-1.0.so.0" || die
		dosym -r /usr/$(get_libdir)/libusb-1.0.so "${PKG_HOME}DaVinci Control Panels Setup/AdminUtility/PlugIns/DaVinciPanels/lib/libusb-1.0.so.0" || die
		dosym -r /usr/$(get_libdir)/libusb-1.0.so "${PKG_HOME}/bin/libusb-1.0.so" || die

		local _lib
		local _libname
		echo "${LIBS_SYM}" | while read _lib; do
			if [ "${_lib}" ]; then
				_libname=$(basename "${_lib}")
				dosym -r "/usr/$(get_libdir)/${_libname}" "${PKG_HOME}/${_lib}" || die
			fi
		done

		dosym -r /usr/$(get_libdir)/libsoxr.so "${PKG_HOME}"/libs/libsoxr.so || die
		dosym -r /usr/$(get_libdir)/libsoxr.so.0 "${PKG_HOME}"/libs/libsoxr.so.0 || die
		dosym -r /usr/$(get_libdir)/libsoxr.so.0.1.2 "${PKG_HOME}"/libs/libsoxr.so.0.1.3 || die
		dosym -r /usr/$(get_libdir)/graphviz/libgvplugin_core.so.6.0.0	"${PKG_HOME}"/libs/graphviz/libgvplugin_core.so.6.0.0 || die
		dosym -r /usr/$(get_libdir)/graphviz/libgvplugin_core.so.6.0.0 "${PKG_HOME}"/libs/graphviz/libgvplugin_dot_layout.so.6.0.0 || die
	fi

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
}

pkg_preinst() {
	xdg_pkg_preinst
}

pkg_postinst() {
	udev_reload
	xdg_pkg_postinst
}

pkg_postrm() {
	xdg_pkg_postrm
}
