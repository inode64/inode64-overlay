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
: ${NODEJS_MANAGEMENT:=npm}

# @ECLASS-VARIABLE: NODEJS_FILES
# @INTERNAL
# @DESCRIPTION:
# Files and directories that usually come in a standard NodeJS/npm module.
NODEJS_FILES="babel.config.js babel.config.json cli.js dist index.js lib node_modules package.json"

# @ECLASS-VARIABLE: NODEJS_DOCS
# @DESCRIPTION:
# Document files that come in a NodeJS/npm module, outside the usual docs
# list of README*, ChangeLog AUTHORS* etc. These are only installed if 'doc' is
# in ${USE}
# NODEJS_DOCS="README* LICENSE HISTORY*"

# @ECLASS-VARIABLE: NODEJS_EXTRA_FILES
# @DESCRIPTION:
# If additional dist files are present in the NodeJS/npm module that are not
# listed in NODEJS_FILES, then this is the place to put them in.
# Can be either files, or directories.
# Example: NODEJS_EXTRA_FILES="rigger.js modules"

nodejs_version() {
    node -p "require('./package.json').version"
}
nodejs_package() {
    node -p "require('./package.json').name"
}
# @ECLASS_VARIABLE: _NODEJS_MODULES
# @DEPRECATED: none
# @DESCRIPTION:
# Location of modules to install
_NODEJS_MODULES() {
    echo /usr/$(get_libdir)/node_modules/$(nodejs_package)
}

nodejs_has_package() {
    [[ -d "${S}"/package ]] || return 1
}

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

IUSE+=" test"
RESTRICT+=" !test? ( test )"
RDEPEND+=" net-libs/nodejs"
BDEPEND+="
test? ( app-misc/jq )
"

enpm() {
    debug-print-function ${FUNCNAME} "$@"

    # Make the array a local variable since <=portage-2.1.6.x does not support
    # global arrays (see bug #297255). But first make sure it is initialised.
    [[ -z ${mynpmflags} ]] && declare -a mynpmflags=()
    local mynpmflagstype=$(declare -p mynpmflags 2>&-)
    if [[ "${mynpmflagstype}" != "declare -a mynpmflags="* ]]; then
        die "mynpmflags must be declared as array"
    fi

    local mynpmflags_local=("${mynpmflags[@]}")

    local npmflags=(
        --audit false
        --color false
        --foreground-scripts
        --offline
        --progress false
        --verbose
        "${mynpmflags_local[@]}"
    )

    case ${NODEJS_MANAGEMENT} in
    npm)
        npm "${npmflags[@]}" "$@"
        ;;
    yarn)
        yarn "${npmflags[@]}" "$@"
        ;;
    esac
}

enpm_clean() {
    debug-print-function ${FUNCNAME} "$@"

    einfo "Clean files"

    enpm prune --omit=dev || die

    pushd node_modules >/dev/null

    # Cleanups

    # Remove license files
    find -type f -iregex '.*/\(...-\)?license\(-...\)?\(\.\(md\|rtf\|txt\|markdown\)\)?$' -delete || die

    # Remove documentation files
    find -type f -iregex '.*/*.\.\(md\|txt\)$' -delete || die
    find -type f -iregex '.*/\(readme\(.*\)?\|changelog\|roadmap\|security\|release\|contributors\|todo\|authors\)$' -delete || die

    # Remove typscript files
    find -type f -iregex '.*\.\(tsx?\|jsx\|map\)$' -delete || die

    # Remove misc files
    find -type f -iname "*.musl.node" -delete || die
    find -type f -iregex '.*\.\(editorconfig\|bak\|npmignore\|exe\|gitattributes\|ps1\|ds_store\|log\|pyc\)$' -delete || die
    find -type f -iregex '.*\.\(travis.yml\|makefile\|jshintrc\|flake8\|mk\)$' -delete || die
    find -type f -iname makefile -delete || die
    find -type f -name *\~ -delete || die

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

    popd
}

enpm_install() {
    debug-print-function ${FUNCNAME} "$@"

    if nodejs_has_package; then
        einfo "Install pack files"
        enpm --prefix "${ED}"/usr \
            install \
            $(nodejs_package)-$(nodejs_version).tgz || die "install failed"
    fi

    local nodejs_files="${NODEJS_FILES} ${NODEJS_EXTRA_FILES} $(nodejs_package).js"

    dodir $(_NODEJS_MODULES) || die "Could not create DEST folder"

    for f in ${nodejs_files}; do
        if [[ -e "${S}/${f}" ]]; then
            cp -r "${S}/${f}" "${ED}/$(_NODEJS_MODULES)"
        fi
    done
}

# @FUNCTION: nodejs_src_prepare
# @DESCRIPTION:
# Implementation of src_prepare() phase
nodejs_src_prepare() {
    debug-print-function ${FUNCNAME} "$@"

    if [[ ! -e package.json ]]; then
        eerror "Unable to locate package.json"
        eerror "Consider not inheriting the nodejs eclass."
        die "FATAL: Unable to find package.json"
    fi

    default_src_prepare
}

nodejs_src_compile() {
    debug-print-function ${FUNCNAME} "$@"

    if nodejs_has_package; then
        einfo "Create pack file"
        enpm pack || die "pack failed"
    fi

    if [[ -d node_modules ]]; then
        einfo "Compile native addon modules"
        find node_modules/ -name binding.gyp -exec dirname {} \; | while read -r dir; do
            pushd "${dir}" >/dev/null
            npm_config_nodedir=/usr/ /usr/$(get_libdir)/node_modules/npm/bin/node-gyp-bin/node-gyp rebuild --verbose
            popd
        done
    fi
}

nodejs_src_test() {
    debug-print-function ${FUNCNAME} "$@"

    if jq -e '.scripts | has("test")' <package.json >/dev/null; then
        npm run test || die "test failed"
    else
        die 'No "test" command defined in package.json'
    fi
}

nodejs_src_install() {
    debug-print-function ${FUNCNAME} "$@"

    enpm_install

    dodoc *.md
}
fi
