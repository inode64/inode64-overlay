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

case ${EAPI} in
        7|8) ;;
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

# @ECLASS_VARIABLE: NODEJS_TYPESCRIPT
# @DESCRIPTION:
# If set to "true", add build for typescript
# and add the necessary BDEPEND. If set to "false", do nothing.
: ${NODEJS_TYPESCRIPT:=false}


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

case ${NODEJS_TYPESCRIPT} in
        true)
                BDEPEND+=" dev-lang/typescript"
                ;;
        false) ;;
        *)
                eerror "Unknown value for \${NODEJS_TYPESCRIPT}"
                die "Value ${NODEJS_TYPESCRIPT} is not supported"
                ;;
esac

nodejs_version() {
    node -p "require('./package.json').version"
}
nodejs_package() {
    node -p "require('./package.json').name"
}

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

    local mynpmflags_local=( "${mynpmflags[@]}" )

    local npmflags=(
        --audit false
        --color false
        --foreground-scripts
        --global
        --offline
        --progress false
        --save false
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

	enpm prune --omit=dev || die

    if [[ ${NODEJS_TYPESCRIPT} = true ]]; then
        find ${pkgdir} -name "*.d.ts" -delete
        find ${pkgdir} -name "*.d.ts.map" -delete
        find ${pkgdir} -name "*.js.map" -delete
    fi
}

enpm_install() {
    debug-print-function ${FUNCNAME} "$@"

    enpm --prefix "${ED}"/usr \
        install \
        $(nodejs_package)-$(nodejs_version).tgz || die "install failed"
}

# @FUNCTION: nodejs_src_prepare
# @DESCRIPTION:
# Implementation of src_prepare() phase
nodejs_src_prepare() {
    debug-print-function ${FUNCNAME} "$@"

     if [[ ! -e package.json ]] ; then
         eerror "Unable to locate package.json"
         eerror "Consider not inheriting the nodejs eclass."
         die "FATAL: Unable to find package.json"
     fi
}

nodejs_src_compile() {
    debug-print-function ${FUNCNAME} "$@"

    enpm pack || die "pack failed"
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

    if [[ ${NODEJS_TYPESCRIPT} = true ]]; then
        tsc || die "tsc falied"
    fi

    dodoc *.md

    rm "${ED}"/usr/lib64/node_modules/${PN}/{LICENSE,*.md}
}

fi
