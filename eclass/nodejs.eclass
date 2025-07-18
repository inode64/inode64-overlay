# Copyright 2019-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: nodejs.eclass
# @MAINTAINER:
# Fco. Javier Félix <web@inode64.com>
# @AUTHOR:
# Fco. Javier Félix <web@inode64.com>
# @SUPPORTED_EAPIS: 8
# @BLURB: An eclass for build NodeJS projects
# @DESCRIPTION:
# An eclass providing functions to build NodeJS projects
#
# Credits and ideas from:
#   Initial version from:
#       https://github.com/gentoo/gentoo/pull/930/files
#       https://github.com/samuelbernardo/ssnb-overlay/blob/master/eclass/npm.eclass
#       https://github.com/gentoo-mirror/lanodanOverlay/blob/master/eclass/nodejs.eclass
#       https://github.com/Tatsh/tatsh-overlay/blob/master/eclass/yarn.eclass
#
# Build package for node_modules:
#   npm:
#       npm install --audit false --color false --foreground-scripts --progress false --verbose --ignore-scripts
#
#   yarn:
#       yarn install --color false --foreground-scripts --progress false --verbose --ignore-scripts
#
#   Create archive in tar:
#       tar --create --auto-compress --file foo-1-node_modules.tar.xz foo-1/node_modules/

case ${EAPI} in
    8) ;;
    *) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ -z ${_NODEJS_ECLASS} ]]; then
_NODEJS_ECLASS=1

# @ECLASS_VARIABLE: NODEJS_MANAGER
# @PRE_INHERIT
# @DEFAULT_UNSET
# @DESCRIPTION:
# Specify a NodeJS package manager to use. ( npm | yarn )
# The default is set to "npm".
: "${NODEJS_MANAGER:=npm}"

# @ECLASS_VARIABLE: NODEJS_FILES
# @INTERNAL
# @DESCRIPTION:
# Files and directories that usually come in a standard NodeJS/npm module.
NODEJS_FILES="babel.config.js babel.config.json bin cli.js dist index.js lib node_modules package.json"

# @ECLASS_VARIABLE: NODEJS_EXTRA_FILES
# @DESCRIPTION:
# If additional dist files are present in the NodeJS/npm module that are not
# listed in NODEJS_FILES, then this is the place to put them in.
# Can be either files, or directories.
# Example: NODEJS_EXTRA_FILES="rigger.js modules"

# @VARIABLE: MYNPMARGS
# @DEFAULT_UNSET
# @DESCRIPTION:
# User-controlled environment variable containing arguments to be passed to npm

case ${NODEJS_MANAGER} in
    npm)
        BDEPEND+=" net-libs/nodejs[npm]"
        ;;
    yarn)
        BDEPEND+=" sys-apps/yarn"
        ;;
    *)
        eerror "Unknown value for \${NODEJS_MANAGER}"
        die "Value ${NODEJS_MANAGER} is not supported"
        ;;
esac

# @FUNCTION: nodejs_version
# @DESCRIPTION:
# Returns the package version
nodejs_version() {
    node -p "require('./package.json').version" || die "Failed to extract version from package.json"
}

# @FUNCTION: nodejs_package
# @DESCRIPTION:
# Returns the package name
nodejs_package() {
    node -p "require('./package.json').name" || die "Failed to extract package name from package.json"
}

# @FUNCTION: nodejs_has_test
# @DESCRIPTION:
# Returns true if test script exist
nodejs_has_test() {
    node -p "if (require('./package.json').scripts.test === undefined) { process.exit(1) }" &>/dev/null
}

# @FUNCTION: nodejs_has_build
# @DESCRIPTION:
# Returns true if build script exist
nodejs_has_build() {
    node -p "if (require('./package.json').scripts.build === undefined) { process.exit(1) }" &>/dev/null
}

# @FUNCTION: nodejs_has_bin
# @DESCRIPTION:
# Returns true if bin exist
nodejs_has_bin() {
   node -p "if (require('./package.json').bin === undefined) { process.exit(1) }" &>/dev/null
}

# @FUNCTION: nodejs_install_bin
# @DESCRIPTION:
# Install binary files
nodejs_install_bin() {
    # Create a proper destination
    local module_path
    module_path="$(nodejs_modules)"
    [[ -z "${module_path}" ]] && die "Failed to determine module path"

    # Use node to safely parse the bin entries
    local bins
    bins=$(node -e "console.log(JSON.stringify(require('./package.json').bin))")

    insinto "${module_path}"
    echo "$bins" | tr '{},' '\n' | grep ':' | sed -e 's/\"//g' -e 's/,$//'| while IFS=: read -r key value; do
      key="$(echo "$key" | xargs)"
      value="$(echo "$value" | xargs)"

      doins "${value}"
      fperms +x "${module_path}/${value}"
      dosym -r "${module_path}/${value}" "/usr/bin/${key}"
    done
}

# @FUNCTION: nodejs_modules
# @DESCRIPTION:
# Returns location where to install NodeJS
nodejs_modules() {
    local package_name
    package_name=$(nodejs_package)
    [[ -z "${package_name}" ]] && die "Failed to determine package name"

    # shellcheck disable=SC2046
    echo "/usr/$(get_libdir)/node_modules/${package_name}"
}

