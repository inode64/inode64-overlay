# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="The General Purpose Raw (GPR) tools for gopro"
HOMEPAGE="https://github.com/gopro/gpr"

if [[ ${PV} == *9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/gopro/gpr.git"
	case ${PV} in
		2.*) EGIT_BRANCH="stable-2.0";;
	esac
else
	MY_P=${P/_/-}
	S="${WORKDIR}/${MY_P}"
	SRC_URI="https://github.com/gopro/gpr/releases/${MY_P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

LICENSE="Apache-2.0"
SLOT="0"

src_install() {
	dobin "${BUILD_DIR}"/source/app/gpr_tools/gpr_tools
	dodoc README.md
}
