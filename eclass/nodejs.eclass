# Copyright 2019-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: nodejs.eclass
# @MAINTAINER:
# Fco. Javier Félix <web@inode64.com>
# @AUTHOR:
# Fco. Javier Félix <web@inode64.com>
# @SUPPORTED_EAPIS: 7 8
# @BLURB: An eclass for build NodeJS projects
# @DESCRIPTION:
# An eclass providing functions to build NodeJS projects
#
# Changelog:
#   Initial version from:
#       https://github.com/gentoo/gentoo/pull/930/files
#       https://github.com/gentoo-mirror/ssnb/blob/master/eclass/npm.eclass
#       https://github.com/gentoo-mirror/lanodanOverlay/blob/master/eclass/nodejs.eclass
#       https://github.com/Tatsh/tatsh-overlay/blob/master/eclass/yarn.eclass

#
# Build package for node_modules
#   npm install --audit false --color false --foreground-scripts --progress false --verbose --ignore-scripts
#   or in yarn
#   yarn install --color false --foreground-scripts --progress false --verbose --ignore-scripts
#   tar --create --auto-compress --file foo-1-node_modules.tar.xz node_modules/

case ${EAPI} in
7 | 8) ;;
*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ -z ${_NODEJS_ECLASS} ]]; then
_NODEJS_ECLASS=1

EXPORT_FUNCTIONS src_compile src_install src_prepare src_test

# @ECLASS_VARIABLE: NODEJS_MANAGEMENT
# @PRE_INHERIT
# @DEFAULT_UNSET
# @DESCRIPTION:
# Specify a package management
# The default is set to "npm".
: "${NODEJS_MANAGEMENT:=npm}"

# @ECLASS_VARIABLE: NODEJS_FILES
# @INTERNAL
# @DESCRIPTION:
# Files and directories that usually come in a standard NodeJS/npm module.
NODEJS_FILES="babel.config.js babel.config.json cli.js dist index.js lib node_modules package.json"

# @ECLASS_VARIABLE: NODEJS_DOCS
# @DESCRIPTION:
# Document files that come in a NodeJS/npm module, outside the usual docs
# list of README*, ChangeLog AUTHORS* etc. These are only installed if 'doc' is
# in ${USE}
# NODEJS_DOCS="README* LICENSE HISTORY*"

# @ECLASS_VARIABLE: NODEJS_EXTRA_FILES
# @DESCRIPTION:
# If additional dist files are present in the NodeJS/npm module that are not
# listed in NODEJS_FILES, then this is the place to put them in.
# Can be either files, or directories.
# Example: NODEJS_EXTRA_FILES="rigger.js modules"

case ${NODEJS_MANAGEMENT} in
npm)
    BDEPEND+=" net-libs/nodejs[npm]"
    ;;
yarn)
    BDEPEND+=" sys-apps/yarn"
    ;;
*)
    eerror "Unknown value for \${NODEJS_MANAGEMENT}"
    die "Value ${NODEJS_MANAGEMENT} is not supported"
    ;;
esac

RDEPEND+=" net-libs/nodejs"
BDEPEND+=" app-misc/jq"

# @FUNCTION: nodejs_version
# @DESCRIPTION:
# Return the package version
nodejs_version() {
    node -p "require('./package.json').version"
}

# @FUNCTION: nodejs_package
# @DESCRIPTION:
# Return de package name
nodejs_package() {
    node -p "require('./package.json').name"
}

# @FUNCTION: _NODEJS_MODULES
# @DESCRIPTION:
# Location where to install nodejs
_NODEJS_MODULES() {
    # shellcheck disable=SC2046
    echo /usr/$(get_libdir)/node_modules/$(nodejs_package)
}
# @FUNCTION: nodejs_has_package
# @DESCRIPTION:
# Return true (0) if is a package
nodejs_has_package() {
    [[ -d "${S}"/package ]] || return 1
}

# @FUNCTION: enpm
# @DESCRIPTION:
# Packet manager execution wrapper
enpm() {
    debug-print-function "${FUNCNAME}" "${@}"

    local mynpmflags_local mynpmflagstype npmflags

    # Make the array a local variable since <=portage-2.1.6.x does not support
    # global arrays (see bug #297255). But first make sure it is initialised.
    [[ -z ${mynpmflags} ]] && declare -a mynpmflags=()
    mynpmflagstype=$(declare -p mynpmflags 2>&-)
    if [[ "${mynpmflagstype}" != "declare -a mynpmflags="* ]]; then
	die "mynpmflags must be declared as array"
    fi

    mynpmflags_local=("${mynpmflags[@]}")

    npmflags=(
	--color false
	--foreground-scripts
	--offline
	--progress false
	--verbose
	"${mynpmflags_local[@]}"
    )

    case ${NODEJS_MANAGEMENT} in
    npm)
	npmflags+=( "--audit false" )
	npm "${npmflags[@]}" "$@"
	;;
    yarn)
	yarn "${npmflags[@]}" "$@"
	;;
    esac
}

