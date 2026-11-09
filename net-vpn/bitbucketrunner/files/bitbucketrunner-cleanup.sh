#!/bin/sh
# Empty the runner's own folder before it starts, as root. The runner deletes
# what an interrupted step left there as the service user and gives up at the
# first file it cannot remove, so a single read-only or root-owned leftover
# fails every later step with runner.working-directory-teardown-error and
# leaves the runner UNHEALTHY. runner.log is kept, as the runner's own
# cleanup.previous.folders option does.
#
# Reads WORKING_DIRECTORY and RUNNER_UUID from the environment (tunnel.cfg).
set -eu

# A relative path would resolve against whatever directory the caller is in.
case ${WORKING_DIRECTORY:-} in
	/*) ;;
	*)
		echo "WORKING_DIRECTORY is not an absolute path, nothing cleaned" >&2
		exit 0
		;;
esac

# The runner names its folder after the UUID without braces, in lower case.
# Anything else is not a UUID and must never become part of an rm -rf path.
uuid=$(printf '%s' "${RUNNER_UUID:-}" | tr -d '{}' | tr 'A-F' 'a-f')
case ${uuid} in
	''|*[!0-9a-f-]*)
		echo "RUNNER_UUID is not a UUID, nothing cleaned" >&2
		exit 0
		;;
esac

dir=${WORKING_DIRECTORY%/}/${uuid}
[ -d "${dir}" ] || exit 0

find "${dir}" -mindepth 1 -maxdepth 1 ! -name runner.log -exec rm -rf -- {} +
