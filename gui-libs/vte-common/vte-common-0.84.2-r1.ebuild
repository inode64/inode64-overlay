# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
PYTHON_COMPAT=( python3_{12..14} )
GNOME_ORG_MODULE="vte"

inherit flag-o-matic gnome.org meson python-any-r1

DESCRIPTION="Library providing a virtual terminal emulator widget"
HOMEPAGE="https://gitlab.gnome.org/GNOME/vte"
# 0.84.2 is only in the GitLab package registry, not on download.gnome.org
SRC_URI="https://gitlab.gnome.org/api/v4/projects/1893/packages/generic/vte/${PV}/vte-${PV}.tar.xz"

S="${WORKDIR}/vte-${PV}"

# Once SIXEL support ships (0.66 or later), might need xterm license (but code might be considered upgraded to LGPL-3+)
LICENSE="LGPL-3+ GPL-3+"

SLOT="2.91" # vte_api_version in meson.build

KEYWORDS="amd64 arm arm64 ~loong ppc ppc64 ~riscv ~sparc x86"

IUSE="systemd"

DEPEND="
	|| ( >=gui-libs/gtk-4.0.1:4 >=x11-libs/gtk+-3.24.22:3 )
	dev-cpp/fast_float
	>=x11-libs/pango-1.22.0
	>=dev-libs/libpcre2-10.21
	systemd? ( >=sys-apps/systemd-220:= )
	>=app-arch/lz4-1.9
"
BDEPEND="
	${PYTHON_DEPS}
	dev-libs/libxml2:2
	dev-util/glib-utils
	>=sys-devel/gettext-0.19.8
"

src_prepare() {
	default
	use elibc_musl && eapply "${FILESDIR}"/${PN}-0.84.0-musl-W_EXITCODE.patch
}

src_configure() {
	# Upstream don't support LTO & error out on it in meson.build (bug #926156)
	filter-lto

	local emesonargs=(
		-Da11y=false
		-Ddebug=false
		-Ddocs=false
		-Dgir=false
		-Dfribidi=true # pulled in by pango anyhow
		-Dglade=false
		-Dgnutls=false
		-Dgtk3=false
		-Dgtk4=false
		-Dicu=false
		$(meson_use systemd _systemd)
		-Dvapi=false
	)
	meson_src_configure
}

src_install() {
	exeinto /usr/libexec/
	doexe "${BUILD_DIR}"/src/vte-urlencode-cwd
	insinto /etc/profile.d/
	newins "${BUILD_DIR}"/src/vte.sh vte-${SLOT}.sh
	newins "${BUILD_DIR}"/src/vte.csh vte-${SLOT}.csh
	if  use systemd; then
		# ::gentoo installs it in .scode.d, which systemd never reads; the
		# vte ebuilds remove it from .scope.d, where meson puts it
		insinto /usr/lib/systemd/user/vte-spawn-.scope.d/
		newins "${S}"/src/vte-spawn-.scope.conf defaults.conf
	fi
	einstalldocs
}
