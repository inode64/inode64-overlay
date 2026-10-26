# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit nodejs-mod

DESCRIPTION="CLI to synchronize rules and configuration across AI coding tools"
HOMEPAGE="https://rulesync.dyoshikawa.com/
	https://github.com/dyoshikawa/rulesync"
SRC_URI="https://github.com/dyoshikawa/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://www.inode64.com/dist/${P}-node_modules.tar.xz"

LICENSE="Apache-2.0 BSD BSD-2 ISC MIT PSF-2 PYTHON"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-vcs/git
	>=net-libs/nodejs-22.13.0
"
BDEPEND=">=net-libs/nodejs-24.11.0[npm]"

src_unpack() {
	default

	# livecheck populates node_modules after unpacking. Translate the pnpm
	# overrides before that step so npm builds the same gray-matter/YAML tree.
	cd "${S}" || die
	node -e '
		const fs = require("fs");
		const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
		pkg.overrides = {
			"gray-matter": { "js-yaml": "4.3.2" },
			"js-yaml@<4.3.2": "4.3.2"
		};
		fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2) + "\n");
	' || die "Failed to prepare npm dependencies"

	# Use the public registry when livecheck regenerates the dependency archive.
	sed -i '/^registry=/d' .npmrc || die
}

src_prepare() {
	nodejs-mod_src_prepare

	# npm does not apply pnpm's dependency patches. Keep upstream's removal
	# of gray-matter's JavaScript evaluator and its js-yaml v4 compatibility.
	pushd node_modules/gray-matter >/dev/null || die
	eapply "${S}/patches/gray-matter@4.0.3.patch"
	popd >/dev/null || die

	# This integration test executes an Amp hook in Bun, which is not needed
	# to run rulesync and is not available in the Gentoo tree.
	sed -i '/it("should preserve shell quoting and expansion when executed by Bun Shell"/s/it(/it.skip(/' \
		src/features/hooks/amp-hooks.test.ts || die
}
