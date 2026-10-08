# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake git-r3 systemd

DESCRIPTION="NPU-first LLM runtime for AMD Ryzen AI (XDNA2) processors"
HOMEPAGE="
	https://fastflowlm.com/
	https://github.com/ROCm/FastFlowLM
"
EGIT_REPO_URI="https://github.com/ROCm/FastFlowLM.git"
# tokenizers-cpp and its nested sentencepiece/msgpack submodules
EGIT_SUBMODULES=( '*' )

# The CLI is MIT. The bundled NPU kernels (src/lib/xrt/*.so, xclbins) are
# proprietary under upstream's TERMS.md: free use, commercially up to a
# revenue threshold, no redistribution grant, hence bindist.
LICENSE="MIT FastFlowLM-Terms"
SLOT="0"
KEYWORDS="~amd64"

# Cargo (inside tokenizers-cpp/rust) fetches crates at build time.
PROPERTIES="live"
RESTRICT="bindist network-sandbox"

BDEPEND="
	>=dev-build/cmake-3.22
	dev-build/ninja
	|| ( dev-lang/rust dev-lang/rust-bin )
"
RDEPEND="
	acct-group/fastflowlm
	acct-user/fastflowlm
	dev-libs/boost:=
	dev-libs/xdna-driver
	dev-libs/xrt-xdna
	dev-util/xrt
	media-video/ffmpeg:=
	net-misc/curl:=
	sci-libs/fftw:3.0=
	sys-libs/ncurses:=
	sys-libs/readline:=
"
# xrt-2.21.75-r1 is the first to install aiebu's headers and static library.
DEPEND="
	${RDEPEND}
	>=dev-util/xrt-2.21.75-r1
"

CMAKE_USE_DIR="${S}/src"
FLM_STATE_DIR="/var/lib/fastflowlm"

src_prepare() {
	# Link XRT's aiebu (/usr/include/aiebu, libaiebu.a) instead of the
	# prebuilt copy upstream ships; flm only calls aiebu_assembler_get_elf().
	rm "${S}"/src/lib/xrt/{libaiebu.a,aiebu_static.lib} || die
	rm -r "${S}"/src/include/aiebu || die
	cmake_src_prepare
}

src_configure() {
	# FLM_VERSION and NPU_VERSION are mandatory preset-only values.
	# CMAKE_XCLBIN_PREFIX must match the install path or the runtime searches
	# beside the executable. FLM_USE_HRX=OFF keeps the XRT backend.
	local mycmakeargs=(
		-DCMAKE_INSTALL_PREFIX="/opt/fastflowlm"
		-DCMAKE_XCLBIN_PREFIX="/opt/fastflowlm/share/flm"
		-DFLM_VERSION="${PV}"
		-DNPU_VERSION="32.0.203.304"
		-DFLM_USE_HRX=OFF
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install

	local flm_libdir="/opt/fastflowlm/$(get_libdir)"

	# Expose the bundled NPU libraries at runtime and default to the shared
	# model store instead of ~/.config/flm.
	newbin - flm <<-EOF
	#!/usr/bin/env bash
	set -euo pipefail
	export LD_LIBRARY_PATH="${flm_libdir}\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}"
	export FLM_CONFIG_PATH="\${FLM_CONFIG_PATH:-/opt/fastflowlm/share/flm/model_list.json}"
	export FLM_MODEL_PATH="\${FLM_MODEL_PATH:-${FLM_STATE_DIR}}"
	exec /opt/fastflowlm/bin/flm "\$@"
	EOF

	newenvd - 99fastflowlm <<-EOF
	LDPATH="${flm_libdir}"
	FLM_CONFIG_PATH="/opt/fastflowlm/share/flm/model_list.json"
	FLM_MODEL_PATH="${FLM_STATE_DIR}"
	EOF

	# Shared model store: owned by the service user, group writable so other
	# members of the fastflowlm group (e.g. lemonade) can pull models too.
	keepdir "${FLM_STATE_DIR}/models"
	fowners -R fastflowlm:fastflowlm "${FLM_STATE_DIR}"
	fperms 2770 "${FLM_STATE_DIR}" "${FLM_STATE_DIR}/models"

	newinitd "${FILESDIR}/${PN}.initd" "${PN}"
	newconfd "${FILESDIR}/${PN}.confd" "${PN}"
	systemd_dounit "${FILESDIR}/${PN}.service"
}

pkg_postinst() {
	elog "FastFlowLM installed to /opt/fastflowlm, wrapper in /usr/bin/flm."
	elog ""
	elog "Models are stored in the shared store ${FLM_STATE_DIR}/models"
	elog "(FLM_MODEL_PATH, set by the wrapper, env.d and both services), owned"
	elog "by the fastflowlm user. Add users that run flm interactively to the"
	elog "fastflowlm group so they can pull models there:"
	elog "  usermod -aG fastflowlm <user>"
	elog ""
	elog "Quick start:"
	elog "  flm validate          # verify the NPU stack"
	elog "  flm pull qwen3:0.6b   # download a model"
	elog "  flm run qwen3:0.6b    # chat with it"
	elog "OpenRC:  rc-service fastflowlm start   (tunables in /etc/conf.d/fastflowlm)"
	elog "systemd: systemctl enable --now fastflowlm.service"
	elog "         (overrides in /etc/default/fastflowlm)"
	elog ""
	elog "flm mlocks NPU buffers: the services set memlock unlimited; interactive"
	elog "use needs it too, e.g. in /etc/security/limits.d/99-amdxdna.conf:"
	elog "  *  soft  memlock  unlimited"
	elog "  *  hard  memlock  unlimited"
}
