# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{8..11} )

inherit autotools bash-completion-r1 python-single-r1

DESCRIPTION="NBD client library in userspace"
HOMEPAGE="https://github.com/libguestfs/libnbd"
SRC_URI="https://download.libguestfs.org/libnbd/$(ver_cut 1-2)-stable/${P}.tar.gz"

LICENSE="LGPL-2 LGPL-2+"
SLOT="0"

KEYWORDS="~amd64 ~x86"
IUSE="examples fuse go ocaml python +ssl"

REQUIRED_USE="
	python? ( ${PYTHON_REQUIRED_USE} )
	"
COMMON_DEPEND="
	dev-libs/libxml2:2=
	examples ( dev-libs/glib dev-libs/libev )
	fuse? ( sys-fs/fuse:3 )
	go? ( dev-lang/go )
	ocaml? ( >=dev-lang/ocaml-4.03:=[ocamlopt] )
	python? ( ${PYTHON_DEPS} )
	ssl? ( net-libs/gnutls )
	"
DEPEND="${COMMON_DEPEND}
	"
RDEPEND="${COMMON_DEPEND}
	"

DOCS=( README.md SECURITY TODO )

src_prepare() {
	default
	eautoreconf -i
}

src_configure() {
	econf \
		--disable-static \
		$(use_enable fuse) \
		$(use_enable go golang) \
		$(use_enable ocaml) \
		$(use_enable python) \
		$(use_with ssl gnutls)
}

src_install() {
	default
	find "${ED}" -type f -name "*.la" -delete
	use python && python_optimize
}
