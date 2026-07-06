# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
DISTUTILS_USE_PEP517=setuptools
inherit distutils-r1 pypi systemd

DESCRIPTION="A template for PostgreSQL High Availability with ZooKeeper, etcd, or Consul"
HOMEPAGE="https://github.com/zalando/patroni"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~ppc64 ~x86"
IUSE="s3 systemd +etcd"

DEPEND="
	acct-group/postgres
	acct-user/postgres
"

RDEPEND="
	dev-python/urllib3[${PYTHON_USEDEP}]
	dev-python/pyyaml[${PYTHON_USEDEP}]
	dev-python/click[${PYTHON_USEDEP}]
	dev-python/prettytable[${PYTHON_USEDEP}]
	dev-python/python-dateutil[${PYTHON_USEDEP}]
	dev-python/cryptography[${PYTHON_USEDEP}]
	dev-python/python-json-logger[${PYTHON_USEDEP}]
	dev-python/psutil[${PYTHON_USEDEP}]
	dev-util/ydiff[${PYTHON_USEDEP}]
	dev-python/pysyncobj[${PYTHON_USEDEP}]
	dev-python/psycopg[${PYTHON_USEDEP}]
	s3? ( dev-python/boto3[${PYTHON_USEDEP}] )
	systemd? ( dev-python/python-systemd[${PYTHON_USEDEP}] )
	etcd? ( dev-python/python-etcd[${PYTHON_USEDEP}] )
"

src_install() {
	default

	keepdir /etc/patroni
	fowners postgres:postgres /etc/patroni
	fperms 0750 /etc/patroni

	if ! use s3; then
		rm "${ED}"/usr/bin/patroni_aws
	fi

	newinitd "${FILESDIR}"/${PN}.initd ${PN}
	systemd_dounit "${FILESDIR}/${PN}.service"
}

pkg_postinst() {
	if [[ ! -e "${EROOT}/etc/patroni/patroni.yml" ]]; then
		elog "Execute the following command to initialize environment:"
		elog
		elog "# emerge --config \"=${CATEGORY}/${PF}\""
		elog
		elog "Installation notes are at official site"
		elog "https://patroni.readthedocs.io/en/latest/patroni_configuration.html"
	fi
}

pkg_config() {
	einfo "Initializing configuration."
	patroni --generate-config /etc/patroni/patroni.yml
	chown postgres:postgres /etc/patroni/patroni.yml
	chmod 0640 /etc/patroni/patroni.yml
}
