#!/bin/bash

search_dir=$1
cp=$2
old_version=$3
new_version=$4
new_sha=${5:-}
old_sha=${6:-}
hash_date=${7:-}

ebuild="$(echo "$cp"|cut -d/ -f2)"

davinci_download()
{
distdir="$(portageq envvar DISTDIR 2>/dev/null)"

_product="DaVinci Resolve Studio"
_referid='86463718c6d1491d8d95f8b49f75c4db'
_siteurl="https://www.blackmagicdesign.com/api/support/latest-stable-version/davinci-resolve-studio/linux"


_useragent="User-Agent: Mozilla/5.0 (X11; Linux ${CARCH}) \
			AppleWebKit/537.36 (KHTML, like Gecko) \
			Chrome/77.0.3865.75 \
			Safari/537.36"
_releaseinfo=$(curl -Ls "$_siteurl")


_downloadId=$(printf "%s" $_releaseinfo | sed -n 's/.*"downloadId":"\([^"]*\).*/\1/p')

_reqjson="{ \
  \"firstname\": \"Gentoo\", \
  \"lastname\": \"Linux\", \
  \"email\": \"someone@archlinux.org\", \
  \"phone\": \"202-555-0194\", \
  \"country\": \"us\", \
  \"street\": \"Bowery 146\", \
  \"state\": \"New York\", \
  \"city\": \"AUR\", \
  \"product\": \"$_product\" \
}"

_reqjson="$(  printf '%s' "$_reqjson"   | sed 's/[[:space:]]\+/ /g')"
_useragent="$(printf '%s' "$_useragent" | sed 's/[[:space:]]\+/ /g')"
_useragent_escaped="${_useragent// /\\ }"

_siteurl="https://www.blackmagicdesign.com/api/register/us/download/${_downloadId}"
_srcurl="$(curl \
	   -s \
	   -H 'Host: www.blackmagicdesign.com' \
	   -H 'Accept: application/json, text/plain, */*' \
	   -H 'Origin: https://www.blackmagicdesign.com' \
	   -H "$_useragent" \
	   -H 'Content-Type: application/json;charset=UTF-8' \
	   -H "Referer: https://www.blackmagicdesign.com/support/download/${_referid}/Linux" \
	   -H 'Accept-Encoding: gzip, deflate, br' \
	   -H 'Accept-Language: en-US,en;q=0.9' \
	   -H 'Authority: www.blackmagicdesign.com' \
	   -H 'Cookie: _ga=GA1.2.1849503966.1518103294; _gid=GA1.2.953840595.1518103294' \
	   --data-ascii "$_reqjson" \
	   --compressed \
	   "$_siteurl")"

filename=$(basename "${_srcurl%%\?*}")

curl $_srcurl --output-dir $distdir -o $filename
}

if [ "$cp" == "media-video/davinci-resolve-studio" ]; then
    davinci_download
fi
