# Copyright 2019-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: nodejs.eclass
# @MAINTAINER:
# Fco. Javier Félix <web@inode64.com>
# @AUTHOR:
# Fco. Javier Félix <web@inode64.com>
# @SUPPORTED_EAPIS: 8 9
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

if [[ -z ${_NODEJS_ECLASS} ]]; then
	_NODEJS_ECLASS=1

case ${EAPI} in
    8|9) ;;
    *) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

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

# @ECLASS_VARIABLE: NODEJS_REMOVE_TYPES
# @DEFAULT_UNSET
# @DESCRIPTION:
# Set to a non-empty value to also drop the TypeScript declarations (*.d.ts
# and its .cts/.mts variants). They are read by the compiler when building
# against a package, never at run time, so an application can do without
# them. Leave it unset for a package meant to be compiled against, such as
# dev-lang/typescript, whose declarations are part of what it ships.

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
        BDEPEND+=" || ( net-libs/nodejs[corepack] sys-apps/yarn )"
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
    debug-print-function "${FUNCNAME}" "${@}"

    # Create a proper destination
    local module_path
    module_path="$(nodejs_modules)"
    [[ -z "${module_path}" ]] && die "Failed to determine module path"

    # Use node to safely parse the bin entries. The field is either a string,
    # and then the unscoped package name is the command, or an object mapping
    # command names to paths.
    local bins
    bins=$(node -e '
        const pkg = require("./package.json");
        const bin = typeof pkg.bin === "string"
            ? { [pkg.name.replace(/^@[^/]+\//, "")]: pkg.bin }
            : pkg.bin;
        for (const [name, file] of Object.entries(bin)) {
            console.log(name + "\t" + file.replace(/^\.\//, ""));
        }
    ') || die "Failed to parse the bin entries of package.json"

    local key value dir
    while IFS=$'\t' read -r key value; do
        [[ -n "${key}" && -n "${value}" ]] || continue

        # enpm_install() already copied whatever NODEJS_FILES covers, so only
        # install the entries that live outside of it. Copying unconditionally
        # would flatten the path and leave a stray duplicate behind.
        if [[ ! -e "${ED}/${module_path}/${value}" ]]; then
            dir="${value%/*}"
            [[ "${dir}" == "${value}" ]] && dir=""

            insinto "${module_path}${dir:+/${dir}}"
            doins "${value}"
        fi

        fperms +x "${module_path}/${value}"
        dosym -r "${module_path}/${value}" "/usr/bin/${key}"
    done <<<"${bins}"
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
    # examples is used in node-red , see bug (inode64/inode64-overlay#38)

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
    find -type f -iregex '.*\.\(tsx\|jsx\|map\)$' -delete || die
    # shellcheck disable=SC2185
    find -type f -name tsconfig.json -delete || die
    # shellcheck disable=SC2185
    find -type f -name docker-compose.yml -delete || die
    # shellcheck disable=SC2185
    find -type f -iname CopyrightNotice.txt -delete || die

    # Remove misc files
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
    # shellcheck disable=SC2185
    find -type f -iregex '.*\.\(orig\|rej\|keep\|gitkeep\|auto-changelog\)$' -delete || die
    # Lock files describe how a tree was resolved, which is already settled
    # once it is installed, and the rest is repository bookkeeping.
    # shellcheck disable=SC2185
    find -type f \( -name 'yarn.lock' -o -name 'package-lock.json' -o \
        -name 'pnpm-lock.yaml' -o -name 'CODEOWNERS' -o -iname 'codecov.yml' -o \
        -iname 'opslevel.yml' \) -delete || die

    if [[ -n ${NODEJS_REMOVE_TYPES} ]]; then
        # shellcheck disable=SC2185
        find -type f -iregex '.*\.d\.\(ts\|cts\|mts\)$' -delete || die
    fi

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
    find -type f -iregex '.*/\(jest\.config\..*\|karma\.conf\..*\|ava\.config\..*\|jasmine\.json\)$' -delete || die
    # No rule on file names here. "sample", "demo", "fixture" and "benchmark"
    # are ordinary function names, and matching them by prefix takes real API
    # with them: lodash publishes sample.js and sampleSize.js, es-toolkit and
    # underscore do the same, and vitest ships a dist chunk called benchmark.
    # The directory rules below cover the development trees anyway.

    # Remove the prebuilt libraries meant for another system. A package that
    # vendors one library per target keeps them all side by side, named after
    # it, so the ones that can never be loaded here can go. Windows and macOS
    # never can; of the Linux ones drop the foreign libc and architectures.
    local foreign_libs=( -iname '*.dll' -o -iname '*.dylib' )

    if [[ ${CHOST} == *-musl* ]]; then
        foreign_libs+=( -o -iname '*[-_.]gnu.so' -o -iname '*[-_.]glibc.so' \
            -o -iname '*[-_.]gnu.node' -o -iname '*[-_.]glibc.node' )
    else
        foreign_libs+=( -o -iname '*[-_.]musl.so' -o -iname '*[-_.]musl.node' )
    fi

    # Only the tokens that cannot be mistaken for the native one, hence no
    # bare "x86" on amd64: it is a prefix of "x86_64". Missing a foreign
    # library only wastes space, deleting a native one breaks the package.
    local foreign_arches=() arch_token
    case ${ARCH} in
        amd64) foreign_arches=( aarch64 arm arm64 armhf armv6 armv7 i386 i686 ia32 ppc64 ppc64le riscv64 s390x ) ;;
        arm)   foreign_arches=( aarch64 amd64 arm64 i386 i686 ia32 ppc64 ppc64le riscv64 s390x x64 x86_64 ) ;;
        arm64) foreign_arches=( amd64 arm armhf armv6 armv7 i386 i686 ia32 ppc64 ppc64le riscv64 s390x x64 x86_64 ) ;;
        ppc64) foreign_arches=( aarch64 amd64 arm arm64 armhf armv6 armv7 i386 i686 ia32 riscv64 s390x x64 x86_64 ) ;;
        riscv) foreign_arches=( aarch64 amd64 arm arm64 armhf armv6 armv7 i386 i686 ia32 ppc64 ppc64le s390x x64 x86_64 ) ;;
        s390)  foreign_arches=( aarch64 amd64 arm arm64 armhf armv6 armv7 i386 i686 ia32 ppc64 ppc64le riscv64 x64 x86_64 ) ;;
        x86)   foreign_arches=( aarch64 arm arm64 armhf armv6 armv7 ppc64 ppc64le riscv64 s390x x64 x86_64 ) ;;
    esac

    for arch_token in "${foreign_arches[@]}"; do
        foreign_libs+=( -o -iname "*[-_]${arch_token}.so" -o -iname "*[-_]${arch_token}[-_]*.so" )
        foreign_libs+=( -o -iname "*[-_]${arch_token}.node" -o -iname "*[-_]${arch_token}[-_]*.node" )
    done

    # shellcheck disable=SC2185
    find -type f \( "${foreign_libs[@]}" \) -delete || die

    # Remove what node-gyp leaves behind in a native addon: only the compiled
    # .node under build/Release is needed at run time, the object files, the
    # generated makefiles and the C++ sources it was built from are not.
    #
    # Restrict the sweep to the packages that actually carry a binding.gyp.
    # Names such as "src" or "*.h" are ordinary elsewhere in the tree, and a
    # package that ships no addon may well need them.
    local addon_dir
    while IFS= read -r -d '' addon_dir; do
        addon_dir=${addon_dir%/binding.gyp}

        rm -rf "${addon_dir}"/build/Release/obj \
            "${addon_dir}"/build/Release/obj.target \
            "${addon_dir}"/build/Release/node-addon-api \
            "${addon_dir}"/build/deps \
            "${addon_dir}"/build/node_gyp_bins ||
            ewarn "Failed to remove the node-gyp intermediates of ${addon_dir}"
    done < <(find . -type f -name binding.gyp -print0)

    # The sources it was built from, on the other hand, can go tree wide.
    # Node loads none of these, and a package such as node-addon-api or nan
    # exists only to be compiled against, so it carries nothing else.
    # shellcheck disable=SC2185
    find -type f \
    \( \
        -name '*.a' -o \
        -name '*.c' -o \
        -name '*.cc' -o \
        -name '*.cpp' -o \
        -name '*.cxx' -o \
        -name '*.gyp' -o \
        -name '*.gypi' -o \
        -name '*.h' -o \
        -name '*.hpp' -o \
        -name '*.o' -o \
        -name '*.target.mk' -o \
        -name 'binding.Makefile' -o \
        -name 'gyp-mac-tool' \
    \) -delete || die

    # Remove tooling, build and foreign platform directories. None of these
    # names is ever part of a package's own code, so they can go at any depth.
    # shellcheck disable=SC2185
    find -type d \
    \( \
        -iwholename '*/.deps' -o \
        -iwholename '*/.github' -o \
        -iwholename '*/.idea' -o \
        -iwholename '*/.nyc_output' -o \
        -iwholename '*/.storybook' -o \
        -iwholename '*/.tscache' -o \
        -iwholename '*/.vscode' -o \
        -iwholename '*/android-arm' -o \
        -iwholename '*/android-arm64' -o \
        -iwholename '*/coverage' -o \
        -iwholename '*/darwin-x64' -o \
        -iwholename '*/darwin-x64+arm64' -o \
        -iwholename '*/git-hooks' -o \
        -iwholename '*/linux-arm' -o \
        -iwholename '*/linux-arm64' -o \
        -iwholename '*/linux-armv6' -o \
        -iwholename '*/linux-armv7' -o \
        -iwholename '*/linux-armv8' -o \
        -iwholename '*/prebuilds' -o \
        -iwholename '*/storybook-static' -o \
        -iwholename '*/win32-arm64' -o \
        -iwholename '*/win32-ia32' -o \
        -iwholename '*/win32-x64' -o \
        -iwholename '*/*-musl' \
    \) \
    -exec rm -rvf {} + || ewarn "Failed to remove some directories"

    # Remove development directories.
    #
    # Unlike the names above, these are ordinary words that only mean
    # "development files" at the top level of a package. Deeper down they
    # belong to the code, for example yaml ships its document model in
    # dist/doc, and a dependency can simply be called test or docs. So only
    # prune a directory whose parent is a package root.
    local dev_dirs=() dev_dir
    while IFS= read -r -d '' dev_dir; do
        [[ -f "${dev_dir%/*}/package.json" ]] && dev_dirs+=( "${dev_dir}" )
    done < <(find . -type d \
    \( \
        -iwholename '*/benchmark' -o \
        -iwholename '*/benchmarks' -o \
        -iwholename '*/demo' -o \
        -iwholename '*/doc' -o \
        -iwholename '*/docs' -o \
        -iwholename '*/fixture' -o \
        -iwholename '*/fixtures' -o \
        -iwholename '*/man' -o \
        -iwholename '*/scripts' -o \
        -iwholename '*/test' -o \
        -iwholename '*/tests' \
    \) -print0)

    # find has walked the whole tree already, so removing entries is safe now.
    for dev_dir in "${dev_dirs[@]}"; do
        rm -rvf "${dev_dir}" || ewarn "Failed to remove ${dev_dir}"
    done

    # Everything above deletes files, which tends to leave whole directory
    # trees behind with nothing in them, for example the Windows only
    # third_party of node-pty. -delete implies -depth, so a parent left empty
    # by its children goes in the same pass.
    # shellcheck disable=SC2185
    find -mindepth 1 -type d -empty -delete || ewarn "Failed to remove some empty directories"
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
