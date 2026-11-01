# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1

DESCRIPTION="AI coding assistant skill"
HOMEPAGE="https://github.com/safishamsi/graphify"
SRC_URI="https://github.com/safishamsi/${PN}/archive/v${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# No upper bound on dev-python/tree-sitter: upstream caps it below 0.26, but it
# only uses Language and Parser, and dev-util/pkgcheck requires >=0.26.
# Gentoo ships no Python bindings for the go, java, php and typescript grammars.
RDEPEND="
	dev-libs/tree-sitter-bash[python,${PYTHON_USEDEP}]
	dev-libs/tree-sitter-cpp[python,${PYTHON_USEDEP}]
	dev-libs/tree-sitter-json[python,${PYTHON_USEDEP}]
	dev-libs/tree-sitter-ruby[python,${PYTHON_USEDEP}]
	dev-libs/tree-sitter-c[python,${PYTHON_USEDEP}]
	dev-libs/tree-sitter-go
	dev-libs/tree-sitter-java
	dev-libs/tree-sitter-javascript[python,${PYTHON_USEDEP}]
	dev-libs/tree-sitter-python[python,${PYTHON_USEDEP}]
	dev-libs/tree-sitter-rust[python,${PYTHON_USEDEP}]
	dev-libs/tree-sitter-typescript
	>=dev-python/tree-sitter-0.25[${PYTHON_USEDEP}]
	dev-python/networkx[${PYTHON_USEDEP}]
	dev-python/numpy[${PYTHON_USEDEP}]
	dev-python/pyyaml[${PYTHON_USEDEP}]
	dev-python/rapidfuzz[${PYTHON_USEDEP}]
	dev-libs/tree-sitter-php
	dev-libs/tree-sitter-lua[python,${PYTHON_USEDEP}]
	dev-libs/tree-sitter-query
	dev-libs/tree-sitter-css
	dev-libs/tree-sitter-html
	dev-libs/tree-sitter-tsx
"
DEPEND="${RDEPEND}"