# @FUNCTION: enpm_clean
# @DESCRIPTION:
# Delete all unnecessary files
enpm_clean() {
    debug-print-function "${FUNCNAME}" "${@}"

    einfo "Clean files"
    case ${NODEJS_MANAGEMENT} in
    npm)
	enpm prune --omit=dev || die
	;;
    yarn)
	enpm install --production || die
	;;
    esac

    pushd "${S}/node_modules" >/dev/null || die

    # Cleanups

    # Remove license files
    # shellcheck disable=SC2185
    find -type f -iregex '.*/\(...-\)?license\(-...\)?\(\.\(md\|rtf\|txt\|markdown\)\)?$' -delete || die

    # Remove documentation files
    # shellcheck disable=SC2185
    find -type f -iregex '.*/*.\.\(md\|txt\)$' -delete || die
    # shellcheck disable=SC2185
    find -type f -iregex '.*/\(readme\(.*\)?\|changelog\|roadmap\|security\|release\|contributors\|todo\|authors\)$' -delete || die

    # Remove typscript files
    # shellcheck disable=SC2185
    find -type f -iregex '.*\.\(tsx?\|jsx\|map\)$' -delete || die
    # shellcheck disable=SC2185
    find -type f -name tsconfig.json -delete || die

    # Remove misc files
    # shellcheck disable=SC2185
    find -type f -iname '*.musl.node' -delete || die
    # shellcheck disable=SC2185
    find -type f -iregex '.*\.\(editorconfig\|bak\|npmignore\|exe\|gitattributes\|ps1\|ds_store\|log\|pyc\)$' -delete || die
    # shellcheck disable=SC2185
    find -type f -iregex '.*\.\(travis.yml\|makefile\|jshintrc\|flake8\|mk\)$' -delete || die
    # shellcheck disable=SC2185
    find -type f -iname makefile -delete || die
    # shellcheck disable=SC2185
    find -type f -name '*\~' -delete || die

    # shellcheck disable=SC2185
    find -type d \
	\( \
	-iwholename '*.github' -o \
	-iwholename '*.tscache' -o \
	-iwholename '*/man' -o \
	-iwholename '*/test' -o \
	-iwholename '*/scripts' -o \
	-iwholename '*/git-hooks' -o \
	-iwholename '*/prebuilds' -o \
	-iwholename '*/android-arm' -o \
	-iwholename '*/android-arm64' -o \
	-iwholename '*/linux-arm64' -o \
	-iwholename '*/linux-armvy' -o \
	-iwholename '*/linux-armv7' -o \
	-iwholename '*/linux-arm' -o \
	-iwholename '*/win32-ia32' -o \
	-iwholename '*/win32-x64' -o \
	-iwholename '*/darwin-x64' \
	-iwholename '*/darwin-x64+arm64' \
	\) \
	-exec rm -rvf {} +

    popd >/dev/null || die
}

# @FUNCTION: enpm_install
# @DESCRIPTION:
# Install the files and folders necessary for the execution of nodejs
enpm_install() {
    debug-print-function "${FUNCNAME}" "${@}"

    local nodejs_files

    if nodejs_has_package; then
	einfo "Install pack files"
	enpm --prefix "${ED}"/usr \
	    install \
	    "$(nodejs_package)-$(nodejs_version).tgz" || die "install failed"
    fi

    nodejs_files="${NODEJS_FILES} ${NODEJS_EXTRA_FILES} $(nodejs_package).js"

    dodir "$(_NODEJS_MODULES)" || die "Could not create DEST folder"

    for f in ${nodejs_files}; do
	if [[ -e "${S}/${f}" ]]; then
	    cp -r "${S}/${f}" "${ED}/$(_NODEJS_MODULES)"
	fi
    done
}

# @FUNCTION: nodejs_src_prepare
# @DESCRIPTION:
# Nodejs preparation phase
nodejs_src_prepare() {
    debug-print-function "${FUNCNAME}" "${@}"

    if [[ ! -e package.json ]]; then
	eerror "Unable to locate package.json"
	eerror "Consider not inheriting the nodejs eclass."
	die "FATAL: Unable to find package.json"
    fi

    default_src_prepare
}

# @FUNCTION: nodejs_src_compile
# @DESCRIPTION:
# General function for compiling a nodejs module
nodejs_src_compile() {
    debug-print-function "${FUNCNAME}" "${@}"

    if nodejs_has_package; then
	einfo "Create pack file"
	enpm pack || die "pack failed"
    fi

    if jq -e '.scripts | has("build")' <package.json >/dev/null; then
	einfo "Run build"
	npm run build || die "build failed"
    fi

    if [[ -d node_modules ]]; then
	einfo "Compile native addon modules"
	find node_modules/ -name binding.gyp -exec dirname {} \; | while read -r dir; do
	    pushd "${dir}" >/dev/null || die
	    # shellcheck disable=SC2046
	    npm_config_nodedir=/usr/ /usr/$(get_libdir)/node_modules/npm/bin/node-gyp-bin/node-gyp rebuild --verbose
	    popd >/dev/null || die
	done
    fi
}

# @FUNCTION: nodejs_src_test
# @DESCRIPTION:
# General function for testing a nodejs module
nodejs_src_test() {
    debug-print-function "${FUNCNAME}" "${@}"

    if ! nodejs_has_package && jq -e '.scripts | has("test")' <package.json >/dev/null; then
	npm run test || die "test failed"
    else
	die 'No "test" command defined in package.json'
    fi
}

# @FUNCTION: nodejs_src_install
# @DESCRIPTION:
# Function for installing the package
nodejs_src_install() {
    debug-print-function "${FUNCNAME}" "${@}"

    # shellcheck disable=SC2035
    dodoc *.md "${NODEJS_DOCS}" || die "failed to install documentation"

    enpm_clean
    enpm_install
}
fi
