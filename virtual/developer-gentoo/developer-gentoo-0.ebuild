# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Tools needed for developing applications in php"
SLOT="${PV}"
KEYWORDS="~amd64"

RDEPEND="
		|| ( dev-util/phpstorm dev-util/pycharm-community dev-util/pycharm-professional app-editors/vscode )
		app-portage/eix
		app-portage/portage-utils
		dev-util/pkgdev
		dev-util/shellcheck-bin
		dev-vcs/git
"
