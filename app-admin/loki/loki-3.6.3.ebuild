# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module systemd tmpfiles

DESCRIPTION="Like Prometheus, but for logs."
HOMEPAGE="https://grafana.com/loki"
SRC_URI="https://github.com/grafana/loki/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

IUSE="promtail +server tools systemd"

RESTRICT="mirror strip"

RDEPEND="acct-group/grafana
	acct-user/${PN}"
DEPEND="${RDEPEND}"

src_configure() {
	export CGO_ENABLED=1
	export CGO_CFLAGS="${CFLAGS}"
	export CGO_CPPFLAGS="${CPPFLAGS}"
	export CGO_CXXFLAGS="${CXXFLAGS}"
	export CGO_LDFLAGS="${LDFLAGS}"

	VPREFIX="github.com/grafana/${PN}/v3/pkg/util/build"

	export EGO_LDFLAGS="-extldflags \"${LDFLAGS}\" -s -w -X ${VPREFIX}.Branch=main -X ${VPREFIX}.Version=${PV} -X ${VPREFIX}.Revision=${PR} -X ${VPREFIX}.BuildUser=${PN} -X ${VPREFIX}.BuildDate=$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

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
		einfo "Building cmd/${PN}/${PN}-tool..."
		ego build -trimpath -ldflags "${EGO_LDFLAGS}" -tags netgo -mod vendor -o cmd/${PN}/${PN}-tool ./cmd/${PN} || die
		einfo "Building cmd/${PN}-canary/${PN}-canary..."
		ego build -trimpath -ldflags "${EGO_LDFLAGS}" -tags netgo -mod vendor -o cmd/${PN}-canary/${PN}-canary ./cmd/${PN}-canary || die
	fi

	if use promtail; then
		einfo "Building cmd/${PN}/promtail..."
		if use systemd; then
			ego build -trimpath -ldflags "${EGO_LDFLAGS}" -tags promtail_journal_enabled -mod vendor -o cmd/promtail/promtail ./clients/cmd/promtail || die
		else
			ego build -trimpath -ldflags "${EGO_LDFLAGS}" -tags netgo -mod vendor -o cmd/promtail/promtail ./clients/cmd/promtail || die
		fi
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
		dobin "${S}/cmd/${PN}/${PN}-tool"
		dobin "${S}/cmd/logcli/logcli"
		dobin "${S}/cmd/${PN}-canary/${PN}-canary"
	fi

	if use promtail; then
		dobin "${S}/cmd/promtail/promtail"

		newconfd "${FILESDIR}/promtail.confd" "promtail"
		newinitd "${FILESDIR}/promtail.initd" "promtail"
		use systemd && systemd_newunit "${FILESDIR}"/promtail.service promtail.service

		insinto "/etc/${PN}"
		doins "${S}/clients/cmd/promtail/promtail-local-config.yaml"

		dotmpfiles "${FILESDIR}/promtail.tmpfiles.conf"
	fi
}

pkg_postinst() {
	if use server; then
	        tmpfiles_process loki.tmpfiles.conf
	fi
	if use promtail; then
	        tmpfiles_process promtail.tmpfiles.conf
	fi
}
