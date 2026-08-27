# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DUNE_PKG_NAME="aliengrep ast_generic collections commons2 commons fast_json
	gitignore git_wrapper glob language_server lib_parsing
	lib_parsing_tree_sitter lwt_platform murmur3 networking
	ograph ojsonnet parallelism parser_bash parser_cairo parser_circom
	parser_cpp parser_csharp parser_dart parser_dockerfile parser_fga
	parser_go parser_hack parser_html parser_java parser_javascript
	parser_jsonnet parser_json parser_julia parser_kotlin parser_lisp
	parser_lua parser_move_on_aptos parser_move_on_sui parser_ocaml
	parser_php parser_promql parser_protobuf parser_python parser_ql
	parser_regexp parser_r parser_ruby parser_rust parser_scala
	parser_solidity parser_swift parser_terraform parser_typescript
	parser_yaml paths pfff-lang_GENERIC-analyze pfff-lang_GENERIC-naming
	process_limits semgrep spacegrep telemetry tree-sitter-lang"

inherit dune edo

declare -a LANG
LANG=(
	bash="c9a4e36f11b202061eb219a309580b903266c47c"
	cairo="a8e2d5d5dcf8345735b15268b76b24377103a188"
	circom="4e1e82bad56bccfe63e12cedd830b768789e239d"
	clojure="f56ba7e347cb078a40551a5b2657b1351d086922"
	cpp="9186c38ddf4d16113209e344f1e5de3d1b30be83"
	c-sharp="a20746f8fa5c155453f91d58d5bf3b736d1fbdb4"
	dart="340d33b7427a0799b897341e129b84876dcb3f72"
	dockerfile="88b70c9520964c696f1c833b8e8fb9645d4233d6"
	fga="05a4b6c58299a290ad11af178568490af63f1d37"
	go="d2e55851fea0f5bd6705198e6282994d5bba4803"
	hack="401a92b1ef61e526bad118f3c97119c714384519"
	hcl="51c3c26af2b5e23d879fbefa61639254140adc0a"
	html="2bde56bff950da7984ae729c656e10c05ede3ddf"
	java="75161f747b9342254c7a132bb0ca7458618cd0a7"
	jsonnet="90e1fbc65e25e1dbef85776777adb3cd53184ec5"
	julia="3dabca267d6565b1a5f50db3f654e5f837a8ea29"
	kotlin="1bddb22061147533add5a66bfe8530254ae81675"
	lua="49a7ed0d0c4859cc91ad0c43b0cf92d7448d007e"
	move-on-aptos="667944faf4c1d81299cc34e4f09f5ab34330df09"
	move-on-sui="4fe01c06c24ada6a9b0a99d49cc488964fa11046"
	ocaml="62466992084e2b75c048ded706e3a9119f9ded2c"
	php="507f87c239d00f0dc501cd4c9105fb35aee4c10b"
	promql="3436085e1638264516ce75c484adf45fc96382d1"
	proto="6754f93b8c89e9e62b48821081300460648f534f"
	python="7b87bb41e7ee884f38af2107182f1d96b9ba31d6"
	ql="55749f3c2124dfe1661453ab0790042035a16d41"
	r="d8576644f8c813ea1ec4403866f661861e43969a"
	ruby="1167a189089c219496149e3823e8f5000141d3e7"
	rust="64fe5d06dfafad9c2a9764524db036cd31820e3c"
	scala="b89a80db4bb076e74f9059eb67f5af7d6195b32d"
	solidity="e7aa37f9421a15b04f42676be7489a27ee455f0d"
	swift="f62f0c1dffa87b84dd1513374687513e6e091de1"
	tsx="6005de74ed9e2fb891785a3df8582dbb91e272bc"
	typescript="50fe6a5c46d3dee74d1d176b9767ffc520a1003e"
)
MY_PN="${PN/-core/}"

DESCRIPTION="Code scanning at ludicrous speed"
HOMEPAGE="https://github.com/semgrep/semgrep"
SRC_URI="https://github.com/${MY_PN}/${MY_PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${MY_PN}-${PV}"

