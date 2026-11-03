# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module systemd tmpfiles

DESCRIPTION="Like Prometheus, but for logs"
HOMEPAGE="https://grafana.com/loki"
SRC_URI="https://github.com/grafana/loki/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="AGPL-3 Apache-2.0"
# Dependent licenses
LICENSE+=" BSD BSD-2 Boost-1.0 ISC MIT MIT-0 MPL-2.0 Unlicense"
SLOT="0"
KEYWORDS="~amd64"

IUSE="+server tools systemd"
REQUIRED_USE="|| ( server tools )"

RESTRICT="mirror"

RDEPEND="
	acct-user/${PN}"
DEPEND="${RDEPEND}"
BDEPEND=">=dev-lang/go-1.26.10"

src_prepare() {
	default

	# Keep the index and the chunks across reboots, in the directory that the
	# tmpfiles entry creates for them.
	sed -i -e 's|/tmp/loki|/var/lib/loki|g' cmd/${PN}/${PN}-local-config.yaml || die
}

src_configure() {
	VPREFIX="github.com/grafana/${PN}/v3/pkg/util/build"

	export EGO_LDFLAGS="-X ${VPREFIX}.Branch=main -X ${VPREFIX}.Version=${PV} -X ${VPREFIX}.Revision=${PR} -X ${VPREFIX}.BuildUser=${PN} -X ${VPREFIX}.BuildDate=$(date -u -d "@${SOURCE_DATE_EPOCH:-$(date +%s)}" +'%Y-%m-%dT%H:%M:%SZ')"

	default
}

src_compile() {
	if use server; then
		einfo "Building cmd/${PN}/${PN}..."
		ego build -trimpath -ldflags "${EGO_LDFLAGS}" -tags cgo,linux,netgo -mod vendor -o cmd/${PN}/${PN} ./cmd/${PN} || die
	fi

	if use tools; then
		einfo "Building cmd/logcli/logcli..."
		ego build -trimpath -ldflags "${EGO_LDFLAGS}" -tags netgo -mod vendor -o cmd/logcli/logcli ./cmd/logcli || die
		einfo "Building cmd/${PN}tool/${PN}tool..."
		ego build -trimpath -ldflags "${EGO_LDFLAGS}" -tags netgo -mod vendor \
			-o cmd/${PN}tool/${PN}tool ./cmd/${PN}tool || die
		einfo "Building cmd/${PN}-canary/${PN}-canary..."
		ego build -trimpath -ldflags "${EGO_LDFLAGS}" -tags netgo -mod vendor \
			-o cmd/${PN}-canary/${PN}-canary ./cmd/${PN}-canary || die
	fi
}

src_install() {
	if use server; then
		dobin "${S}/cmd/${PN}/${PN}"

		newconfd "${FILESDIR}/${PN}.confd" "${PN}"
		newinitd "${FILESDIR}/${PN}.initd" "${PN}"
		use systemd && systemd_newunit "${FILESDIR}"/${PN}.service ${PN}.service

		insinto "/etc/${PN}"
		doins "${S}/cmd/${PN}/${PN}-local-config.yaml"

		dotmpfiles "${FILESDIR}/${PN}.tmpfiles.conf"
	fi

	if use tools; then
		dobin "${S}/cmd/${PN}tool/${PN}tool"
		dobin "${S}/cmd/logcli/logcli"
		dobin "${S}/cmd/${PN}-canary/${PN}-canary"
	fi
}

pkg_postinst() {
	if use server; then
		tmpfiles_process loki.tmpfiles.conf
	fi

	local v
	for v in ${REPLACING_VERSIONS}; do
		if ver_test "${v}" -lt 3.7; then
			ewarn "Upstream removed Promtail in Loki 3.7, so this package no longer installs"
			ewarn "it. ${CATEGORY}/${PN}-3.6.7 is the last version that does."
			break
		fi
	done
}
