# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

NODEJS_MANAGER="pnpm"
inherit desktop multiprocessing nodejs optfeature systemd toolchain-funcs xdg

# The Electron major that package.json pins.
ELECTRON_SLOT="43"
ORCA_TARGET="linux-x64-glibc"

DESCRIPTION="IDE to run coding agents in parallel, each in its own git worktree"
HOMEPAGE="
	https://www.onorca.dev/
	https://github.com/stablyai/orca
"
# The node_modules of the main and of the mobile pnpm workspaces, named after
# their lockfiles: livecheck reuses it while the dependencies do not change.
SRC_URI="
	https://github.com/stablyai/orca/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://www.inode64.com/dist/${PN}-1ce934fcd7143d70-node_modules.tar.xz
"
S="${WORKDIR}/orca-${PV}"

LICENSE="MIT"
# Dependent licenses of what the app, orcad and the mobile web client ship;
# all-rights-reserved is the Claude Agent SDK.
LICENSE+=" 0BSD Apache-2.0 BlueOak-1.0.0 BSD BSD-2 ISC PSF-2 Unlicense all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+gui server wayland"
REQUIRED_USE="
	|| ( gui server )
	wayland? ( gui )
"
# Vitest and Playwright suites that drive a running Electron app.
RESTRICT="bindist mirror test"

# node runs orcad, the CLI and the terminal daemon of the desktop app. The
# native addons target N-API 8, so they do not depend on the Node ABI.
RDEPEND="
	>=net-libs/nodejs-24:*
	dev-vcs/git
	sys-apps/ripgrep
	gui? ( dev-util/electron-bin:${ELECTRON_SLOT} )
	wayland? ( dev-libs/wayland )
"
DEPEND="wayland? ( dev-libs/wayland )"
BDEPEND="
	>=net-libs/nodejs-24:*
	gui? ( dev-util/electron-bin:${ELECTRON_SLOT} )
"

