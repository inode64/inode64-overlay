# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit readme.gentoo-r1

DESCRIPTION="AIDE (Advanced Intrusion Detection Environment) is a file integrity checker"
HOMEPAGE="https://aide.github.io/ https://github.com/aide/aide"
SRC_URI="https://github.com/aide/aide/releases/download/v${PV}/${P}.tar.gz"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64"
IUSE="acl audit curl e2fs nettle selinux test xattr"

DEPEND="
	dev-libs/libpcre2:=
	virtual/zlib:=
	acl? ( virtual/acl )
	audit? ( sys-process/audit )
	curl? ( net-misc/curl )
	e2fs? ( sys-fs/e2fsprogs )
	nettle? ( dev-libs/nettle:= )
	selinux? ( sys-libs/libselinux )
	xattr? ( sys-apps/attr )
	!nettle? (
		dev-libs/libgcrypt:=
		dev-libs/libgpg-error
	)
"
RDEPEND="
	${DEPEND}
	selinux? ( sec-policy/selinux-aide )
"
BDEPEND="
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig
	test? ( dev-libs/check )
"

RESTRICT="!test? ( test )"

DISABLE_AUTOFORMATTING=1
DOC_CONTENTS="
Example configuration file was installed at '${EPREFIX}/etc/aide/aide.conf'.
Please edit it to meet your needs. Refer to aide.conf(5) manual page
for more information.

A helper script, aideinit, was installed and can be used to make AIDE
management easier. Please run 'aideinit --help' for more information."

src_prepare() {
	default

	# Only needed for snapshots.
	if [[ ${PV} == *_p* ]] ; then
		echo "m4_define([AIDE_VERSION], [${PV}])" > version.m4 || die
	fi
}

src_configure() {
	local myeconfargs=(
		--sysconfdir="${EPREFIX}"/etc/${PN}

		# Needed even in EAPI=8, >=portage-3.0.40 skips it here (bug #887177)
		--disable-static

		--with-zlib
		--without-gcrypt
		$(use_with curl)
		$(use_with acl posix-acl)
		$(use_with selinux)
		$(use_with xattr)
		$(use_with e2fs e2fsattrs)
		$(use_with nettle nettle)
		$(use_with audit)
	)

	econf "${myeconfargs[@]}"
}

src_test() {
	emake check
}

src_install() {
	default

	readme.gentoo_create_doc

	insinto /etc/${PN}
	insopts -m0600
	# Offically, there is no default. Maybe OS based?
	newins "${FILESDIR}"/aide.conf-r3 aide.conf

	dobin "${FILESDIR}"/aide-report

	keepdir /var/{lib,log}/${PN}
	keepdir /etc/${PN}/${PN}.conf.d
}

pkg_postinst() {
	readme.gentoo_print_elog

	CONFIG="${EROOT}/etc/aide/aide.conf"
	DATABASE="$(< "${CONFIG}" grep "^database_in[[:space:]]*=[[:space:]]*file:/" | head -n 1 | cut -d: -f2)"

	if [[ ! -e "${EROOT}${DATABASE}" ]]; then
		elog
		elog "Execute the following command to finish installation:"
		elog
		elog "# emerge --config \"=${CATEGORY}/${PF}\""
	fi
}

pkg_config() {
	einfo
	einfo "Initializing database."
	einfo

	CONFIG="${EROOT}/etc/aide/aide.conf"
	DATABASE="$(< "${CONFIG}" grep "^database_in[[:space:]]*=[[:space:]]*file:/" | head -n 1 | cut -d: -f2)"
	DATABASE_OUT="$(< "${CONFIG}" grep "^database_out[[:space:]]*=[[:space:]]*file:/" | head -n 1 | cut -d: -f2)"

	if aide --init; then
	        cp -f "$DATABASE_OUT" "$DATABASE"
	fi
}
