# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RPM_COMPRESS_TYPE=none
inherit rpm

DESCRIPTION="Microsoft ODBC Driver 18 for SQL Server"
HOMEPAGE="https://learn.microsoft.com/en-us/sql/connect/odbc/microsoft-odbc-driver-for-sql-server"
SRC_URI="https://packages.microsoft.com/rhel/9/prod/Packages/m/msodbcsql18-${PV}-1.x86_64.rpm"
S="${WORKDIR}"

LICENSE="Microsoft-ODBC"
SLOT="${PV%%.*}"
KEYWORDS="-* ~amd64"
RESTRICT="bindist mirror strip"

RDEPEND="dev-db/unixODBC
	net-misc/curl
	virtual/krb5"
IDEPEND="dev-db/unixODBC"

SO_NAME="libmsodbcsql-${PV%.*.*}.so.${PV#*.*.}"

DOCS=( "usr/share/doc/msodbcsql${PV%%.*}/RELEASE_NOTES" )

QA_PREBUILT="usr/lib64/${SO_NAME}"

src_prepare() {
	default

	# Change lib path
	sed -i '/Driver/s|opt/microsoft/msodbcsql[0-9]*|usr|' \
		"opt/microsoft/msodbcsql${PV%%.*}/etc/odbcinst.ini" \
		|| die "sed failed for odbcinst.ini"
}

src_install() {
	einstalldocs

	insinto /usr/share/${PN}
	doins "opt/microsoft/msodbcsql${PV%%.*}/etc/odbcinst.ini"

	doheader "opt/microsoft/msodbcsql${PV%%.*}/include/msodbcsql.h"
	dolib.so "opt/microsoft/msodbcsql${PV%%.*}/lib64/${SO_NAME}"
	dosym "${SO_NAME}" "usr/lib64/libmsodbcsql-${PV%%.*}.so"

	insinto /usr/share/resources/en_US
	doins "opt/microsoft/msodbcsql${PV%%.*}/share/resources/en_US/msodbcsqlr${PV%%.*}.rll"
}

# /etc/unixODBC/odbcinst.ini belongs to dev-db/unixODBC and lists every driver,
# so register this one in it the way upstream's RPM does. Portage runs the old
# pkg_prerm before the new pkg_postinst, which keeps UsageCount at 1 on updates.
pkg_postinst() {
	odbcinst -i -d -f "${EROOT}/usr/share/${PN}/odbcinst.ini" || ewarn "odbcinst failed to register the driver"
}

pkg_prerm() {
	odbcinst -u -d -n "ODBC Driver ${SLOT} for SQL Server" || ewarn "odbcinst failed to remove the driver"
}
