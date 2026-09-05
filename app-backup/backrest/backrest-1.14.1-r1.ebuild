# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

NODEJS_MOD_PREFIX="webui"
inherit go-module nodejs nodejs-mod systemd tmpfiles

DESCRIPTION="A web UI and orchestrator for restic backup"
HOMEPAGE="https://github.com/garethgeorge/backrest"

# paraglide-js fetches these two plugins while generating the translations,
# see src_prepare(). webui/project.inlang/settings.json asks jsdelivr for "@4"
# and "@2", which resolve to whatever is current and would make the build
# unreproducible, so pin what those ranges resolved to.
INLANG_MESSAGE_FORMAT_PV=4.4.4
INLANG_M_FUNCTION_MATCHER_PV=2.2.9

SRC_URI="https://github.com/garethgeorge/backrest/archive/v${PV}.tar.gz -> ${P}.tar.gz
	https://www.inode64.com/dist/${P}-vendor.tar.xz
	https://www.inode64.com/dist/${P}-node_modules.tar.xz
	https://cdn.jsdelivr.net/npm/@inlang/plugin-message-format@${INLANG_MESSAGE_FORMAT_PV}/dist/index.js
		-> inlang-plugin-message-format-${INLANG_MESSAGE_FORMAT_PV}.js
	https://cdn.jsdelivr.net/npm/@inlang/plugin-m-function-matcher@${INLANG_M_FUNCTION_MATCHER_PV}/dist/index.js
		-> inlang-plugin-m-function-matcher-${INLANG_M_FUNCTION_MATCHER_PV}.js
"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"
RESTRICT="
	!test? ( test )
"
BDEPEND="test? ( app-backup/restic )"
RDEPEND="
	app-backup/restic
	!app-backup/backrest-bin
"
DEPEND=">=dev-lang/go-1.26"

src_prepare() {
	# The webui build is the only part that still wanted the network:
	# paraglide-js imports the plugins listed in project.inlang/settings.json
	# straight from a CDN. The inlang SDK also accepts a plugin as a path
	# relative to the directory holding project.inlang, so drop the copies
	# from SRC_URI next to it and point the settings at those.
	local plugin
	for plugin in \
		inlang-plugin-message-format-${INLANG_MESSAGE_FORMAT_PV} \
		inlang-plugin-m-function-matcher-${INLANG_M_FUNCTION_MATCHER_PV}
	do
		cp "${DISTDIR}/${plugin}.js" "webui/${plugin%-*}.js" || die
	done

	node -e 'const fs = require("fs"), f = "webui/project.inlang/settings.json";
		const settings = JSON.parse(fs.readFileSync(f));
		settings.modules = settings.modules.map((module) => {
			const name = module.match(/@inlang\/(plugin-[^@]+)@/)?.[1];
			if (!name) throw new Error("unexpected module " + module);
			return "./inlang-" + name + ".js";
		});
		fs.writeFileSync(f, JSON.stringify(settings, null, 2) + "\n");' || die

	nodejs-mod_src_prepare
}

src_compile() {
	# Builds the native addons of webui/ and then runs its build script.
	nodejs-mod_src_compile

	ego build -trimpath -ldflags="-s -w" \
		-ldflags "-X 'main.version=${PV}' -X 'main.commit=${PR}'" \
		-o backrest ./cmd/backrest || die
}

src_test() {
	BACKREST_RESTIC_COMMAND=/usr/bin/restic ego test ./... || die "test failed"
}

src_install() {
	dobin backrest
	dodoc *.md

	dotmpfiles "${FILESDIR}/${PN}.tmpfiles.conf"
	newinitd "${FILESDIR}/${PN}.initd" ${PN}
	systemd_dounit "${FILESDIR}/${PN}.service"
}

pkg_postinst() {
	tmpfiles_process backrest.tmpfiles.conf
}
