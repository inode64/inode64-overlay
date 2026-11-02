# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-group

# Dynamic, as acct-group.eclass asks of overlays, so it cannot clash with ::gentoo.
ACCT_GROUP_ID=-1
