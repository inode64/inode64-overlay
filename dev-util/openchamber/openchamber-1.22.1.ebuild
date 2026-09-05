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
S="${WORKDIR}/${P}"

LICENSE="0BSD Apache-2.0 BSD BSD-2 ISC MIT MPL-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+dictation"

# node-pty is a native addon built against the Node ABI, hence the subslot dep.
RDEPEND="
	acct-group/openchamber
	acct-user/openchamber
	net-libs/nodejs:=[npm]
"

# The npm release ships only the build output, not the sources or the test
# toolchain the test script needs.
RESTRICT="test"

NODEJS_EXTRA_FILES="public server"

# bun-pty ships an already stripped prebuilt library.
QA_PREBUILT="usr/lib*/node_modules/@openchamber/web/node_modules/bun-pty/rust-pty/target/release/*.so"

#src_unpack() {
#	unpack ${P}.tgz
#
#	# The npm archive always unpacks into package/; give it the usual name so
#	# that the node_modules archive, which uses ${P}/, lands on top of it.
#	mv "${WORKDIR}"/package "${S}" || die
#
#	# livecheck drops this one from SRC_URI while it regenerates the archive.
#	if has ${P}-node_modules.tar.xz ${A}; then
#		unpack ${P}-node_modules.tar.xz
#	fi
#}

src_prepare() {
	# Speech to text pulls in ~25MiB of prebuilt onnxruntime libraries and is
	# only loaded on demand, so it can simply be left out. Drop it from the
	# dependencies as well, otherwise "npm prune" trips over the gap.
	local drop_dictation=
	use dictation || drop_dictation=1

	# The npm release ships the prebuilt frontend in dist/, but keeps the
	# monorepo scripts, which need sources and a toolchain that are not part
	# of the tarball. Drop them so the eclass does not try to rebuild them.
	OPENCHAMBER_DROP_DICTATION=${drop_dictation} \
		node -e 'const fs = require("fs"), p = JSON.parse(fs.readFileSync("package.json"));
		delete p.scripts.build; delete p.scripts.test; delete p.devDependencies;
		if (process.env.OPENCHAMBER_DROP_DICTATION) delete p.dependencies["sherpa-onnx-node"];
		fs.writeFileSync("package.json", JSON.stringify(p, null, 2) + "\n");' || die

	if [[ -n ${drop_dictation} ]]; then
		rm -rf node_modules/sherpa-onnx-node node_modules/sherpa-onnx-linux-* || die
	fi

	nodejs-mod_src_prepare
}

src_install() {
	# bun-pty vendors a prebuilt library per OS and ABI; only the native one
	# is usable and the others trip the QA checks. It is loaded only when
	# OpenChamber runs under bun, node-pty covers the Node.js case.
	rm -rf node_modules/bun-pty/rust-pty/target/release/*.dll \
		node_modules/bun-pty/rust-pty/target/release/*.dylib \
		node_modules/bun-pty/rust-pty/target/release/*_arm64*.so \
		node_modules/bun-pty/rust-pty/target/release/*_musl.so || die

	# node-gyp intermediates and the Windows-only parts of node-pty; the
	# addon itself stays in build/Release.
	rm -rf node_modules/node-pty/build/Release/obj.target \
		node_modules/node-pty/build/Release/node-addon-api \
		node_modules/node-pty/build/config.gypi \
		node_modules/node-pty/third_party \
		node_modules/node-pty/src || die

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
