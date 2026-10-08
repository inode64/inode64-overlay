# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.85.0"

inherit cargo git-r3 shell-completion

DESCRIPTION="All-in-one LLM CLI Tool"
HOMEPAGE="https://github.com/sigoden/aichat"
EGIT_REPO_URI="https://github.com/sigoden/aichat.git"

LICENSE="|| ( Apache-2.0 MIT )"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 BSD Boost-1.0 CDLA-Permissive-2.0 ISC LGPL-3+ MIT MPL-2.0
	Unicode-3.0 ZLIB
"
SLOT="0"

# Crates are fetched from crates.io at unpack time.
PROPERTIES="live"

# reqwest is built with rustls, so no OpenSSL dependency.
BDEPEND="virtual/pkgconfig"

QA_FLAGS_IGNORED="usr/bin/aichat"

src_unpack() {
	git-r3_src_unpack
	cargo_live_src_unpack
}

src_install() {
	cargo_src_install
	dodoc README.md
	docinto examples
	dodoc config.example.yaml

	newbashcomp scripts/completions/aichat.bash aichat
	newzshcomp scripts/completions/aichat.zsh _aichat
	newfishcomp scripts/completions/aichat.fish aichat.fish

	# Shell integration (Alt-E turns a natural language prompt into a command).
	insinto /usr/share/aichat/shell-integration
	doins scripts/shell-integration/integration.{bash,fish,zsh}
}

pkg_postinst() {
	elog "Configure aichat in ~/.config/aichat/config.yaml. For the local"
	elog "lemonade server (sci-ml/lemonade) point an openai-compatible client at"
	elog "  api_base: http://127.0.0.1:13305/api/v1"
	elog "A sample config is in /usr/share/doc/${PF}/examples/, shell"
	elog "integration scripts in /usr/share/aichat/shell-integration/."
}
