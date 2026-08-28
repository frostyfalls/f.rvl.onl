#!/bin/sh

outdir=public
contentdir=content

# https://romanzolotarev.com/ssg/ssg.sh
tmpl() {
	d=0
	s=-1
	while IFS= read -r line; do
		o=
		rest=$line
		while :; do
			case $rest in
			*{{*)
				before=${rest%%\{\{*}
				rest=${rest#*\{\{}
				tag=${rest%%\}\}*}
				rest=${rest#*\}\}}
				[ $s -lt 0 ] && o="$o$before"
				case $tag in
				\#*) d=$((d + 1)); [ $s -lt 0 ] && [ -z "$(printenv "${tag#\#}")" ] && s=$d ;;
				^*) d=$((d + 1)); [ $s -lt 0 ] && [ -n "$(printenv "${tag#^}")" ] && s=$d ;;
				/*) [ $s -eq $d ] && s=-1; d=$((d - 1)) ;;
				*) [ $s -lt 0 ] && o="${o}$(printenv "$tag")" ;;
				esac
				;;
			*) [ $s -lt 0 ] && o="${o}${rest}"; break ;;
			esac
		done
		[ $s -lt 0 ] || [ -n "$o" ] && printf '%s\n' "$o"
	done
}

if [ -d "$outdir" ]; then
	rm -rf "$outdir"
fi
mkdir -p "$outdir"

domain=https://f.rvl.onl
export url=$domain \
	ishome=1
{
	cat base.pre.html
	printf '<h2>Bits and tips</h2>\n'
	printf '<ul>\n'
	for f in content/bits.*.md; do
		slug=${f#content/bits.}
		slug=${slug%.md}
		export title=$(lowdown -X title "$f") \
			lastmod=$(lowdown -X lastmod "$f") \
			url="$domain/$slug.html"
		printf '<li>%s: <a href="%s">%s</a></li>\n' \
			"$(date -d "$lastmod" "+%b %d %Y")" "$slug.html" "$title"
		{
			cat base.pre.html
			printf '<h1>%s</h1>\n' "$title"
			lowdown -T html "$f"
			printf '<p>Last modified %s.</p>\n' \
				"$(date -d "$lastmod" "+%b %d %Y")"
			cat base.post.html
		} | tmpl >"$outdir/$slug.html"
	done
	unset slug title lastmod
	printf '</ul>\n'
	cat base.post.html
} | tmpl >"$outdir/index.html"
cp style.css "$outdir"