# @FUNCTION: nodejs_has_package
# @DESCRIPTION:
# Returns true (0) if is a package
nodejs_has_package() {
    [[ -d package ]]
}

# @FUNCTION: nodejs_docs
# @DESCRIPTION:
# Install docs usually found in NodeJS/NPM packages
nodejs_docs() {
    # If docs variable is not empty when install docs usually found in NodeJS/NPM packages
    [[ ! "${DOCS}" ]] || return

    einfo "Installing documentation"

    local f
    for f in README* HISTORY* ChangeLog AUTHORS NEWS TODO CHANGES \
        THANKS BUGS FAQ CREDITS CHANGELOG* *.md; do
        if [[ -s "${f}" ]]; then
            dodoc "${f}"
        fi
    done
}

# @FUNCTION: nodejs_remove_dev
# @INTERNAL
# @DESCRIPTION:
# Remove docs, licenses and development files
nodejs_remove_dev() {
    # Remove license files
    # shellcheck disable=SC2185
    find -type f -iregex '.*/\(...-\)?license\(-...\|-apache\)?\(\.\(md\|rtf\|txt\|markdown\|bsd\)\)?$' -delete || die

    # Remove documentation files
    # shellcheck disable=SC2185
    find -type f -iregex '.*/*.\.md$' -delete || die
    # shellcheck disable=SC2185
    find -type f -iregex '.*/\(readme\(.*\)?\|changelog\|roadmap\|security\|release\|contributors\|todo\|authors\)$' -delete || die

    # Remove TypeScript files
    # shellcheck disable=SC2185
    find -type f -iregex '.*\.\(tsx?\|jsx\|map\)$' -delete || die
    # shellcheck disable=SC2185
    find -type f -name tsconfig.json -delete || die
    # shellcheck disable=SC2185
    find -type f -name docker-compose.yml -delete || die
    # shellcheck disable=SC2185
    find -type f -iname CopyrightNotice.txt -delete || die

    # Remove misc files
    # shellcheck disable=SC2185
    find -type f -iname '*.musl.node' -delete || die
    # shellcheck disable=SC2185
    find -type f -iregex '.*\.\(editorconfig\|bak\|npmignore\|exe\|gitattributes\|ps1\|ds_store\|log\|pyc\)$' -delete || die
    # shellcheck disable=SC2185
    find -type f -iregex '.*\.\(travis.yml\|makefile\|jshintrc\|flake8\|mk\|env\|nycrc\|eslint.*\|coveralls.*\)$' -delete || die
    # shellcheck disable=SC2185
    find -type f -iregex '.*\.\(jscs.json\|jshintignore\|gitignore\|babelrc.*\|runkit_example.js\|airtap.yml\)$' -delete || die
    # shellcheck disable=SC2185
    find -type f -iregex '.*\.\(jekyll-metadata\|codeclimate.yml\|prettierrc.yaml\|drone.jsonnet\|mocharc.*\)$' -delete || die
    # shellcheck disable=SC2185
    find -type f -iname makefile -delete || die
    # shellcheck disable=SC2185
    find -type f -name '*\~' -delete || die

    # Additional files to remove
    # shellcheck disable=SC2185
    find -type f -iregex '.*\.\(flow\|husky.*\|huskyrc\|lintstagedrc\|commitlintrc\|storybook.*\)$' -delete || die
    # shellcheck disable=SC2185
    find -type f -iregex '.*\.\(webpack.config.*\|rollup.config.*\|parcel.*\|grunt.*\|gulp.*\)$' -delete || die
    # shellcheck disable=SC2185
    find -type f -iregex '.*\.\(browserslist.*\|nvmrc\|dockerignore\|stylelintrc.*\|prettierignore\)$' -delete || die
    # shellcheck disable=SC2185
    find -type f -iregex '.*\.\(appveyor.yml\|circle.yml\|circleci.*\|dependabot.*\|renovate.*\)$' -delete || die
    # shellcheck disable=SC2185
    find -type f -iregex '.*/\(jest.config.*\|karma.conf.*\|ava.config.*\|jasmine.*\)$' -delete || die
    # shellcheck disable=SC2185
    find -type f -iregex '.*/\(benchmark.*\|example.*\|demo.*\|fixture.*\|sample.*\)$' -delete || die

    # Remove development directories
    # shellcheck disable=SC2185
    find -type d \
    \( \
        -iwholename '*.deps' -o \
        -iwholename '*.github' -o \
        -iwholename '*.idea' -o \
        -iwholename '*.nyc_output' -o \
        -iwholename '*.tscache' -o \
        -iwholename '*.vscode' -o \
        -iwholename '*/.storybook' -o \
        -iwholename '*/android-arm' -o \
        -iwholename '*/android-arm64' -o \
        -iwholename '*/benchmarks' -o \
        -iwholename '*/coverage' -o \
        -iwholename '*/darwin-x64' -o \
        -iwholename '*/darwin-x64+arm64' -o \
        -iwholename '*/demo' -o \
        -iwholename '*/doc' -o \
        -iwholename '*/docs' -o \
        -iwholename '*/examples' -o \
        -iwholename '*/fixtures' -o \
        -iwholename '*/git-hooks' -o \
        -iwholename '*/linux-arm' -o \
        -iwholename '*/linux-arm64' -o \
        -iwholename '*/linux-armv6' -o \
        -iwholename '*/linux-armv7' -o \
        -iwholename '*/linux-armv8' -o \
        -iwholename '*/man' -o \
        -iwholename '*/prebuilds' -o \
        -iwholename '*/scripts' -o \
        -iwholename '*/storybook-static' -o \
        -iwholename '*/test' -o \
        -iwholename '*/tests' -o \
        -iwholename '*/win32-arm64' -o \
        -iwholename '*/win32-ia32' -o \
        -iwholename '*/win32-x64' \
    \) \
    -exec rm -rvf {} + || ewarn "Failed to remove some directories"
}

