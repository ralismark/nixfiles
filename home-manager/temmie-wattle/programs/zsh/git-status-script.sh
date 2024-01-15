#!/usr/bin/env bash

old_inprogress() {
	local gitdir=$1

	local f
	for f in "$gitdir/rebase-apply" "$gitdir/rebase"; do
		if [[ -d "$f" ]]; then
			if [[ -f "$f/rebasing" ]]; then
				echo "${2}rebase"
			elif [[ -f "$f/applying" ]]; then
				echo "${2}am"
			else
				echo "${2}am/rebase"
			fi
			return 0
		fi
	done

	if [[ -f "$gitdir/rebase-merge/interactive" ]]; then
		echo "${2}rebase-i"
	elif [[ -d "$gitdir/rebase-merge" ]]; then
		echo "${2}rebase-m"
	elif [[ -f "$gitdir/MERGE_HEAD" ]]; then
		echo "${2}merge"
	elif [[ -f "$gitdir/BISECT_LOG" ]]; then
		echo "${2}bisect"
	elif [[ -f "$gitdir/CHERRY_PICK_HEAD" ]]; then
		if [[ -d "$gitdir/sequencer" ]]; then
			echo "${2}cherry-seq"
		else
			echo "${2}cherry"
		fi
	elif [[ -d "$gitdir/sequencer" ]]; then
		echo "${2}cherry/revert"
	else
		return 1
	fi
}

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
	local stashes=$(git stash list | wc -l)
	if [ "$stashes" -eq 0 ]; then
		return
	fi
	echo " %F{14}[$stashes stashed]%f"
}

inprogress() {
	# TODO(2022-06-25) I've noticed that REBASE_HEAD sometimes stays around
	# even after rebasing, so it's not a reliable indicator of rebase
	printf '%s\n' MERGE_HEAD REBASE_HEAD BISECT_EXPECTED_REV |
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
ret=$?
if [ "$ret" = 0 ]; then
	# got a branch
	echo " %F{243}on%f %F{yellow}${HEAD}%f$(aheadbehind "$HEAD")$(inprogress)$(stashes)"
elif [ "$ret" = 1 ]; then
	# fatal: ref HEAD is not a symbolic ref
	HEAD=$(git rev-parse HEAD 2>/dev/null) || {
		echo " %F{red}E: git-rev-parse returned $ret"
		exit
	}
	echo " %F{243}at%f %F{green}${HEAD:0:7}%f$(inprogress)$(stashes)"
elif [ "$ret" = 128 ]; then
	# fatal: not a git repository (or any of the parent directories): .git
	exit
else
	echo " %F{red}E: git-symbolic-ref returned $ret"
	exit
fi
