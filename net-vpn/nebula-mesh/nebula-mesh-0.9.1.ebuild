# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module systemd tmpfiles

DESCRIPTION="Self-hosted control plane for the Nebula mesh VPN"
HOMEPAGE="https://github.com/forgekeep/nebula-mesh"

SRC_URI="https://github.com/forgekeep/nebula-mesh/archive/v${PV}.tar.gz -> ${P}.tar.gz
	https://www.inode64.com/dist/${P}-vendor.tar.xz
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+agent mgmt"
REQUIRED_USE="|| ( agent mgmt )"

DATA_DIR="/var/lib/nebula-mgmt"
DATABASE_FILE="${DATA_DIR}/nebula.db"
CONFIG_MGMT_FILE="/etc/nebula-mgmt/server.yml"
CONFIG_AGENT_FILE="/etc/nebula-agent/agent.yml"

RDEPEND="
	mgmt? (
		acct-group/nebula-mgmt
		acct-user/nebula-mgmt
		dev-libs/openssl
	)
	agent? ( net-vpn/nebula )
"

PATCHES=(
        "${FILESDIR}/0001-feat-host-introduc~house-relay-role.patch"
)

src_prepare() {
	default

	sed -i -e 's|/usr/local/bin/|/usr/bin/|g' deploy/systemd/nebula-{agent,mgmt}.service || die
}

src_compile() {
	if use agent; then
		ego build -trimpath -ldflags "-s -w" -o nebula-agent ./cmd/nebula-agent || die
	fi
	if use mgmt; then
		ego build -trimpath -ldflags "-s -w" -o nebula-mgmt ./cmd/nebula-mgmt || die
	fi
}

src_test() {
	ego test ./... || die "test failed"
}

src_install() {
	dodoc README.md CHANGELOG.md

	if use agent; then
		dobin nebula-agent

		insopts -m0600
		insinto /etc/nebula-agent
		doins configs/agent.example.yml
		fperms 0700 /etc/nebula-agent

		newinitd "${FILESDIR}/nebula-agent.initd" nebula-agent
		newconfd "${FILESDIR}/nebula-agent.confd" nebula-agent
		systemd_dounit deploy/systemd/nebula-agent.service

		dotmpfiles "${FILESDIR}/nebula-agent.tmpfiles.conf"
	fi

	if use mgmt; then
		dobin nebula-mgmt

		insopts -m0600
		insinto /etc/nebula-mgmt
		doins configs/server.example.yml
		fperms 0700 /etc/nebula-mgmt
		fowners -R nebula-mgmt:nebula-mgmt /etc/nebula-mgmt

		newinitd "${FILESDIR}/nebula-mgmt.initd" nebula-mgmt
		newconfd "${FILESDIR}/nebula-mgmt.confd" nebula-mgmt
		systemd_dounit deploy/systemd/nebula-mgmt.service

		dotmpfiles "${FILESDIR}/nebula-mgmt.tmpfiles.conf"
	fi
}

pkg_postinst() {
	if use agent; then
		elog "Copy /etc/nebula-agent/agent.example.yml to ${CONFIG_AGENT_FILE}"
		elog "and adjust it before starting the nebula-agent service."

		tmpfiles_process nebula-agent.tmpfiles.conf
	fi
	if use mgmt; then
		elog "Copy /etc/nebula-mgmt/server.example.yml to ${CONFIG_MGMT_FILE}"
		elog "and adjust it before starting the nebula-mgmt service."

		tmpfiles_process nebula-mgmt.tmpfiles.conf

		if [[ ! -e "${EROOT}${DATABASE_FILE}" ]]; then
			elog
			elog "Execute the following command to finish installation:"
			elog
			elog "# emerge --config \"=${CATEGORY}/${PF}\""
		fi
	fi
}

pkg_config() {
	if ! use mgmt; then
		einfo "Nothing to configure: the mgmt USE flag is disabled."
		return
	fi

	if [[ ! -e "${EROOT}${CONFIG_MGMT_FILE}" ]]; then
		einfo "Creating ${EROOT}${CONFIG_MGMT_FILE}"
		cat > "${EROOT}${CONFIG_MGMT_FILE}" <<-EOF || die
			listen: 127.0.0.1:8080
			data_dir: ${DATA_DIR}
			db_path: ${DATABASE_FILE}
			log_level: info
			master_key: "$(openssl rand -base64 32)"
		EOF
		chmod 0600 "${EROOT}${CONFIG_MGMT_FILE}" || die
		chown nebula-mgmt:nebula-mgmt "${EROOT}${CONFIG_MGMT_FILE}" || die
	fi

	einfo "Initializing database."
	"${EROOT}"/usr/bin/nebula-mgmt init --config "${EROOT}${CONFIG_MGMT_FILE}" || die
	chown nebula-mgmt:nebula-mgmt "${EROOT}${DATABASE_FILE}" || die
}
