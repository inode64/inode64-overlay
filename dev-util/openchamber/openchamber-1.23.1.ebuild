# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit nodejs-mod systemd tmpfiles

DESCRIPTION="Agentic development environment based on the OpenCode AI agent"
HOMEPAGE="https://openchamber.dev/
	https://github.com/openchamber/openchamber"
# The GitHub tarball is a bun workspace that needs the full frontend toolchain,
# so use the npm release instead: it ships the prebuilt dist/.
SRC_URI="https://registry.npmjs.org/@openchamber/web/-/web-${PV}.tgz -> ${P}.tgz
	https://www.inode64.com/dist/${P}-node_modules.tar.xz"
S="${WORKDIR}/package"

LICENSE="0BSD Apache-2.0 BSD BSD-2 ISC MIT MPL-2.0"
SLOT="0"
KEYWORDS="~amd64"

# node-pty is a native addon built against the Node ABI, hence the subslot dep.
RDEPEND="
	acct-group/openchamber
	acct-user/openchamber
	net-libs/nodejs:=[npm]
"

# The prebuilt sherpa-onnx addon needs its RUNPATH fixed, see src_prepare().
BDEPEND="dev-util/patchelf"

# The npm release ships only the build output, not the sources or the test
# toolchain the test script needs.
RESTRICT="test"

NODEJS_EXTRA_FILES="public server"

# OpenChamber is an application, nothing is ever compiled against it, so the
# TypeScript declarations its dependencies ship are dead weight.
NODEJS_REMOVE_TYPES=1

src_prepare() {
	# The npm release ships the prebuilt frontend in dist/, but keeps the
	# monorepo scripts, which need the sources (index.html, src/,
	# vite.config.ts) and a toolchain that are not part of the tarball.
	# Drop them so the eclass does not try to rebuild them.
	#
	# bun-pty goes with them. It is a prebuilt Rust library, the tarball
	# carries no crate to rebuild it from, and server/lib/terminal/runtime.js
	# only reaches for it when globalThis.Bun is defined. This runs under
	# Node.js, so node-pty, which is built here from its own sources, is what
	# gets loaded; even under bun the import is wrapped in a try and falls
	# back to it. Drop it from the dependencies as well, otherwise "npm
	# prune" trips over the gap.
	node -e 'const fs = require("fs"), p = JSON.parse(fs.readFileSync("package.json"));
		delete p.scripts.build; delete p.scripts.test; delete p.devDependencies;
		delete p.dependencies["bun-pty"];
		fs.writeFileSync("package.json", JSON.stringify(p, null, 2) + "\n");' || die

	rm -rf node_modules/bun-pty || die

	# The prebuilt speech to text addon carries the RUNPATH of the upstream
	# CI builder, "$ORIGIN:/home/runner/...:", whose trailing empty entry
	# means the current directory and trips the scanelf security check. The
	# sibling libraries it needs sit next to it, so $ORIGIN alone is enough.
	patchelf --set-rpath '$ORIGIN' \
		node_modules/sherpa-onnx-linux-x64/sherpa-onnx.node || die

	nodejs-mod_src_prepare
}

src_install() {
	nodejs-mod_src_install

	dotmpfiles "${FILESDIR}"/${PN}.conf

	newconfd "${FILESDIR}"/${PN}.confd ${PN}
	doinitd "${FILESDIR}"/${PN}
	systemd_dounit "${FILESDIR}"/${PN}.service
}

pkg_postinst() {
	tmpfiles_process ${PN}.conf

	elog "OpenChamber drives the standalone OpenCode CLI, which has no ebuild in"
	elog "the Gentoo tree. Install it before starting the service, either from an"
	elog "overlay that carries it (dev-util/opencode-bin in ::gentoo-zh) or with"
	elog "    npm install -g opencode-ai"
	elog "Any opencode binary in PATH is picked up; otherwise point"
	elog "settings.opencodeBinary at it."
	elog
	elog "The service listens on 127.0.0.1:3000. OpenRC reads the port and the"
	elog "bind address from /etc/conf.d/${PN}; for systemd override them with"
	elog "    systemctl edit ${PN}.service"
	ewarn "Do not expose OpenChamber to a network without setting a UI password"
	ewarn "(--ui-password / OPENCHAMBER_UI_PASSWORD): it runs an agent with full"
	ewarn "access to the files and the shell of the openchamber user."
}
