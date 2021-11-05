# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
inherit systemd autotools

DESCRIPTION="This is the proxy-daemon used by www-apps/guacamole"
HOMEPAGE="https://guacamole.apache.org/"

if [[ "${PV}" == *9999 ]] ; then
	inherit autotools git-r3
	EGIT_REPO_URI="https://github.com/apache/incubator-guacamole-server.git"
else
	SRC_URI="https://mirrors.ircam.fr/pub/apache/guacamole/${PV}/source/guacamole-server-${PV}.tar.gz"
fi

LICENSE="MIT"
SLOT="0"
KEYWORDS=""
IUSE="encode pulseaudio rdp ssh telnet vnc vorbis webp"
REQUIRED_USE="pulseaudio? ( vnc )"
RDEPEND="
	<app-text/ghostscript-gpl-9.54[-X]
	net-analyzer/openbsd-netcat
	ssh? (
		media-fonts/dejavu
		media-fonts/liberation-fonts
		media-fonts/terminus-font )
	telnet?	(
		media-fonts/dejavu
		media-fonts/liberation-fonts
		media-fonts/terminus-font )
"
DEPEND="${RDEPEND}
	acct-group/guacamole
	acct-user/guacamole
	x11-libs/cairo
	media-libs/libpng:0=
	virtual/jpeg:0
	dev-libs/ossp-uuid
	encode? ( media-video/ffmpeg )
	rdp? ( net-misc/freerdp )
	ssh? (
		net-libs/libssh2
		x11-libs/pango )
	telnet?	(
		net-libs/libtelnet
		x11-libs/pango )
	vnc? (
		net-libs/libvncserver[threads]
		pulseaudio? ( media-sound/pulseaudio ) )
	dev-libs/openssl:0=
	vorbis? ( media-libs/libvorbis )
	webp? ( media-libs/libwebp )
"

PATCHES=(
	# From https://issues.apache.org/jira/browse/GUACAMOLE-997
	"${FILESDIR}"/rdp-read-request.diff
)

src_prepare() {
	autoreconf -f -i
	eapply_user
	default
}

src_configure() {
	local myconf="--without-terminal --without-pango"

	if use ssh || use telnet; then
		myconf="--with-terminal --with-pango"
	fi

	econf ${myconf} \
		$(use_enable encode guacenc) \
		$(use_with ssh) \
		$(use_with rdp) \
		$(use_with vnc) \
		$(use_with pulseaudio pulse) \
		$(use_with vorbis) \
		$(use_with telnet) \
		$(use_with webp)
}

src_install() {
	default
	doinitd "${FILESDIR}/guacd"
	systemd_dounit "${FILESDIR}/guacd.service"
}
