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

inherit dune edo git-r3

DESCRIPTION="Code scanning at ludicrous speed"
HOMEPAGE="https://github.com/semgrep/semgrep"
EGIT_REPO_URI="https://github.com/semgrep/semgrep.git"

LICENSE="LGPL-2.1"
SLOT="0"
IUSE="ocamlopt test"
RESTRICT="test"
PROPERTIES="test_network"

RDEPEND=">=dev-lang/ocaml-5.3.0:0=[flambda,ocamlopt?]
	dev-libs/libev:=
	dev-libs/libpcre2:=
	dev-ml/ANSITerminal:=[ocamlopt?]
	dev-ml/alcotest:0=[ocamlopt?]
	dev-ml/alcotest-lwt:0=[ocamlopt?]
	dev-ml/ambient-context:0=[ocamlopt?]
	dev-ml/atd:0=[ocamlopt?]
	dev-ml/base:0=[ocamlopt?]
	dev-ml/bos:0=
	dev-ml/calendar:0=[ocamlopt?]
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
	dev-ml/opentelemetry:0=[ocamlopt?]
	dev-ml/parmap:0=[ocamlopt?]
	dev-ml/pcre-ocaml:0=[ocamlopt?]
	dev-ml/pcre2-ocaml:0=[ocamlopt?]
	~dev-ml/ppxlib-0.35.0:0=[ocamlopt?]
	dev-ml/ppx_blob:=[ocamlopt?]
	dev-ml/ppx_deriving:0=[ocamlopt?]
	dev-ml/ppx_deriving_yojson:0=[ocamlopt?]
	dev-ml/ppx_hash:0=[ocamlopt?]
	dev-ml/ppx_inline_test:0=[ocamlopt?]
	dev-ml/ppx_sexp_conv:0=[ocamlopt?]
	dev-ml/pyro-caml:0=[ocamlopt?]
	dev-ml/python-str-repr:0=[ocamlopt?]
	dev-ml/re:0=[ocamlopt?]
	dev-ml/sarif:0=[ocamlopt?]
	dev-ml/semver:0=[ocamlopt?]
	dev-ml/ppx_sexp_conv:0=[ocamlopt?]
	dev-ml/terminal_size:0=[ocamlopt?]
	dev-ml/testo:0=[ocamlopt?]
	dev-ml/timedesc:0=[ocamlopt?]
	dev-ml/tls:0=[ocamlopt?]
	dev-ml/tree-sitter:0=[ocamlopt?]
	dev-ml/uri:0=[ocamlopt?]
	dev-ml/uring:0=[ocamlopt?]
	>=dev-ml/uuidm-0.9.10:0=[ocamlopt?]
	dev-ml/uucp:0=
	dev-ml/uutf:0=[ocamlopt?]
	dev-ml/visitors-cleanroom:0=[ocamlopt?]
	dev-ml/xmlm:0=
	dev-ml/yaml:0=[ocamlopt?]
	dev-ml/yojson:0=[ocamlopt?]
	net-misc/curl"
BDEPEND="test? ( dev-ml/qcheck
		dev-ml/py )"

PATCHES=( "${FILESDIR}/${PN}"-1.163.0-ambient-context-0.2.patch )

src_prepare() {
	default

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
