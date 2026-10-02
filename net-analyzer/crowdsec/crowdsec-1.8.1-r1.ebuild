# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-env go-module shell-completion systemd toolchain-funcs

DESCRIPTION="Collaborative detection of malicious activity and protection against attacks"
HOMEPAGE="https://www.crowdsec.net/ https://github.com/crowdsecurity/crowdsec"
SRC_URI="
	https://github.com/crowdsecurity/crowdsec/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/crowdsecurity/crowdsec/releases/download/v${PV}/${PN}-v${PV}-vendor.tar.xz
"

LICENSE="Apache-2.0 BSD BSD-2 ISC MIT MPL-2.0 WTFPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+server"
# The upstream suite requires external services and fixtures absent from vendor/.
RESTRICT="test"

DEPEND="
	dev-db/sqlite:3
	dev-libs/re2:=
"
RDEPEND="
	${DEPEND}
	app-misc/ca-certificates
	server? (
		acct-group/nobody
		acct-user/nobody
	)
	!net-analyzer/crowdsec-bin
"
BDEPEND="
	>=dev-lang/go-1.26.1
	virtual/pkgconfig
"

src_unpack() {
	default
	# Upstream ships vendor/ at the archive root, separately from the sources.
	mv "${WORKDIR}/vendor" "${S}/vendor" || die
	go-env_set_compile_environment
}

src_prepare() {
	default

	sed -i \
		-e '/^  daemonize:/d' \
		-e 's|log_dir: /var/log/|log_dir: /var/log/crowdsec/|' \
		-e 's|/usr/local/lib/crowdsec/plugins/|/usr/libexec/crowdsec/plugins/|' \
		-e 's|group: nogroup|group: nobody|' \
		-e "s|/etc/crowdsec|${EPREFIX}/etc/crowdsec|g" \
		-e "s|/var/lib/crowdsec|${EPREFIX}/var/lib/crowdsec|g" \
		-e "s|/var/log/crowdsec|${EPREFIX}/var/log/crowdsec|g" \
		-e "s|/usr/libexec/crowdsec|${EPREFIX}/usr/libexec/crowdsec|g" \
		config/config.yaml || die

	sed -i "s|/usr/local/bin|${EPREFIX}/usr/bin|g; s|/etc/crowdsec|${EPREFIX}/etc/crowdsec|g" \
		config/crowdsec.service || die
}

src_compile() {
	local module=github.com/crowdsecurity/crowdsec
	local myldflags="
		-X github.com/crowdsecurity/go-cs-lib/version.Version=v${PV}
		-X github.com/crowdsecurity/go-cs-lib/version.Tag=v${PV}
		-X ${module}/pkg/cwversion.Codename=alphaga
		-X ${module}/pkg/cwversion.Libre2=C++
		-X ${module}/pkg/csconfig.defaultConfigDir=${EPREFIX}/etc/crowdsec
		-X ${module}/pkg/csconfig.defaultDataDir=${EPREFIX}/var/lib/crowdsec/data
	"
	local mygoargs=(
		-mod=vendor
		-trimpath
		-tags netgo,osusergo,expr_debug,nomsgpack,re2_cgo,libsqlite3,sqlite_omit_load_extension
		-ldflags "${myldflags}"
	)

	ego build "${mygoargs[@]}" -o cscli ./cmd/crowdsec-cli

	if use server; then
		ego build "${mygoargs[@]}" -o crowdsec ./cmd/crowdsec

		local plugin
		for plugin in cmd/notification-*; do
			ego build "${mygoargs[@]}" -o "${plugin##*/}" "./${plugin}"
		done
	fi

	if ! tc-is-cross-compiler; then
		local shell
		for shell in bash fish zsh; do
			./cscli completion "${shell}" > "cscli.${shell}" || die
		done
	fi
}

