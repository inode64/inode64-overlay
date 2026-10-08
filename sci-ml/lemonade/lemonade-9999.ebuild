# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..15} )

inherit cmake desktop git-r3 python-any-r1 systemd

DESCRIPTION="Local AI server: optimized LLM inference on AMD NPU + GPU"
HOMEPAGE="
	https://lemonade-server.ai/
	https://github.com/lemonade-sdk/lemonade
"
EGIT_REPO_URI="https://github.com/lemonade-sdk/lemonade.git"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+system-fastflowlm +system-llamacpp +system-rocm tauri webui"

# Missing cpp-httplib pkg-config metadata or optional dependencies make
# upstream fall back to FetchContent downloads at configure time; webui and
# tauri fetch npm modules / Rust crates while building.
PROPERTIES="live"
RESTRICT="network-sandbox"

# Linux always links libdrm_amdgpu. brotli is macOS-only. Digest verification
# links mbedtls; only slot 0 matches the probe, otherwise a static copy is fetched.
RDEPEND="
	>=app-arch/zstd-1.5.5:=
	>=dev-cpp/cli11-2.4.2
	>=dev-cpp/cpp-httplib-0.26.0
	>=dev-cpp/nlohmann_json-3.11.3
	>=net-libs/libwebsockets-4.3.3
	>=net-misc/curl-8.5.0
	net-libs/mbedtls:0=
	sys-libs/libcap
	x11-libs/libdrm[video_cards_amdgpu]
	acct-group/lemonade
	acct-user/lemonade
	system-fastflowlm? ( sci-ml/fastflowlm )
	system-llamacpp? ( sci-misc/llama-cpp )
	system-rocm? ( dev-util/hip )
	webui? (
		app-misc/jq
		x11-misc/xdg-utils
	)
	tauri? (
		net-libs/libsoup:3.0
		net-libs/webkit-gtk:4.1
		x11-libs/gtk+:3
	)
"
DEPEND="${RDEPEND}"
BDEPEND="
	${PYTHON_DEPS}
	>=dev-build/cmake-3.12
	app-misc/jq
	virtual/pkgconfig
	webui? ( net-libs/nodejs[npm] )
	tauri? (
		net-libs/nodejs[npm]
		|| ( dev-lang/rust dev-lang/rust-bin )
	)
"

LEMONADE_MODELS_DIR="/var/lib/lemonade/models"

src_configure() {
	# BUILD_TAURI_APP builds during configure, before CMakeCache exists; build
	# its standalone target later and install it manually.
	# Upstream's resource lookup does not support /opt, so install to /usr.
	# BUILD_TESTING=OFF is upstream's distro-packaging path.
	local mycmakeargs=(
		-DCMAKE_INSTALL_PREFIX="/usr"
		-DBUILD_WEB_APP=$(usex webui ON OFF)
		-DBUILD_TAURI_APP=OFF
		-DBUILD_TESTING=OFF
	)
	cmake_src_configure
}

src_compile() {
	cmake_src_compile

	# This standalone target is not part of all.
	if use tauri; then
		cmake_src_compile tauri-app
	fi
}

src_install() {
	cmake_src_install

	# Do not ship the FetchContent dependency's private static archive.
	find "${ED}" -name 'libwebsockets.a' -delete || die

	# OpenRC service; upstream already installs the systemd units
	# (system + user lemond.service, sysusers.d, /etc/default/lemond).
	newinitd "${FILESDIR}/${PN}.initd" "${PN}"
	newconfd "${FILESDIR}/${PN}.confd" "${PN}"

	# Shared model store, group writable for manual launches by members of
	# the lemonade group; the services already run as the lemonade user.
	keepdir "${LEMONADE_MODELS_DIR}"
	fowners -R lemonade:lemonade /var/lib/lemonade
	fperms 2770 "${LEMONADE_MODELS_DIR}"

	# systemd drop-ins for both the system and the user unit.
	# flm (NPU backend) mlocks its buffers; upstream's unit only grants
	# CAP_SYS_RESOURCE, it does not raise the limit (the OpenRC init does).
	local -a dropins=( 10-memlock.conf )
	printf '[Service]\nLimitMEMLOCK=infinity\n' > "${T}/10-memlock.conf" || die
	if use system-fastflowlm; then
		# lemond spawns flm; point it at fastflowlm's shared model store.
		printf '[Service]\nEnvironment=FLM_MODEL_PATH=/var/lib/fastflowlm\n' \
			> "${T}/10-fastflowlm.conf" || die
		dropins+=( 10-fastflowlm.conf )
	fi

	# Point the services at the system ROCm instead of downloading TheRock.
	if use system-rocm; then
		sed -i -e 's|^#\?LEMONADE_ROCM_PATH=.*|LEMONADE_ROCM_PATH="/usr"|' \
			"${ED}/etc/conf.d/${PN}" || die
		printf '[Service]\nEnvironment=ROCM_PATH=/usr\n' \
			> "${T}/10-rocm-path.conf" || die
		dropins+=( 10-rocm-path.conf )
	fi

	local unitdir dropin
	for unitdir in "$(systemd_get_systemunitdir)" "$(systemd_get_userunitdir)"; do
		insinto "${unitdir#"${EPREFIX}"}/lemond.service.d"
		for dropin in "${dropins[@]}"; do
			doins "${T}/${dropin}"
		done
	done

	# Seed every new config with the shared model store instead of the
	# per-user HuggingFace cache, and route fetch-by-default backends to
	# packaged binaries (set both backend and its matching *_bin: "auto"
	# otherwise ignores the path). Guard each section so jq cannot create a
	# misplaced key.
	local -a jqf=( ".models_dir=\"${LEMONADE_MODELS_DIR}\"" ) sections=()
	if use system-llamacpp; then
		# Always route through the "vulkan" slot: it is the only one lemond
		# launches without its own runtime bookkeeping (the rocm slot wants a
		# backend_versions.json entry and TheRock). Which GPU backend actually
		# runs is decided by the binary: a ROCm-built llama-server runs ROCm.
		jqf+=( '.llamacpp.backend="vulkan" | .llamacpp.vulkan_bin="/usr/bin/llama-server"' )
		sections+=( llamacpp )
	fi
	if use system-fastflowlm; then
		# PATH is ignored without prefer_system; pin npu_bin to prevent a download.
		jqf+=( '.flm.npu_bin="/usr/bin/flm"' )
		sections+=( flm )
	fi
	# Patch the config seed (lemond merges /usr/share/lemonade/defaults.json
	# over its built-in defaults for every new config.json).
	local def="${ED}/usr/share/lemonade/defaults.json"
	local s
	for s in models_dir "${sections[@]}"; do
		jq -e "has(\"${s}\")" "${def}" >/dev/null \
			|| die "defaults.json has no '${s}' key; re-audit the pins"
	done
	local filter
	printf -v filter '%s | ' "${jqf[@]}"
	jq "${filter% | }" "${def}" > "${T}/defaults.json" || die
	mv "${T}/defaults.json" "${def}" || die

	if use tauri; then
		# Upstream's configure-time install rules are unusable; install manually.
		dobin "${BUILD_DIR}/app/lemonade-app"
		domenu "${S}/data/lemonade-app.desktop"
		newicon -s scalable "${S}/src/app/assets/logo.svg" lemonade-app.svg
	fi
}