for lang in "${!LANG[@]}" ; do
	SRC_URI+="
		https://github.com/semgrep/semgrep-${LANG[$lang]%=*}/archive/${LANG[$lang]#*=}.tar.gz
			-> ${P}-${LANG[$lang]%=*}.tar.gz"
done

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64"
IUSE="ocamlopt test"
RESTRICT="test"
PROPERTIES="test_network"

RDEPEND=">=dev-lang/ocaml-5.3.0:0=[flambda,ocamlopt?]
	dev-libs/libev:=
	dev-libs/libpcre2:=
	dev-ml/ANSITerminal:=[ocamlopt?]
	>=dev-ml/alcotest-1.9.0:0=[ocamlopt?]
	dev-ml/alcotest-lwt:0=[ocamlopt?]
	>=dev-ml/ambient-context-0.2:0=[ocamlopt?]
	>=dev-ml/atd-4.2.0:0=[ocamlopt?]
	>=dev-ml/base-0.17.3:0=[ocamlopt?]
	dev-ml/bos:0=
	>=dev-ml/calendar-3.0.0:0=[ocamlopt?]
	dev-ml/cmdliner:0=[ocamlopt?]
	dev-ml/cohttp:0=[ocamlopt?]
	dev-ml/digestif:0=[ocamlopt?]
	dev-ml/eio:0=[ocamlopt?]
	dev-ml/emile:0=[ocamlopt?]
	dev-ml/fmt:0=[ocamlopt?]
	dev-ml/fpath:0=
	dev-ml/git:0=[ocamlopt?]
	dev-ml/jsonrpc:0=[ocamlopt?]
	dev-ml/logs:0=[ocamlopt?]
	dev-ml/lwt:0=[ocamlopt?]
	dev-ml/lsp:0=[ocamlopt?]
	dev-ml/menhir:=[ocamlopt?]
	dev-ml/memtrace:=
	dev-ml/obackward:0=[ocamlopt?]
	dev-ml/ocaml-fileutils:=[ocamlopt?]
	dev-ml/ocamlgraph:0=[ocamlopt?]
	dev-ml/ocolor:0=[ocamlopt?]
	dev-ml/ocurl:0=[ocamlopt?]
	~dev-ml/opentelemetry-0.13:0=[ocamlopt?]
	dev-ml/parmap:0=[ocamlopt?]
	dev-ml/pcre-ocaml:0=[ocamlopt?]
	dev-ml/pcre2-ocaml:0=[ocamlopt?]
	~dev-ml/ppxlib-0.35.0:0=[ocamlopt?]
	dev-ml/ppx_blob:=[ocamlopt?]
	~dev-ml/ppx_deriving-6.0.3:0=[ocamlopt?]
	~dev-ml/ppx_deriving_yojson-3.9.0:0=[ocamlopt?]
	>=dev-ml/ppx_hash-0.17.0:0=[ocamlopt?]
	~dev-ml/ppx_inline_test-0.17.0:0=[ocamlopt?]
	~dev-ml/ppx_sexp_conv-0.17.0:0=[ocamlopt?]
	dev-ml/pyro-caml:0=[ocamlopt?]
	dev-ml/python-str-repr:0=[ocamlopt?]
	dev-ml/re:0=[ocamlopt?]
	dev-ml/sarif:0=[ocamlopt?]
	dev-ml/semver:0=[ocamlopt?]
	dev-ml/terminal_size:0=[ocamlopt?]
	dev-ml/testo:0=[ocamlopt?]
	dev-ml/timedesc:0=[ocamlopt?]
	dev-ml/tls:0=[ocamlopt?]
	dev-ml/tree-sitter:0=[ocamlopt?]
	~dev-ml/uri-4.4.0:0=[ocamlopt?]
	dev-ml/uring:0=[ocamlopt?]
	>=dev-ml/uuidm-0.9.10:0=[ocamlopt?]
	>=dev-ml/uucp-17.0.0:0=
	dev-ml/uutf:0=[ocamlopt?]
	dev-ml/visitors-cleanroom:0=[ocamlopt?]
	dev-ml/xmlm:0=
	dev-ml/yaml:0=[ocamlopt?]
	dev-ml/yojson:0=[ocamlopt?]
	net-misc/curl"
