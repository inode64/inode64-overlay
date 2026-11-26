# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.98.0"

inherit cargo shell-completion wrapper

DESCRIPTION="Fast, disk space efficient package manager"
HOMEPAGE="
	https://pnpm.io/
	https://github.com/pnpm/pnpm
"
SRC_URI="
	https://github.com/pnpm/pnpm/archive/v${PV}.tar.gz -> ${P}.tar.gz
	https://www.inode64.com/dist/${P}-crates.tar.xz
"

LICENSE="MIT"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 BSD BSD-2 Boost-1.0 CDLA-Permissive-2.0 ISC MPL-2.0
	Unicode-3.0 ZLIB
"
SLOT="0"
KEYWORDS="~amd64"
# The tests run through cargo-nextest against a mock registry, and need the
# JavaScript workspace that `pnpm install` fetches.
RESTRICT="test"

DEPEND="
	app-arch/zstd:=
	dev-db/sqlite:3
"
# pnpm is a native binary, but lifecycle scripts and node-gyp run on Node.js.
RDEPEND="
	${DEPEND}
	net-libs/nodejs
"
BDEPEND="virtual/pkgconfig"

src_prepare() {
	default

	# The crate tarball also carries upstream's git forks (libsql, node-semver,
	# dashmap) as vendored by `cargo vendor`: point their sources at it.
	local src
	while read -r src; do
		cat >> "${ECARGO_HOME}/config.toml" <<-EOF || die
		[source."git+${src}"]
		git = "${src%%\?*}"
		rev = "${src#*rev=}"
		replace-with = "gentoo"
		EOF
	done < <(sed -n 's/^source = "git+\([^#]*\)#.*"$/\1/p' Cargo.lock | sort -u)
}

src_configure() {
	# Link the system libraries instead of the copies bundled in the -sys
	# crates. Exported for all phases: a change would make cargo rebuild.
	export LIBSQLITE3_SYS_USE_PKG_CONFIG=1 ZSTD_SYS_USE_PKG_CONFIG=1
	cargo_src_configure
}

src_compile() {
	cargo_src_compile -p pnpm-cli --bin pnpm

	local shell
	for shell in bash fish zsh; do
		"$(cargo_target_dir)"/pnpm completion ${shell} > pnpm.${shell} || die
	done
}

src_install() {
	dobin "$(cargo_target_dir)"/pnpm
	dosym pnpm /usr/bin/pn
	# pnpm takes its launch name from /proc/self/exe, so a symlink cannot make
	# it run `dlx`: like upstream's Unix aliases, these are scripts.
	make_wrapper pnpx "/usr/bin/pnpm dlx"
	make_wrapper pnx "/usr/bin/pnpm dlx"

	newbashcomp pnpm.bash pnpm
	bashcomp_alias pnpm pn
	newfishcomp pnpm.fish pnpm.fish
	# fish autoloads a command's completions from <command>.fish only.
	dosym pnpm.fish "$(get_fishcompdir)"/pn.fish
	newzshcomp pnpm.zsh _pnpm

	einstalldocs
}
