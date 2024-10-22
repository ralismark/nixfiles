#!/usr/bin/env bash

aheadbehind() {
	git for-each-ref "refs/heads/$1" --format="%(upstream:track,nobracket)" |
	sed -e '
		s/ahead/%F{243}\0%F{green}/ # Ahead count as green
		s/behind/%F{243}\0%F{red}/ # Behind count as red
		s/gone/%F{243}\0/
		s/^./ \0/ # Add space
		/./s/$/%f/
	'
}

stashes() {
	stash_count=$(git stash list | wc -l)
	if [ "$stash_count" -eq 0 ]; then
		return
	fi
	echo " %F{14}[$stash_count stashed]%f"
}

inprogress() {
	printf '%s\n' MERGE_HEAD rebase-merge/onto BISECT_EXPECTED_REV |
	git cat-file --batch-check="%(objecttype)" |
	sed -ne '
		/^commit$/ {
			1i\ %F{red}[merging]%f
			2i\ %F{red}[rebasing]%f
			3i\ %F{red}[bisecting]%f
			q
		}
	'
}

HEAD=$(git symbolic-ref -q --short HEAD 2>/dev/null)
case "$?" in
	0)
		# got a branch
		echo " %F{243}on%f %F{yellow}${HEAD}%f$(aheadbehind "$HEAD")$(inprogress)$(stashes)"
		;;
	1)
		# fatal: ref HEAD is not a symbolic ref
		HEAD=$(git rev-parse HEAD 2>/dev/null) || {
			echo " %F{red}E: git-rev-parse returned $?"
			exit
		}
		echo " %F{243}at%f %F{green}${HEAD:0:7}%f$(inprogress)$(stashes)"
		;;
	128)
		# fatal: not a git repository (or any of the parent directories): .git
		;;
	*)
		echo " %F{red}E: git-symbolic-ref returned $?"
		;;
esac