# @FUNCTION: enpm
# @DESCRIPTION:
# Packet manager execution wrapper
enpm() {
    debug-print-function "${FUNCNAME}" "${@}"

    local mynpmargs_local mynpmargstype npmargs

    # Make the array a local variable since <=portage-2.1.6.x does not support
    # global arrays (see bug #297255). But first make sure it is initialised.
    [[ -z ${mynpmargs} ]] && declare -a mynpmargs=()
    mynpmargstype=$(declare -p mynpmargs 2>&-)
    if [[ "${mynpmargstype}" != "declare -a mynpmargs="* ]]; then
        die "mynpmargs must be declared as array"
    fi

    mynpmargs_local=("${mynpmargs[@]}")
    npmargs=(
        --color false
        --foreground-scripts
        --offline
        --progress false
        --verbose
        "${mynpmargs_local[@]}"
    )

    case ${NODEJS_MANAGER} in
        npm)
            if ! type -P npm >/dev/null; then
                eerror "npm is required but not installed or not in PATH"
                die "npm not available"
            fi
            npmargs+=( --audit false )
            npm "$@" "${npmargs[@]}"
            ;;
        yarn)
            if ! type -P yarn >/dev/null; then
                eerror "yarn is required but not installed or not in PATH"
                die "yarn not available"
            fi
            npmargs+=( --cache-folder ".cache" )
            yarn "$@" "${npmargs[@]}"
            ;;
    esac
}

# @FUNCTION: enpm_clean
# @DESCRIPTION:
# Delete all unnecessary files
enpm_clean() {
    debug-print-function "${FUNCNAME}" "${@}"

    local nodejs_files f

    einfo "Cleaning up unnecessary files"

    case ${NODEJS_MANAGER} in
        npm)
            enpm prune --omit=dev || die "npm prune failed"
            ;;
        yarn)
            enpm install --production || die "yarn install production failed"
            if type -P yarn >/dev/null && yarn --help | grep -q autoclean; then
                enpm autoclean --init || ewarn "yarn autoclean --init failed"
                enpm autoclean --force || ewarn "yarn autoclean --force failed"
            else
                ewarn "yarn autoclean not available, skipping additional cleanup"
            fi
            ;;
    esac

    nodejs_files="${NODEJS_FILES} ${NODEJS_EXTRA_FILES}"

    # Cleanups
    for f in ${nodejs_files}; do
        if [[ -d "${f}" ]]; then
            pushd "${f}" >/dev/null || die
            nodejs_remove_dev
            popd >/dev/null || die
        fi
    done
}

# @FUNCTION: enpm_install
# @DESCRIPTION:
# Install the files and folders necessary for the execution of NodeJS
enpm_install() {
    debug-print-function "${FUNCNAME}" "${@}"

    local nodejs_files f
    local module_path

    einfo "Installing NodeJS module"

    module_path="$(nodejs_modules)"
    [[ -z "${module_path}" ]] && die "Failed to determine module path"

    if nodejs_has_package; then
        einfo "Installing packaged files..."
        enpm --prefix "${ED}"/usr \
            install \
            "$(nodejs_package)-$(nodejs_version).tgz" || die "install failed"
    fi

    nodejs_files="${NODEJS_FILES} ${NODEJS_EXTRA_FILES} $(nodejs_package).js"

    dodir "${module_path}"

    for f in ${nodejs_files}; do
        if [[ -e "${f}" ]]; then
            cp -r "${f}" "${ED}/${module_path}" || die "Failed to copy ${f}"
        fi
    done

    pushd "${ED}/${module_path}" >/dev/null || die

    # Reset permissions for all files
    find -type f | while read -r f; do
        fperms -x "${module_path}/${f}"
    done

    # Set permissions for executables and libraries
    find -type f -name "*.node" | while read -r f; do
        fperms +x "${module_path}/${f}"
    done

    find -type f -executable | while read -r f; do
        fperms +x "${module_path}/${f}"
    done

    popd >/dev/null || die

    if nodejs_has_bin; then
        einfo "Installing binary files..."
        nodejs_install_bin
    fi
}

fi
