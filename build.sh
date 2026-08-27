#!/bin/sh

outdir=public
contentdir=content

# https://romanzolotarev.com/ssg/ssg.sh
mustache() {
	d=0
	s=-1
	while IFS= read -r line; do
		o=
		rest=$line
		while :; do
			case $rest in
			*'{{'*)
				before=${rest%%\{\{*}
				rest=${rest#*\{\{}
				tag=${rest%%\}\}*}
				rest=${rest#*\}\}}
				if test $s -lt 0; then o="${o}${before}"; fi
				case $tag in
				'#'*)
					d=$((d + 1))
					if test $s -lt 0 -a -z "$(printenv "${tag#\#}")"; then s=$d; fi
					;;
				'/'*) if test $s -eq $d; then s=-1; fi && d=$((d - 1)) ;;
				'^'*)
					d=$((d + 1))
					if test $s -lt 0 -a -n "$(printenv "${tag#^}")"; then s=$d; fi
					;;
				*) if test $s -lt 0; then o="${o}$(printenv "$tag")"; fi ;;
				esac
				;;
			*) if test $s -lt 0; then o="${o}${rest}"; fi && break ;;
			esac
		done
		if test $s -lt 0 -o -n "$o"; then printf '%s\n' "$o"; fi
		# printf '%s\n' "$o"
	done
}


if [ -d "$outdir" ]; then
	rm -rf "$outdir"
fi
mkdir -p "$outdir"

{
	cat base.pre.html
	printf '<h2>Bits and tips</h2>\n'
	printf '<ul>\n'
	for f in content/bits.*.md; do
		slug=${f#content/bits.}
		slug=${slug%.md}
		export title=$(lowdown -X title "$f") \
			lastmod=$(lowdown -X lastmod "$f")
		printf '<li>%s: <a href="%s">%s</a></li>\n' \
			"$(date -d "$lastmod" "+%b %d %Y")" "/$slug.html" "$title"
		{
			cat base.pre.html
			printf '<h1>%s</h1>\n' "$title"
			lowdown -T html "$f"
			printf '<p>Last modified %s.</p>\n' \
				"$(date -d "$lastmod" "+%b %d %Y")"
			cat base.post.html
		} | mustache >"$outdir/$slug.html"
	done
	unset slug title lastmod
	printf '</ul>\n'
	cat base.post.html
} | mustache >"$outdir/index.html"
cp style.css "$outdir"
