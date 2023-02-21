# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit systemd autotools

DESCRIPTION="This is the proxy-daemon used by www-apps/guacamole"
HOMEPAGE="https://guacamole.apache.org/"

if [[ "${PV}" == *9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/apache/incubator-guacamole-server.git"
else
	KEYWORDS="~amd64 ~x86"
	SRC_URI="https://mirrors.ircam.fr/pub/apache/guacamole/${PV}/source/guacamole-server-${PV}.tar.gz"
fi

LICENSE="MIT"
SLOT="0"
IUSE="encode kubernetes print pulseaudio rdp ssh telnet vnc vorbis webp"
REQUIRED_USE="pulseaudio? ( vnc )"
FONTS="
	media-fonts/dejavu
	media-fonts/liberation-fonts
	media-fonts/terminus-font
"
RDEPEND="
	print? ( app-text/ghostscript-gpl[-X] )
	net-analyzer/openbsd-netcat
	ssh? ( ${FONTS} )
	telnet? ( ${FONTS} )
	kubernetes? ( ${FONTS} )
"
DEPEND="${RDEPEND}
	acct-group/guacamole
	acct-user/guacamole
	dev-libs/openssl:0=
	|| ( dev-libs/ossp-uuid sys-libs/libuuid )
	encode? ( media-video/ffmpeg[encode] )
	kubernetes? ( net-libs/libwebsockets )
	media-libs/libpng:0=
	media-libs/libjpeg-turbo:0=
	rdp? ( net-misc/freerdp )
	ssh? (
		net-libs/libssh2
		x11-libs/pango
		)
	telnet?	(
		net-libs/libtelnet
		x11-libs/pango
		)
	vnc? (
		net-libs/libvncserver[jpeg]
		pulseaudio? (
			media-sound/pulseaudio
			)
	)
	vorbis? ( media-libs/libvorbis )
	webp? ( media-libs/libwebp )
	x11-libs/cairo
"
PATCHES=(
	"${FILESDIR}"/ghostscript-gpl-9.54-compat.patch
)

src_prepare() {
	eautoreconf -fi
	eapply_user
	default
}

src_configure() {
	local myconf="--without-terminal --without-pango"

	if use ssh || use telnet; then
		myconf="--with-terminal --with-pango"
	fi

	if use rdp; then
		myconf="--enable-allow-freerdp-snapshots"
	fi

	econf ${myconf} \
		$(use_enable encode guacenc) \
		$(use_enable kubernetes) \
		$(use_with pulseaudio pulse) \
		$(use_with rdp) \
		$(use_with ssh) \
		$(use_with telnet) \
		$(use_with vnc) \
		$(use_with vorbis) \
		$(use_with webp)
}

src_install() {
	default

	newinitd "${FILESDIR}/guacd.initd" guacd
	newconfd "${FILESDIR}/guacd.confd" guacd

	systemd_newunit "${FILESDIR}/guacd.service" guacd.service
}
