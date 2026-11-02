# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit optfeature systemd tmpfiles

MY_PN="${PN%-bin}"

DESCRIPTION="Self-hosted newsletter and mailing list manager (prebuilt binary)"
HOMEPAGE="
	https://listmonk.app/
	https://github.com/knadh/listmonk
"
SRC_URI="
	https://github.com/knadh/${MY_PN}/releases/download/v${PV}/${MY_PN}_${PV}_linux_amd64.tar.gz
		-> ${P}-linux-amd64.tar.gz
	https://raw.githubusercontent.com/knadh/${MY_PN}/v${PV}/config.toml.sample
		-> ${P}-config.toml
"
S="${WORKDIR}"

LICENSE="AGPL-3"
# Dependent licenses: Go modules, admin UI, email builder and fonts in the binary
LICENSE+=" Apache-2.0 BSD BSD-2 ISC LGPL-2.1 MIT OFL-1.1"
SLOT="0"
KEYWORDS="~amd64"
# The admin UI, templates and SQL queries are a zip appended to the binary,
# which strip would drop.
RESTRICT="strip"

# Also in DEPEND: src_install hands the config file to the listmonk group.
DEPEND="acct-user/listmonk"
RDEPEND="${DEPEND}"

QA_PREBUILT="usr/bin/${MY_PN}"

src_install() {
	dobin ${MY_PN}
	einstalldocs

	insinto /etc/${MY_PN}
	newins "${DISTDIR}/${P}-config.toml" config.toml
	# It holds the database password.
	fowners root:${MY_PN} /etc/${MY_PN}/config.toml
	fperms 0640 /etc/${MY_PN}/config.toml

	newinitd "${FILESDIR}/${MY_PN}.initd" ${MY_PN}
	newconfd "${FILESDIR}/${MY_PN}.confd" ${MY_PN}
	systemd_dounit "${FILESDIR}/${MY_PN}.service"
	newtmpfiles "${FILESDIR}/${MY_PN}.tmpfiles" ${MY_PN}.conf

	insinto /etc/logrotate.d
	newins "${FILESDIR}/${MY_PN}.logrotate" ${MY_PN}
}

pkg_postinst() {
	tmpfiles_process ${MY_PN}.conf

	if [[ -z ${REPLACING_VERSIONS} ]]; then
		elog "listmonk needs PostgreSQL 12 or later, on this host or another one:"
		elog "  CREATE USER listmonk WITH PASSWORD '<password>';"
		elog "  CREATE DATABASE listmonk OWNER listmonk;"
		elog "Put the credentials in ${EROOT}/etc/${MY_PN}/config.toml, create the schema with"
		elog "  emerge --config =${CATEGORY}/${PF}"
		elog "and start it with 'rc-service ${MY_PN} start' or 'systemctl enable --now ${MY_PN}'."
		elog "The first visit to http://localhost:9000/admin creates the admin user."
	else
		elog "listmonk refuses to start while database upgrades are pending. Stop it,"
		elog "back up the database (going back to an older version needs that backup)"
		elog "and run:"
		elog "  emerge --config =${CATEGORY}/${PF}"
	fi

	optfeature "a local database server" dev-db/postgresql
}

pkg_config() {
	local config="${EROOT}/etc/${MY_PN}/config.toml"
	[[ -f ${config} ]] || die "${config} not found"

	# As upstream says, never change the schema under a running instance: an
	# older binary would keep working against tables it does not know.
	if pgrep -x ${MY_PN} >/dev/null; then
		die "${MY_PN} is running, stop it before running emerge --config"
	fi

	ewarn "Back up the database first: going back to an older version needs that backup."

	# Two runs: given --install and --upgrade together, listmonk skips the upgrade.
	einfo "Creating the database schema if it does not exist yet"
	"${EROOT}"/usr/bin/${MY_PN} --config "${config}" --install --idempotent --yes \
		|| die "listmonk --install failed, see the output above"

	einfo "Applying pending database upgrades"
	"${EROOT}"/usr/bin/${MY_PN} --config "${config}" --upgrade --yes \
		|| die "listmonk --upgrade failed, see the output above"

	elog "The database is ready for ${MY_PN} ${PV}."
}
