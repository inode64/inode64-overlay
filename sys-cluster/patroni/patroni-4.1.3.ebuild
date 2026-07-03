# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
DISTUTILS_USE_PEP517=setuptools
inherit distutils-r1 pypi

DESCRIPTION="A template for PostgreSQL High Availability with ZooKeeper, etcd, or Consul"
HOMEPAGE="https://github.com/zalando/patroni"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~ppc64 ~x86"
IUSE="s3 systemd +etcd"

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