BDEPEND="test? ( dev-ml/qcheck
		dev-ml/py
		dev-vcs/git )"

PATCHES=( "${FILESDIR}/${PN}"-1.163.0-ambient-context-0.2.patch )

src_prepare() {
	default

	for lang in "${!LANG[@]}" ; do
		case "${LANG[$lang]%=*}" in
			c-sharp)
				edo rmdir languages/csharp/tree-sitter/semgrep-c-sharp
				edo ln -s ../../../../semgrep-c-sharp-"${LANG[$lang]#*=}" \
					languages/csharp/tree-sitter/semgrep-"${LANG[$lang]%=*}"
				;;
			clojure)
				edo rmdir languages/lisp/tree-sitter/semgrep-clojure
				edo ln -s ../../../../semgrep-clojure-"${LANG[$lang]#*=}" \
					languages/lisp/tree-sitter/semgrep-"${LANG[$lang]%=*}"
				;;
			hcl)
				edo rmdir languages/terraform/tree-sitter/semgrep-hcl
				edo ln -s ../../../../semgrep-hcl-"${LANG[$lang]#*=}" \
					languages/terraform/tree-sitter/semgrep-"${LANG[$lang]%=*}"
				;;
			move-on-aptos)
				edo rmdir languages/move_on_aptos/tree-sitter/semgrep-move-on-aptos
				edo ln -s ../../../../semgrep-move-on-aptos-"${LANG[$lang]#*=}" \
					languages/move_on_aptos/tree-sitter/semgrep-"${LANG[$lang]%=*}"
				;;
			move-on-sui)
				edo rmdir languages/move_on_sui/tree-sitter/semgrep-move-on-sui
				edo ln -s ../../../../semgrep-move-on-sui-"${LANG[$lang]#*=}" \
					languages/move_on_sui/tree-sitter/semgrep-"${LANG[$lang]%=*}"
				;;
			proto)
				edo rmdir languages/protobuf/tree-sitter/semgrep-proto
				edo ln -s ../../../../semgrep-proto-"${LANG[$lang]#*=}" \
					languages/protobuf/tree-sitter/semgrep-"${LANG[$lang]%=*}"
				;;
			tsx)
				edo rmdir languages/typescript/tree-sitter/semgrep-tsx
				edo ln -s ../../../../semgrep-tsx-"${LANG[$lang]#*=}" \
					languages/typescript/tree-sitter/semgrep-"${LANG[$lang]%=*}"
				;;
			*)
				edo rmdir languages/"${LANG[$lang]%=*}"/tree-sitter/semgrep-"${LANG[$lang]%=*}"
				edo ln -s ../../../../semgrep-"${LANG[$lang]%=*}"-"${LANG[$lang]#*=}" \
					languages/"${LANG[$lang]%=*}"/tree-sitter/semgrep-"${LANG[$lang]%=*}"
				;;
		esac
	done

	# don't look for linker flags from opam
	sed -i 's/opam/echo/g' src/main/flags.sh || die "sed failed for flags.sh"
	# allow empty package
	sed -i '/(name language_server)/a\ (allow_empty)' dune-project \
		|| die "sed failed for dune-project"
	# remove non-existed library
	sed -i '/opentelemetry.ambient-context.eio/d' libs/telemetry/dune \
		|| die "sed failed for dune"
	# https://github.com/mjambon/testo/issues/172
	sed -i 's/broken/flaky/g' src/osemgrep/tests/Test_osemgrep.ml \
		src/osemgrep/networking/tests/Unit_Fetching.ml \
		|| die "sed failed for testo"
	# change expected OCaml version
	sed -i '/let expected_prefix/s|+semgrep-fork||' src/core/Test_compiler_version.ml \
		|| die "sed failed for Test_compiler_version.ml"

	if use test ; then
		edo git init > /dev/null
		edo git config user.email "you@example.com"
		edo git config user.name "Your Name"
	fi
}

src_compile() {
	dune-compile profiling ${DUNE_PKG_NAME}

	if use test ; then
		edo scripts/make-symlinks
		emake build-core-test
	fi
}

src_test() {
	edo scripts/run-core-test
}
