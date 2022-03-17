# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

ACCT_USER_ID=970
ACCT_USER_GROUPS=( libvirtdbus )
DESCRIPTION="Libvirt D-Bus bridge"

acct-user_add_deps
