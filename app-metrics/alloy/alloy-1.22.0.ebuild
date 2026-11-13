# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

NODEJS_MOD_PREFIX="internal/web/ui"
inherit go-env go-module nodejs-mod shell-completion systemd tmpfiles

DESCRIPTION="OpenTelemetry Collector distribution with programmable pipelines"
HOMEPAGE="https://grafana.com/oss/alloy/ https://github.com/grafana/alloy"
SRC_URI="https://github.com/grafana/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz
	https://www.inode64.com/dist/${P}-vendor.tar.xz
	https://www.inode64.com/dist/${P}-node_modules.tar.xz
"

LICENSE="Apache-2.0"
# Dependent licenses. The logql packages of Loki are AGPL-3.
LICENSE+=" 0BSD AGPL-3 BSD BSD-2 ISC MIT MIT-0 MPL-2.0"
# Icons and fonts of the embedded web UI
LICENSE+=" CC-BY-4.0 OFL-1.1"
SLOT="0"
# The node_modules tarball carries the esbuild and rollup binaries for amd64.
KEYWORDS="~amd64"
IUSE="systemd"

# go-systemd builds against the headers of libsystemd and opens it with
# dlopen() to read the journal.
DEPEND="
	app-arch/zstd:=
	systemd? ( sys-apps/systemd )
"
RDEPEND="${DEPEND}
	acct-user/alloy
	app-misc/ca-certificates
	!app-metrics/alloy-bin
"
BDEPEND="
	>=dev-lang/go-1.27.3
	>=net-libs/nodejs-24.16
"

src_unpack() {
	# go-module verifies the root module against the network when there is
	# no vendor/ beside it, but the module that builds the binary, and the
	# one vendored, is collector/.
	default
	go-env_set_compile_environment
}

src_prepare() {
	# collector/go.mod replaces github.com/grafana/alloy with ../, so go mod
	# vendor copies those packages into collector/vendor, and the build
	# compiles that copy instead of ${S}. Changes to Alloy itself go there.
	local vendored=collector/vendor/github.com/grafana/${PN}

	# Trust only the system CA store, as Nixpkgs does: the fallback bundle is
	# frozen at the vendored x/crypto and would take over unnoticed if the
	# store went missing.
	sed -i -e '\|"golang.org/x/crypto/x509roots/fallback"|d' ${vendored}/flowcmd/flowcmd.go || die
	if grep -rq --include='*.go' 'x509roots/fallback"' ${vendored}; then
		die "The fallback CA bundle is still imported"
	fi

	nodejs-mod_src_prepare
}

src_configure() {
	# The tags of the upstream release, plus the system libzstd instead of
	# the copy that DataDog/zstd bundles, as Alpine does.
	ALLOY_TAGS="embedalloyui,gore2regex,netgo,external_libzstd"
	use systemd && ALLOY_TAGS+=",promtail_journal_enabled"

	local vprefix="github.com/grafana/${PN}/internal/build"
	local ldflags=(
		-X ${vprefix}.Version=v${PV}
		-X github.com/grafana/${PN}/syntax/internal/stdlib.Version=v${PV}
		-X ${vprefix}.Branch=v${PV}
		-X ${vprefix}.Revision=v${PV}
		-X ${vprefix}.BuildUser=portage@gentoo
		-X ${vprefix}.BuildDate=$(date -u -d "@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y-%m-%dT%H:%M:%SZ)
	)
	ALLOY_LDFLAGS="${ldflags[*]}"
}

src_compile() {
	# Builds internal/web/ui/dist, which embedalloyui embeds in the binary
	# from the vendored copy of Alloy (see src_prepare).
	nodejs-mod_src_compile
	cp -r ${NODEJS_MOD_PREFIX}/dist collector/vendor/github.com/grafana/${PN}/${NODEJS_MOD_PREFIX}/ || die

	pushd collector >/dev/null || die
	ego build -trimpath -tags "${ALLOY_TAGS}" -ldflags "${ALLOY_LDFLAGS}" -o "${S}"/alloy .
	popd >/dev/null || die

	local shell
	for shell in bash fish zsh; do
		./alloy completion ${shell} > alloy.${shell} || die
	done
}

src_test() {
	# The upstream suite needs Docker and the network. Test how the collector
	# derives its version, and that the binary loads the configuration it
	# installs, with every component registered.
	pushd collector >/dev/null || die
	ego test -trimpath -tags "${ALLOY_TAGS}" .
	popd >/dev/null || die

	./alloy validate packaging/config.alloy || die
	./alloy --version | grep -F "v${PV}" || die
}

src_install() {
	dobin alloy
	einstalldocs

	newbashcomp alloy.bash alloy
	newfishcomp alloy.fish alloy.fish
	newzshcomp alloy.zsh _alloy

	insinto /etc/alloy
	doins packaging/config.alloy

	newinitd "${FILESDIR}"/${PN}.initd ${PN}
	newconfd "${FILESDIR}"/${PN}.confd ${PN}
	systemd_dounit "${FILESDIR}"/${PN}.service
	newtmpfiles "${FILESDIR}"/${PN}.tmpfiles.conf ${PN}.conf
}

pkg_postinst() {
	tmpfiles_process ${PN}.conf

	if [[ -z ${REPLACING_VERSIONS} ]]; then
		elog "beyla.ebpf does not work in this build: upstream embeds a prebuilt"
		elog "Beyla binary. ${CATEGORY}/${PN}-bin includes it, if it is needed."
	fi
}
