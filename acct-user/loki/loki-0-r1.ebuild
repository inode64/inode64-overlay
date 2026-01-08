# Copyright 2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="Loki program user"

ACCT_USER_ID=200
ACCT_USER_GROUPS=( grafana )

acct-user_add_deps