pkg_postinst() {
	elog "lemond binds 127.0.0.1:13305 by default; expose it beyond localhost"
	elog "only behind API-key auth (LEMONADE_API_KEY) or a VPN/SSH tunnel."
	elog ""
	ewarn "Privacy: at startup lemond sends a UDP presence broadcast on LAN"
	ewarn "interfaces, even with the loopback bind. Disable it by setting"
	ewarn "broadcast to false in ~/.cache/lemonade/config.json."
	elog ""
	elog "Models are stored in the shared store ${LEMONADE_MODELS_DIR}"
	elog "(models_dir in every new config.json), owned by the lemonade user."
	elog "Add users that run lemond by hand to the lemonade group:"
	elog "  usermod -aG lemonade <user>"
	elog "Per-user state (config.json, downloaded backends) stays under"
	elog "~/.config/lemonade and ~/.cache/lemonade for manual launches;"
	elog "the services use /var/lib/lemonade and /var/cache/lemonade."
	elog ""
	elog "Quick start:"
	elog "  lemond                   # start the server"
	elog "  lemonade run <model>     # CLI client"
	elog "OpenRC (runs as the lemonade user, tunables in /etc/conf.d/lemonade):"
	elog "  rc-service lemonade start"
	elog "systemd (runs as the dedicated 'lemonade' user):"
	elog "  systemctl enable --now lemond          # system-wide, or"
	elog "  systemctl --user enable --now lemond   # per-user"
	elog "  host/port live in config.json; HF_TOKEN and LEMONADE_API_KEY"
	elog "  go in /etc/default/lemond"
	elog "  the system unit gets LimitMEMLOCK=infinity for the NPU backend; a"
	elog "  --user unit needs the same from /etc/security/limits.d"
	elog ""
	if use webui; then
		elog "Web UI: lemond serves the bundled React app at http://127.0.0.1:13305/"
		elog "and a 'lemonade-web-app' launcher opens it in your browser."
		elog ""
	fi
	if use tauri; then
		elog "Desktop app: 'lemonade-app' is a client for a running lemond."
		elog ""
	fi
	if use system-llamacpp; then
		elog "system-llamacpp: lemond reuses /usr/bin/llama-server (sci-misc/llama-cpp)"
		elog "through the 'vulkan' routing pinned in the shipped defaults; the GPU"
		elog "backend that actually runs is the one llama-cpp was built with."
		elog "An existing config is not touched; set it by hand:"
		elog "  lemonade config set llamacpp.backend=vulkan llamacpp.vulkan_bin=/usr/bin/llama-server"
		elog ""
	fi
	if use system-rocm; then
		elog "system-rocm: lemond is pointed at /usr (ROCM_PATH) by the OpenRC confd"
		elog "and a systemd drop-in, so its ROCm backends reuse the system ROCm"
		elog "instead of downloading AMD's ~3 GB TheRock runtime. For a manual"
		elog "launch: export ROCM_PATH=/usr"
		elog ""
	fi
	if use system-fastflowlm; then
		elog "system-fastflowlm: the shipped defaults pin flm.npu_bin=/usr/bin/flm."
		elog "An existing ~/.cache/lemonade/config.json is not touched; set it with:"
		elog "  lemonade config set flm.npu_bin=/usr/bin/flm"
		elog "Confirm 'flm validate' passes before lemonade drives the NPU."
	else
		ewarn "Without USE=system-fastflowlm, lemond downloads the FastFlowLM (flm)"
		ewarn "NPU runtime into ~/.cache/lemonade on first NPU use. A bare flm on"
		ewarn "PATH is not used unless flm.prefer_system is set."
	fi
}
