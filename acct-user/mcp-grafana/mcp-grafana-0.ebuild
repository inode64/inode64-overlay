# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="User for app-metrics/mcp-grafana under OpenRC"
# Dynamic, as acct-user.eclass asks of overlays, so it cannot clash with ::gentoo.
ACCT_USER_ID=-1
ACCT_USER_GROUPS=( mcp-grafana )

acct-user_add_deps
