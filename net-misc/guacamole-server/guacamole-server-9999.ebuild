# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit systemd tmpfiles

DESCRIPTION="This is the proxy-daemon used by www-apps/guacamole"
HOMEPAGE="https://guacamole.apache.org/"

if [[ "${PV}" == *9999 ]]; then
	inherit autotools git-r3
	EGIT_REPO_URI="https://github.com/apache/guacamole-server.git"
	#EGIT_BRANCH="staging/${PV}"
else
	SRC_URI="https://mirrors.ircam.fr/pub/apache/guacamole/${PV}/source/guacamole-server-${PV}.tar.gz"
fi

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="encode kubernetes print pulseaudio rdp ssh telnet test vnc vorbis webp"
RESTRICT="!test? ( test )"

REQUIRED_USE="pulseaudio? ( vnc )"
FONTS="
	media-fonts/dejavu
	media-fonts/liberation-fonts
	media-fonts/terminus-font
"
RDEPEND="
	kubernetes? ( ${FONTS} )
	net-analyzer/openbsd-netcat
	print? ( app-text/ghostscript-gpl[-X] )
	ssh? ( ${FONTS} )
	telnet? ( ${FONTS} )
"
DEPEND="${RDEPEND}
	acct-group/guacamole
	acct-user/guacamole
	dev-libs/openssl:0=
	|| ( dev-libs/ossp-uuid sys-libs/libuuid )
	encode? ( media-video/ffmpeg )
	kubernetes? ( net-libs/libwebsockets )
	media-libs/libpng:0=
	media-libs/libjpeg-turbo:0=
	rdp? ( ~net-misc/freerdp-3.9.0[client(+),ffmpeg,jpeg] )
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
			media-libs/libpulse
			)
	)
	vorbis? ( media-libs/libvorbis )
	webp? ( media-libs/libwebp )
	x11-libs/cairo
	test? (
		dev-util/cunit
	)
"

src_prepare() {
	default

	if [[ "${PV}" == *9999 ]]; then
		eautoreconf -fi
	fi
}

src_configure() {
	local myconf=(
		$(use_enable encode guacenc)
		$(use_enable kubernetes)
		$(use_with pulseaudio pulse)
		$(use_with rdp)
		$(use_with ssh)
		$(use_with telnet)
		$(use_with vnc)
		$(use_with vorbis)
		$(use_with webp)
	)

	if use ssh || use telnet; then
	    myconf+=(
	    --with-terminal
	    --with-pango
	    )
	else
	    myconf+=(
	    --without-terminal
	    --without-pango
	    )
	fi

	if use rdp; then
		myconf+=(--enable-allow-freerdp-snapshots)
	fi

	econf "${myconf[@]}"
}

src_install() {
	default

	find "${D}" -type f -name '*.la' -delete || die

	newinitd "${FILESDIR}/guacd.initd" guacd
	newconfd "${FILESDIR}/guacd.confd" guacd

	systemd_newunit "${FILESDIR}/guacd.service" guacd.service
	newtmpfiles "${FILESDIR}/guacd.conf" guacd.conf
}

pkg_postinst() {
	tmpfiles_process guacd.conf
}
