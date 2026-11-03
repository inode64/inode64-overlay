# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Codex CLI - OpenAI's AI-powered coding agent (prebuilt binary)"
HOMEPAGE="https://github.com/openai/codex"

SRC_URI="
	amd64? (
		https://github.com/openai/codex/releases/download/rust-v${PV}/codex-x86_64-unknown-linux-musl.tar.gz
			-> ${P}-x86_64-unknown-linux-musl.tar.gz
		https://github.com/openai/codex/releases/download/rust-v${PV}/codex-code-mode-host-x86_64-unknown-linux-musl.tar.gz
			-> ${P}-code-mode-host-x86_64-unknown-linux-musl.tar.gz
	)
	arm64? (
		https://github.com/openai/codex/releases/download/rust-v${PV}/codex-aarch64-unknown-linux-musl.tar.gz
			-> ${P}-aarch64-unknown-linux-musl.tar.gz
		https://github.com/openai/codex/releases/download/rust-v${PV}/codex-code-mode-host-aarch64-unknown-linux-musl.tar.gz
			-> ${P}-code-mode-host-aarch64-unknown-linux-musl.tar.gz
	)
"

S="${WORKDIR}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
RESTRICT="strip"

RDEPEND="
	!dev-util/codex
	>=sys-apps/bubblewrap-0.11.2
	sys-apps/ripgrep
"

QA_PREBUILT="
	usr/bin/codex
	usr/bin/codex-code-mode-host
"

src_install() {
	local target
	if use amd64; then
		target=x86_64-unknown-linux-musl
	elif use arm64; then
		target=aarch64-unknown-linux-musl
	else
		die "Unsupported architecture"
	fi

	newbin codex-${target} codex
	# Codex runs the tools of the code_mode_only models through this helper,
	# which it looks up next to its own executable, and fails closed without it.
	newbin codex-code-mode-host-${target} codex-code-mode-host
}
