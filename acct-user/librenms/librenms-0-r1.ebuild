# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="A user for Librenms"
ACCT_USER_ID=312
ACCT_USER_HOME=/opt/librenms
ACCT_USER_GROUPS=( librenms )

IUSE="apache2 nginx"

acct-user_add_deps

pkg_setup() {
	use apache2 && ACCT_USER_GROUPS+=( "apache" )
	use nginx && ACCT_USER_GROUPS+=( "nginx" )
}