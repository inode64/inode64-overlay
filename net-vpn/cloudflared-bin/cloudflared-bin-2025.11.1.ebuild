# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd tmpfiles

DESCRIPTION="Argo Tunnel client, written in GoLang"
HOMEPAGE="https://github.com/cloudflare/cloudflared"
SRC_URI="
	amd64? (
		https://github.com/cloudflare/cloudflared/releases/download/${PV}/cloudflared-linux-amd64
			-> cloudflared-${PV}-amd64
	)
	arm64? (
		https://github.com/cloudflare/cloudflared/releases/download/${PV}/cloudflared-linux-arm64
			-> cloudflared-${PV}-arm64
	)
	doc? (
		https://raw.githubusercontent.com/cloudflare/cloudflared/refs/tags/${PV}/RELEASE_NOTES
			-> RELEASE_NOTES-${PV}
	)"

S=${WORKDIR}
LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="doc"
RESTRICT="strip"

src_prepare() {
	default

	case ${ARCH} in
		amd64)
			cp "${DISTDIR}/cloudflared-${PV}-amd64" cloudflared || die
			;;
		arm64)
			cp "${DISTDIR}/cloudflared-${PV}-arm64" cloudflared || die
			;;
		*)
			die "Unsupported arch ${ARCH}"
			;;
	esac

	use doc && (cp "${DISTDIR}/RELEASE_NOTES-${PV}" release_notes || die)
}

src_install() {
	exeinto /usr/bin
	doexe cloudflared

	use doc && dodoc release_notes

	diropts -m0600
	insinto /etc/cloudflared
	newins "${FILESDIR}"/config.yml config-example.yml
	newinitd "${FILESDIR}"/cloudflared.initd cloudflared
	newconfd "${FILESDIR}"/cloudflared.confd cloudflared
	systemd_newunit "${FILESDIR}"/cloudflared.service cloudflared.service

	dotmpfiles "${FILESDIR}/cloudflared.tmpfiles.conf"
}
