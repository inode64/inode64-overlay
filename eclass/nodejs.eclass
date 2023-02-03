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

RDEPEND="net-libs/nodejs"
BDEPEND="
	net-libs/nodejs[npm]
	test? ( app-misc/jq )
"

NPM_FLAGS=(
        --audit false
        --color false
        --foreground-scripts
        --global
        --omit dev
        --offline
        --progress false
        --save false
        --verbose
)


# @FUNCTION: nodejs_src_prepare
# @DESCRIPTION:
# Implementation of src_prepare() phase
nodejs_src_prepare() {
     if [[ ! -e package.json ]] ; then
         eerror "Unable to locate package.json"
         eerror "Consider not inheriting the nodejs eclass."
         die "FATAL: Unable to find package.json"
     fi
}

nodejs_src_compile() {
        npm "${NPM_FLAGS[@]}" pack || die "npm pack failed"
}

nodejs_src_test() {
	if jq -e '.scripts | has("test")' <package.json >/dev/null; then
		npm run test || die
	else
		die 'No "test" command defined in package.json'
	fi
}

nodejs_src_install() {
    local NAME=$(node -p "require('./package.json').name")
    Local DEV=$(node -p "require('./package.json').version")

    npm "${NPM_FLAGS[@]}" \
        --prefix "${ED}"/usr \
        install \
        ${NAME}-${DEV}.tgz || die "npm install failed"

    find ${pkgdir} -name "*.d.ts" -delete
    find ${pkgdir} -name "*.d.ts.map" -delete
    find ${pkgdir} -name "*.js.map" -delete

    dodoc *.md

    rm "${ED}"/usr/lib64/node_modules/${PN}/{LICENSE,*.md}
}

fi