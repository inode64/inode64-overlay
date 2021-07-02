# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6..9} )

inherit distutils-r1

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="https://github.com/abbbi/virtnbdbackup.git"
	inherit git-r3
else
	SRC_URI="https://github.com/abbbi/virtnbdbackup/archive/${PV}.tar.gz -> ${P}.tar.gz"
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
	app-emulation/qemu[multipath]
	>=dev-python/libvirt-python-1.6.0[${PYTHON_USEDEP}]
	dev-python/tqdm[${PYTHON_USEDEP}]
	dev-python/lz4[${PYTHON_USEDEP}]
	>=app-emulation/libnbd-1.5.5[python]
	virtual/logger
"
BDEPEND="${PYTHON_DEPS}
"

DOCS=( README.md )
