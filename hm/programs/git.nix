{ config, pkgs, inputs, ... }:
let
  inherit (pkgs) lib;
in
{
  programs.git =
    let
      idents = [
        {
          alias = "ac";
          origin = "git@gitlab.com:autumn-compass*/**";
          name = "Temmie Yao";
          email = "temmie@autumncompass.com";
        }
        {
          alias = "cse";
          origin = "gitlab@gitlab.cse.unsw.edu.au:*/**";
          name = "Temmie Yao";
          email = "t.yao@unsw.edu.au";
        }
        {
          alias = "github";
          origin = "git@github.com:*/**";
          name = "ralismark";
          email = "13449732+ralismark@users.noreply.github.com";
        }
      ];
    in
    {
      enable = true;

      aliases = {
        # higher-level ops
        amend = "commit --amend --no-edit";
        bleach = "!git reset --hard HEAD && git clean -xdff";
        bleach-ignored = "clean -Xff";
        shallow-clone = "clone --recursive --depth 1";
        shove = "push --force-with-lease";
        standup = ''!git log --author="$(git config user.name)" --all --date-order --relative-date --format='%Cgreen%h %Cblue%ad %Creset%s%Cred%d%Creset' --since=yesterday'';
        commit-empty = "commit --allow-empty --only";

        # shortcuts
        ap = "add -p";
        unap = "reset -p";
        co = "checkout";
        dl = "clone --recursive";

        # history
        graph = "hist --all -n20";
        graph2 = "log --graph --format=format:'%C(yellow)%h%C(reset) - %C(blue)%aD%C(reset) %C(green)(%ar)%C(reset)%C(auto)%d%C(reset)%n          %C(white)%s%C(reset) %C(bold black)- %an%C(reset)' --all --date-order";
        grapha = "hist --all";

        # TODO make these use git-foresta if that's available <2023-01-22>
        hist = "log --graph --date-order --format=tformat:'\t%C(yellow)%h%C(reset) %ad - %C(green)(%ar)%C(reset) %s  %C(auto)%d%C(reset)' --date=format-local:%y%m%d%H%M%S --boundary";
        #hist = "foresta --style=10 --svdepth=10 --graph-symbol-commit=● --graph-symbol-merge=▲ --graph-symbol-tip=∇  --date-order --reverse --no-status --boundary"

        # branch workflow
        bnew = "checkout --no-track origin/HEAD -b"; # usage: bnew <name> [<commit>]
        bls = "branch --list -vv";
        blog = "hist --not origin/HEAD";
        bdiff = "diff --merge-base origin/HEAD";

        # diff
        sdiff = "diff --cached";

      } // lib.listToAttrs (map
        ({ alias, origin, name, email }: {
          name = "id-${alias}";
          value = ''!git config --local user.name "${name}" && git config --local user.email "${email}"'';
        })
        idents);

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

      includes =
        (map
          ({ alias, origin, name, email }: {
            condition = "hasconfig:remote.*.url:${origin}";
            contents.user = { inherit name email; };
          })
          idents);
    };
}