# Prebuilt by upstream and shipped through npm: the agent-browser driver, the
# file watcher and the koffi FFI addons.
QA_PREBUILT="
	usr/lib*/${PN}/resources/agent-browser-*
	usr/lib*/${PN}/*/watcher.node
	usr/lib*/${PN}/resources/node_modules/@koromix/*
"

src_unpack() {
	nodejs_unpack
}

src_prepare() {
	local PATCHES=(
		"${FILESDIR}"/${PN}-1.4.274-build-commit.patch
		"${FILESDIR}"/${PN}-1.4.274-no-auto-update.patch
		"${FILESDIR}"/${PN}-1.4.274-system-node.patch
		"${FILESDIR}"/${PN}-1.4.274-electron-builder.patch
	)
	use wayland || PATCHES+=( "${FILESDIR}"/${PN}-1.4.274-no-wayland-clipboard.patch )

	default
}

src_compile() {
	local node_prefix
	node_prefix=$(node -p 'path.resolve(process.execPath, "../..")') ||
		die "Failed to find the prefix of node"

	# config/pnpmfile.cjs links the dependencies from a store shared by the
	# user unless it runs under CI.
	export CI=true
	# The official skills that the app installs clone this ref.
	export ORCA_BUILD_COMMIT="v${PV}"
	# See the system-node patch: no pinned Node, no downloads.
	export ORCA_SYSTEM_NODE="${EPREFIX}/usr/bin/node"
	export ORCA_SYSTEM_NODEDIR="${node_prefix}"
	# The default, Bun, needs the binary that its postinstall step links.
	export ORCA_CLI_BUILD_COMPILER=tsrs
	export ELECTRON_SKIP_BINARY_DOWNLOAD=1 PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
	export EXPO_NO_TELEMETRY=1 EXPO_OFFLINE=1
	tc-export AR CC CXX
	# The terminal daemon that the build checks names its process.
	addpredict /proc/self/comm

	enpm run build:packages || die "build:packages failed"
	# build:cli without prepare:cli-output, which links orca-dev into
	# /usr/local/bin.
	node config/scripts/cli-build/build-cli.mjs || die "Failed to build the CLI"
	node config/scripts/cli-build/verify-cli-bin.mjs --fix-executable --fix-package-json ||
		die "Failed to verify the CLI"
	# The postinstall step of the mobile workspace generates sources of the
	# web client.
	enpm --dir mobile run postinstall || die "Failed to prepare the mobile workspace"
	enpm run build:mobile-web || die "build:mobile-web failed"
	# orcad for this host. The server runs it, and the desktop app serves
	# with it and copies it to SSH hosts of the same target; Orca builds the
	# other targets on the remote host itself.
	enpm run build:orcad-template --targets "${ORCA_TARGET}" ||
		die "build:orcad-template failed"

	if use server; then
		node config/scripts/orcad-distribution/server-artifact/pack-orcad-server-artifact.mjs \
			--template out/orcad-template --target "${ORCA_TARGET}" --out-dir out/orca-server ||
			die "Failed to pack the server"
		mkdir "${WORKDIR}"/server || die
		tar -xzf out/orca-server/orca-server-linux-x64.tar.gz --strip-components=1 \
			-C "${WORKDIR}"/server || die
	fi

	use gui && orca_compile_gui
}

orca_compile_gui() {
	local electron="${EPREFIX}/opt/electron-bin-${ELECTRON_SLOT}"

	# Build tools that require('electron') get the system runtime.
	export ELECTRON_OVERRIDE_DIST_PATH="${electron}"

	enpm run build:electron-vite || die "build:electron-vite failed"
	enpm run verify:built-skills-cli || die "verify:built-skills-cli failed"
	enpm run build:web-from-renderer || die "build:web-from-renderer failed"

	# node-pty is the one native addon of the app on Linux. Upstream rebuilds
	# it in its postinstall step, which first fetches Electron; it targets
	# N-API, so the headers of the system Electron are enough.
	local pty
	pty=$(readlink -f node_modules/node-pty) || die
	pushd "${pty}" >/dev/null || die
	node "${S}"/node_modules/node-gyp/bin/node-gyp.js rebuild --jobs "$(get_makeopts_jobs)" \
		--nodedir="${electron}/node_headers" || die "Failed to build node-pty"
	popd >/dev/null || die

	# Upstream builds these helpers in Docker for an old glibc; build them
	# here where the extraResources of electron-builder expect them.
	local cc
	cc=$(tc-getCC)
	mkdir -p native/provider-exec/.build/linux-x64 native/journal-file-lock/.build/x64 || die
	${cc} ${CPPFLAGS} ${CFLAGS} ${LDFLAGS} -std=c11 native/provider-exec/provider-exec.c \
		-o native/provider-exec/.build/linux-x64/orca-provider-exec || die
	${cc} ${CPPFLAGS} ${CFLAGS} ${LDFLAGS} native/journal-file-lock/main.c \
		-o native/journal-file-lock/.build/x64/journal-file-lock || die
	if use wayland; then
		mkdir -p native/wayland-clipboard/.build/x64 || die
		${cc} ${CPPFLAGS} ${CFLAGS} ${LDFLAGS} native/wayland-clipboard/wayland-clipboard.c \
			native/wayland-clipboard/x11-clipboard-publisher.c -ldl \
			-o native/wayland-clipboard/.build/x64/orca-wayland-clipboard || die
	fi

	# electron-builder copies the whole runtime, and the build user cannot read
	# the setuid chrome-sandbox. Only the resources of that copy are installed.
	cp -rs "${electron}" "${T}"/electron-dist || die
	rm "${T}"/electron-dist/chrome-sandbox || die

	# --dir: only the unpacked app, no AppImage, deb or rpm (nor the fpm and
	# 7-Zip downloads they need).
	node node_modules/electron-builder/cli.js --config config/electron-builder.config.cjs \
		--dir --publish=never --config.electronDist="${T}"/electron-dist ||
		die "electron-builder failed"
}

# @USAGE: <directory in ${ED}>
# The app looks for rg only at its own path, never in PATH: point those
# copies to the system ripgrep and drop the ones of other platforms.
orca_link_ripgrep() {
	local rg
	find "${ED}${1}" -type d \( -path '*/ripgrep/darwin-*' -o -path '*/ripgrep/win32-*' \
		-o -path '*/ripgrep/linux-arm64*' \) -prune -exec rm -r {} + || die
	while IFS= read -r -d '' rg; do
		rm "${rg}" || die
		dosym -r /usr/bin/rg "${rg#"${ED}"}"
	done < <(find "${ED}${1}" -type f -name rg -path '*ripgrep*' -print0)
}

