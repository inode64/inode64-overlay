# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module systemd

MY_PN="prometheus_${PN}"

DESCRIPTION="Prometheus exporter for Varnish Cache and Vinyl Cache"
HOMEPAGE="https://github.com/otto-de/prometheus_varnish_exporter"
SRC_URI="https://github.com/otto-de/${MY_PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz
	https://www.inode64.com/dist/${P}-vendor.tar.xz"
S="${WORKDIR}/${MY_PN}-${PV}"

LICENSE="MIT"
# Dependent licenses
LICENSE+=" Apache-2.0 BSD"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="acct-user/varnish_exporter"
BDEPEND=">=dev-lang/go-1.25.0"

DOCS=( CHANGELOG.md README.md )

src_compile() {
	# Without cgo, as upstream releases are built. A release tarball has no
	# git hash for main.VersionHash, so -version shows "(gentoo)" instead.
	CGO_ENABLED=0 ego build -trimpath \
		-ldflags "-X main.Version=${PV} -X main.VersionHash=gentoo" \
		-o ${PN} .
}

src_test() {
	ego test ./...
}

src_install() {
	dobin ${PN}
	einstalldocs

	newinitd "${FILESDIR}"/${PN}.initd ${PN}
	newconfd "${FILESDIR}"/${PN}.confd ${PN}
	systemd_dounit "${FILESDIR}"/${PN}.service

	insinto /etc/logrotate.d
	newins "${FILESDIR}"/${PN}.logrotate ${PN}
}

pkg_postinst() {
	elog "The service runs as varnish_exporter, a member of the vinyl and varnish"
	elog "groups so that vinylstat or varnishstat can read the cache's shared"
	elog "memory. It listens on"
	elog "127.0.0.1:9131; change VARNISH_EXPORTER_OPTS in /etc/conf.d/${PN}"
	elog "(OpenRC) or override ExecStart in a drop-in (systemd)."
	elog "Check it before enabling it:"
	elog "  su -s /bin/sh varnish_exporter -c \\"
	elog "    '${PN} -varnishstat-path=${EPREFIX}/usr/bin/vinylstat -test'"
}
