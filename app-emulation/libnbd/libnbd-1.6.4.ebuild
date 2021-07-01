# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6..9} )

inherit autotools bash-completion-r1 python-single-r1

DESCRIPTION="NBD client library in userspace"
HOMEPAGE="https://github.com/libguestfs/libnbd"
SRC_URI="https://download.libguestfs.org/libnbd/1.6-stable/${P}.tar.gz"

LICENSE="LGPL-2 LGPL-2+"
SLOT="0"

KEYWORDS="amd64 x86"
IUSE="fuse go python ocaml +ssl"

REQUIRED_USE="
	python? ( ${PYTHON_REQUIRED_USE} )
	"
COMMON_DEPEND="
	dev-libs/libxml2:2=
	python? ( ${PYTHON_DEPS} )
	fuse? ( sys-fs/fuse:3= )
	ocaml? ( >=dev-lang/ocaml-4.03:=[ocamlopt] )
	ssl? ( net-libs/gnutls )
	"
DEPEND="${COMMON_DEPEND}
	"
RDEPEND="${COMMON_DEPEND}
	"

DOCS=( README SECURITY TODO )

src_prepare() {
	default
	eautoreconf -i
}

src_configure() {
	econf \
		--disable-static \
		$(use_with ssl gnutls) \
		$(use_enable python) \
		$(use_enable fuse) \
		$(use_enable ocaml) \
		$(use_enable go golang) \
		$(use_enable fuse)
}

src_install() {
	default
	find "${ED}" -type f -name "*.la" -delete
	use python && python_optimize
}