src_install() {
	local dir="/usr/$(get_libdir)/${PN}"

	einstalldocs

	if use server; then
		dodir "${dir}"
		cp -a "${WORKDIR}"/server "${ED}${dir}"/server || die
		orca_link_ripgrep "${dir}"/server

		local server="${EPREFIX}${dir}/server/bin/orca-ide"
		sed "s|@ORCA_SERVER@|${server}|" "${FILESDIR}"/orca-ide.initd > "${T}"/orca-ide || die
		doinitd "${T}"/orca-ide
		newconfd "${FILESDIR}"/orca-ide.confd orca-ide
		sed "s|@ORCA_SERVER@|${server}|" "${FILESDIR}"/orca-ide_at.service \
			> "${T}"/orca-ide@.service || die
		systemd_dounit "${T}"/orca-ide@.service

		use gui || dosym -r "${dir}"/server/bin/orca-ide /usr/bin/orca-ide
	fi

	if use gui; then
		# electron-builder --dir laid out a whole app; Electron itself comes
		# from dev-util/electron-bin, so only its resources are needed.
		dodir "${dir}"
		cp -a dist/linux-unpacked/resources "${ED}${dir}"/resources || die
		# The default app of the Electron runtime, the musl build of koffi and
		# the intermediate objects of node-gyp are not used.
		rm -r "${ED}${dir}"/resources/default_app.asar \
			"${ED}${dir}"/resources/node_modules/@koromix/koffi-linux-x64/musl_x64 || die
		find "${ED}${dir}"/resources -type d -name obj.target -path '*/build/Release/*' \
			-prune -exec rm -r {} + || die
		insinto "${dir}"/resources
		doins "${FILESDIR}"/resources-path-override.cjs

		sed -e "s|@ELECTRON@|${EPREFIX}/opt/electron-bin-${ELECTRON_SLOT}/electron|" \
			-e "s|@APPDIR@|${EPREFIX}${dir}|g" "${FILESDIR}"/orca-ide-launcher \
			> "${T}"/orca-ide || die
		exeinto "${dir}"
		doexe "${T}"/orca-ide

		# The terminal daemon runs on this Node, bundled upstream.
		dosym -r /usr/bin/node "${dir}"/resources/node-runtime/bin/node
		orca_link_ripgrep "${dir}"/resources
		dosym -r "${dir}"/resources/bin/orca-ide /usr/bin/orca-ide

		# By absolute path: icon themes such as Faenza provide an "orca" icon
		# (the screen reader), which the name lookup would fall back to.
		newicon resources/build/icon.png ${PN}.png
		newicon -s 256 resources/icon.png ${PN}.png
		make_desktop_entry "${EPREFIX}${dir}/orca-ide %U" Orca \
			"${EPREFIX}/usr/share/pixmaps/${PN}.png" "Development" "StartupWMClass=orca"
	fi
}

pkg_postinst() {
	xdg_pkg_postinst

	if use server; then
		elog "The server runs as the user whose repositories and agents it serves:"
		elog "  OpenRC:  ln -s orca-ide /etc/init.d/orca-ide.<user>"
		elog "           rc-update add orca-ide.<user> default"
		elog "  systemd: systemctl enable --now orca-ide@<user>.service"
		elog "It listens on 127.0.0.1 by default; set the address in"
		elog "/etc/conf.d/orca-ide (or with systemctl edit) and pair a client with"
		elog "  orca-ide pair --address <address>"
		elog "as that user. Do not expose the port to the Internet."
		elog "The memory limits of ORCA_TERMINAL_MEMORY_MAX need systemd with a user"
		elog "manager that outlives logout: loginctl enable-linger <user>."
	fi
	optfeature "the Claude Code agent" dev-util/claude-code
	optfeature "the Codex agent" dev-util/codex-bin
	optfeature "the OpenCode agent" dev-util/opencode-bin
	if use gui; then
		optfeature "computer use on X11" \
			"dev-python/pygobject app-accessibility/at-spi2-core[introspection] x11-misc/xdotool x11-misc/xclip"
	fi
}
