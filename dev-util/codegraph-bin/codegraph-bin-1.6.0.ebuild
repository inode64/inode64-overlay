# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Pre-indexed code knowledge graph and MCP server for AI coding agents"
HOMEPAGE="https://colbymchenry.github.io/codegraph/
	https://github.com/colbymchenry/codegraph"
# Upstream refuses to run on Node.js >= 25 (V8 turboshaft WASM Zone OOM while
# compiling the tree-sitter grammars, upstream issue #81) and needs >= 22.5 for
# node:sqlite, so net-libs/nodejs cannot be relied on. Use the self-contained
# release bundle, which carries the Node.js runtime it was tested against.
SRC_URI="
	amd64? (
		https://github.com/colbymchenry/codegraph/releases/download/v${PV}/codegraph-linux-x64.tar.gz
			-> ${P}-linux-x64.tar.gz
	)
	arm64? (
		https://github.com/colbymchenry/codegraph/releases/download/v${PV}/codegraph-linux-arm64.tar.gz
			-> ${P}-linux-arm64.tar.gz
	)
"
S="${WORKDIR}"

# MIT for codegraph itself, the rest comes from the bundled Node.js runtime
# and the vendored node_modules.
LICENSE="MIT Apache-1.1 Apache-2.0 BlueOak-1.0.0 BSD BSD-2 Unlicense"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
RESTRICT="strip"

RDEPEND="
	sys-devel/gcc
	sys-libs/glibc
"

QA_PREBUILT="opt/codegraph/*"

src_install() {
	local bundle
	if use amd64; then
		bundle=codegraph-linux-x64
	elif use arm64; then
		bundle=codegraph-linux-arm64
	else
		die "Unsupported architecture"
	fi

	# The launcher locates the runtime relative to itself, so keep the
	# upstream layout (bin/ lib/ node) untouched.
	insinto /opt/codegraph
	doins -r "${bundle}"/lib
	exeinto /opt/codegraph
	doexe "${bundle}"/node
	exeinto /opt/codegraph/bin
	doexe "${bundle}"/bin/codegraph

	# "codegraph upgrade" and the daily update check re-run upstream's
	# install.sh, which would drop a second copy in ~/.codegraph shadowing
	# this one. Updates come from the package manager, so silence the check.
	newbin - codegraph <<-EOF
		#!/bin/sh
		export CODEGRAPH_NO_UPDATE_CHECK="\${CODEGRAPH_NO_UPDATE_CHECK:-1}"
		exec /opt/codegraph/bin/codegraph "\$@"
	EOF
}

pkg_postinst() {
	elog "Register the MCP server in your agents (Claude Code, Codex, Cursor, ...)"
	elog "with"
	elog "    codegraph install"
	elog "and index a project with"
	elog "    codegraph init"
	elog
	elog "Do not use \"codegraph upgrade\": it installs a second copy under"
	elog "~/.codegraph. Update through the package manager instead."
	elog
	elog "CodeGraph sends anonymous usage statistics by default. Opt out with"
	elog "    codegraph telemetry off"
	elog "or by exporting CODEGRAPH_TELEMETRY=0 or DO_NOT_TRACK=1."
}
