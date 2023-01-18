# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{8..11} )

inherit distutils-r1

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="https://github.com/abbbi/virtnbdbackup.git"
	inherit git-r3
else
	SRC_URI="https://github.com/abbbi/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

DESCRIPTION="Backup utility for libvirt kvm / qemu with incremental backup support via NBD"
HOMEPAGE="https://github.com/abbbi/virtnbdbackup"

LICENSE="GPL-3"
SLOT="0"
IUSE=""

REQUIRED_USE="${PYTHON_REQUIRED_USE}
"
RDEPEND="
	>=sys-libs/libnbd-1.5.5[python]
	>=dev-python/libvirt-python-7.6.0[${PYTHON_USEDEP}]
	app-emulation/qemu[multipath]
	dev-python/lxml[${PYTHON_USEDEP}]
	dev-python/lz4[${PYTHON_USEDEP}]
	dev-python/paramiko[${PYTHON_USEDEP}]
	dev-python/tqdm[${PYTHON_USEDEP}]
	virtual/logger
"
BDEPEND="${PYTHON_DEPS}
"

DOCS=( README.md Changelog )
