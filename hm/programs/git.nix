{ config, pkgs, inputs, ... }:
let
  inherit (pkgs) lib;
in
{
  imports = [
    ../modules/git-identity.nix
  ];

  programs.git = {
      enable = true;

      identity = {
        ac = {
          origins = ["git@gitlab.com:autumn-compass*/**"];
          userName = "Temmie Yao";
          userEmail = "temmie@autumncompass.com";
        };
        cse = {
          origins = ["gitlab@gitlab.cse.unsw.edu.au:*/**"];
          userName = "Temmie Yao";
          userEmail = "t.yao@unsw.edu.au";
        };
        github = {
          origins = ["git@github.com:*/**"];
          userName = "ralismark";
          userEmail = "13449732+ralismark@users.noreply.github.com";
        };
      };

      aliases = {
        # higher-level ops
        amend = "commit --amend --no-edit";
        bleach = "!git reset --hard HEAD && git clean -xdff";
        bleach-ignored = "clean -Xff";
        shallow-clone = "clone --recursive --depth 1";
        shove = "push --force-with-lease";
        standup = ''!git log --author="$(git config user.name)" --all --date-order --relative-date --format='%Cgreen%h %Cblue%ad %Creset%s%Cred%d%Creset' --since=yesterday'';
        commit-empty = "commit --allow-empty --only";
        push-new = "push -u origin HEAD";

        # shortcuts
        ap = "add -p";
        unap = "reset -p";
        co = "checkout";
        dl = "clone --recursive";

        # history
        graph = "hist -n20 --branches";

        # TODO make these use git-foresta if that's available <2023-01-22>
        hist = "log --graph --date-order --boundary --format=tformat:'\t%C(yellow)%h %C(blue)%ad %C(bold black)%an %C(reset)%s%C(auto)%d' --date=format-local:'%_d %b %y'";
        hist-base = "log --graph --date-order --boundary --format=tformat:'\t%C(yellow)%h %C(blue)%ad %C(reset)\t%C(bold black)%an %C(reset)%s%C(auto)%d%C(reset) #@#' --date=format-local:'%_d %b %y'";
        hist2 = ''!bash -c 'git hist-base --color=always "$@" | sed -Ee "s/^(.*)\t(.*)\t(.*)#@#$/\2\1\t\3/" | less -F' --'';

        # branch workflow
        bnew = "checkout --no-track origin/HEAD -b"; # usage: bnew <name> [<commit>]
        bls = "branch --list -vv";
        blog = "hist HEAD ^origin/HEAD";
        bdiff = "diff --merge-base origin/HEAD";

        # diff
        sdiff = "diff --cached";

      };

      extraConfig = {
        core = {
          autoclrf = "input";
          eol = "lf";
          hideDotFiles = false;
          symlinks = true;
        };

        advice = lib.flip lib.genAttrs (_: false) [
          "detachedHead"
        ];

        credential.helper = "cache";

        user.useConfigOnly = true;

        # Operation-Specific ====================================================

        diff.algorithm = "patience";
        diff.context = 10;
        diff.wordRegex = "[^[:punct:][:space:]]+|[[:punct:][:space:]]";

        fetch.prune = true; # remove remote references that no longer exist
        fetch.pruneTags = true; # remove remote tags that no longer exist

        grep.lineNumber = true; # -n by default, like regular grep

        init.defaultBranch = "main";

        interactive.singleKey = true; # no need to hit return for git add -p and others

        pull.rebase = true; # better than the default of doing a merge

        push.autoSetupRemote = true; # auto do -u <branch> on git push
        push.default = "simple";

        rebase.autoSquash = true; # handle fixup! and others
        rebase.autoStash = true; # stash local changes before rebasing

        status.short = true;
        status.branch = true;

        # URL Subtitution =======================================================

        # replace urls e.g. for go
        url."git@github.com:".insteadOf = "https://github.com/";
        url."git@gitlab.com:".insteadOf = "https://gitlab.com/";
        # but not for crates.io (to avoid issues with cargo-edit)
        url."https://github.com/rust-lang/crates.io-index".insteadOf = "https://github.com/rust-lang/crates.io-index";
      };
    };
}
