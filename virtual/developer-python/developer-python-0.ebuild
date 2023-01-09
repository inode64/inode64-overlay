# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"

DESCRIPTION="Tools needed for developing in gentoo"
SLOT="${PV}"
KEYWORDS="~amd64"

RDEPEND="
		|| ( dev-util/pycharm-community dev-util/pycharm-professional app-editors/vscode )
		dev-python/flake8
		dev-python/pip
"