src_install() {
	dobin cscli
	if use server; then
		dobin crowdsec
		exeinto /usr/libexec/crowdsec/plugins
		doexe notification-*

		insinto /etc/crowdsec/notifications
		doins cmd/notification-*/*.yaml

		newinitd "${FILESDIR}/crowdsec.initd" crowdsec
		newconfd "${FILESDIR}/crowdsec.confd" crowdsec
		systemd_dounit config/crowdsec.service
	fi

	insinto /etc/crowdsec
	doins config/{acquis,config,console,context,detect,profiles,simulation}.yaml
	insopts -m0600
	doins config/{local_api_credentials,online_api_credentials}.yaml
	insopts -m0644
	insinto /etc/crowdsec/patterns
	doins config/patterns/*

	keepdir /etc/crowdsec/{acquis.d,hub,collections,scenarios,appsec-configs,appsec-rules}
	keepdir /etc/crowdsec/parsers/{s00-raw,s01-parse,s02-enrich}
	keepdir /etc/crowdsec/postoverflows/s01-whitelist
	keepdir /var/lib/crowdsec/data /var/log/crowdsec
	fperms 0700 /var/lib/crowdsec/data
	fperms 0750 /var/log/crowdsec

	if ! tc-is-cross-compiler; then
		newbashcomp cscli.bash cscli
		newfishcomp cscli.fish cscli.fish
		newzshcomp cscli.zsh _cscli
	fi
	dodoc README.md
}

pkg_config() {
	if ! use server; then
		einfo "USE=-server installs cscli only; no local API needs initialization."
		einfo "For remote API access, use: cscli lapi register --url https://API_HOST:PORT"
		einfo "Then validate the machine on the API server."
		return
	fi

	[[ -z ${ROOT} ]] || die "Run emerge --config crowdsec on the target system"

	local credentials="${EROOT}/etc/crowdsec/local_api_credentials.yaml"
	if ! grep -q '^login:' "${credentials}"; then
		"${EROOT}/usr/bin/cscli" -c "${EROOT}/etc/crowdsec/config.yaml" \
			machines add --auto --force || die "Failed to create local API credentials"
		chmod 0600 "${credentials}" || die
	else
		einfo "Keeping the existing local API credentials."
	fi
}

pkg_postinst() {
	if use server; then
		elog "For a new local API installation, configure the database first, then run:"
		elog "  emerge --config ${CATEGORY}/${PN}"
		elog "Download detection rules and configure log acquisition:"
		elog "  cscli hub update"
		elog "  cscli collections install crowdsecurity/linux"
		elog "  cscli setup interactive"
		elog "Review /etc/crowdsec/acquis.yaml and /etc/crowdsec/acquis.d/ before starting."
		elog "Validate with: crowdsec -c /etc/crowdsec/config.yaml -t"
		elog "For an agent using a remote API, set api.server.enable: false and register"
		elog "with: cscli lapi register --url https://API_HOST:PORT"
		elog "Then validate the machine on the API server."
		elog "Optional Central API registration (on the API server): cscli capi register"
		elog "Install a remediation component (bouncer) to actually block attacks."
	else
		elog "USE=-server: installed cscli and shell completions, without the daemon,"
		elog "services or notification plugins."
		elog "For remote API access, use: cscli lapi register --url https://API_HOST:PORT"
		elog "Then validate the machine on the API server. Some administrative commands"
		elog "require direct access to the database."
	fi

	elog
	elog "SQLite, MySQL/MariaDB and PostgreSQL support is always included."
	elog "Choose the backend in ${EROOT}/etc/crowdsec/config.yaml (db_config)."
	elog "Examples (choose one and replace the host, user and password as needed):"
	elog
	elog "SQLite (default, no database server required):"
	elog "  db_config: { type: sqlite, db_path: ${EROOT}/var/lib/crowdsec/data/crowdsec.db }"
	elog "MySQL or MariaDB:"
	elog "  db_config: { type: mysql, host: 127.0.0.1, port: 3306,"
	elog '               db_name: crowdsec, user: crowdsec, password: "CHANGE_ME" }'
	elog "PostgreSQL (pgx driver):"
	elog "  db_config: { type: pgx, host: 127.0.0.1, port: 5432,"
	elog '               db_name: crowdsec, user: crowdsec, password: "CHANGE_ME" }'
	elog
	elog "For MySQL/MariaDB or PostgreSQL, create the database and user first,"
	elog "with permissions to create and update the CrowdSec schema. The database"
	elog "server may be remote; it is not installed by this package."
	elog "Changing db_config does not migrate existing data. Machines and bouncers"
	elog "must be registered again when switching to a new, empty database."
	elog "Agents using a remote API do not need a local database."
	elog "Details: https://docs.crowdsec.net/docs/local_api/database/"
}
