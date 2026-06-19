# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1

DESCRIPTION="AI coding assistant skill"
HOMEPAGE="https://github.com/safishamsi/graphify"
SRC_URI="https://github.com/safishamsi/${PN}/archive/v${PV}.tar.gz -> ${P}.gh.tar.gz"


LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-libs/tree-sitter-bash
	dev-libs/tree-sitter-cpp
	dev-libs/tree-sitter-json
	dev-libs/tree-sitter-ruby
	dev-libs/tree-sitter-c
	dev-libs/tree-sitter-go
	dev-libs/tree-sitter-java
	dev-libs/tree-sitter-javascript
	dev-libs/tree-sitter-python
	dev-libs/tree-sitter-rust
	dev-libs/tree-sitter-typescript
	dev-python/networkx[${PYTHON_USEDEP}]
	dev-python/numpy[${PYTHON_USEDEP}]
	dev-python/rapidfuzz[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}"
