# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="User for app-metrics/varnish_exporter"
# Dynamic, as acct-user.eclass asks of overlays, so it cannot clash with ::gentoo.
ACCT_USER_ID=-1
# The stats tool reads the cache's VSM files, 0640 to its group: vinyl for
# Vinyl Cache (vinylstat), varnish for Varnish Cache (varnishstat).
ACCT_USER_GROUPS=( varnish_exporter vinyl varnish )

acct-user_add_deps
