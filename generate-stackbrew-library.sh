#!/usr/bin/env bash
set -Eeuo pipefail

declare -A aliases=(
    [1.12]='latest 1 1.12.0'
)

defaultDebianSuite='buster'

self="$(basename "$BASH_SOURCE")"
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

if [ "${1-unset}" = "nightly" ]; then
    versions=( nightly )
    aliases[nightly]="$(grep -e "^ENV CCL_COMMIT" nightly/buster/Dockerfile | cut -d" " -f 3 | head -c 7)"
elif [ "${1-unset}" = "all" ]; then
    versions=( */ )
    versions=( "${versions[@]%/}" )
    aliases[nightly]="$(grep -e "^ENV CCL_COMMIT" nightly/buster/Dockerfile | cut -d" " -f 3 | head -c 7)"
else
    versions=( */ )
    versions=( "${versions[@]%/}" )
    versions=( "${versions[@]/nightly}" )
fi

# sort version numbers with highest first
IFS=$'\n'; versions=( $(echo "${versions[*]}" | sort -rV) ); unset IFS

# get the most recent commit which modified any of "$@"
fileCommit() {
    git log -1 --format='format:%H' HEAD -- "$@"
}

# get the most recent commit which modified "$1/Dockerfile" or any file COPY'd from "$1/Dockerfile"
dirCommit() {
    local dir="$1"; shift
    (
        cd "$dir"
        fileCommit \
            Dockerfile \
            $(git show HEAD:./Dockerfile | awk '
                toupper($1) == "COPY" {
                    for (i = 2; i < NF; i++) {
                        print $i
                    }
                }
            ')
    )
}

getArches() {
    local repo="$1"; shift
    local officialImagesUrl='https://github.com/docker-library/official-images/raw/master/library/'

    eval "declare -g -A parentRepoToArches=( $(
        find -name 'Dockerfile' -exec awk '
                toupper($1) == "FROM" && $2 !~ /^('"$repo"'|scratch|.*\/.*)(:|$)/ {
                    print "'"$officialImagesUrl"'" $2
                }
            ' '{}' + \
            | sort -u \
            | xargs bashbrew cat --format '[{{ .RepoName }}:{{ .TagName }}]="{{ join " " .TagEntry.Architectures }}"'
    ) )"
}
getArches 'ccl'

cat <<-EOH
# this file is generated via https://github.com/cl-docker-images/ccl/blob/$(fileCommit "$self")/$self
Maintainers: Eric Timmons <nasafreak@gmail.com> (@daewok)
GitRepo: https://github.com/cl-docker-images/ccl.git
EOH

# prints "$2$1$3$1...$N"
join() {
    local sep="$1"; shift
    local out; printf -v out "${sep//%/%%}%s" "$@"
    echo "${out#$sep}"
}

for version in "${versions[@]}"; do

    for v in \
        buster/{,slim} \
        stretch/{,slim} \
        windowsservercore-{1809,ltsc2016}/ \
    ; do
        os="${v%%/*}"
        variant="${v#*/}"
        if [ -n "$variant" ]; then
            variantTag="-$variant"
        else
            variantTag=""
        fi

        dir="$version/$v"

        if [ "$version" = "nightly" ] && [[ "$os" == "windowsservercore"* ]]; then
            continue
        fi

        [ -f "$dir/Dockerfile" ] || continue

        commit="$(dirCommit "$dir")"

        versionAliases=(
            $version
            ${aliases[$version]:-}
        )

        variantAliases=( "${versionAliases[@]/%/$variantTag-$os}" )
        variantAliases=( "${variantAliases[@]//latest-/}" )

        case "$os" in
            windows*) variantArches='windows-amd64' ;;
            *)
                variantParent="$(awk 'toupper($1) == "FROM" { print $2 }' "$dir/Dockerfile")"
                parentArches="${parentRepoToArches[$variantParent]:-}"
                variantArches=
                for arch in $parentArches; do
                    if echo "$arch" | grep -E "amd64|arm32v7" > /dev/null; then
                        variantArches+=" $arch"
                    fi
                done
                ;;
        esac

        sharedTags=()

        if [ "$os" = "$defaultDebianSuite" ] || [[ "$os" == 'windowsservercore'* ]]; then
            sharedTags+=( "${versionAliases[@]/%/$variantTag}" )

            if [[ "$os" == "windowsservercore"* ]]; then
                sharedTags+=( "${versionAliases[@]/%/-windowsservercore$variantTag}")
            fi
        fi

        sharedTags=( "${sharedTags[@]//latest-/}" )

        echo
        echo "Tags: $(join ', ' "${variantAliases[@]}")"
        if [ "${#sharedTags[@]}" -gt 0 ]; then
            echo "SharedTags: $(join ', ' "${sharedTags[@]}")"
        fi
        cat <<-EOE
			Architectures: $(join ', ' $variantArches)
			GitCommit: $commit
			Directory: $dir
		EOE
        [[ "$os" == "windows"* ]] && echo "Constraints: $os"
    done
done
