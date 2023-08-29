{ config, inputs, lib, pkgs, ... }:
with lib;
{
  imports = [
    ./module-setopt.nix
    ../../modules/zsh-bindkey.nix
  ];

  home.packages = [(
    pkgs.runCommandLocal "x-default-shell-is-zsh" { } ''
      mkdir -p $out/bin
      ln -s ${pkgs.zsh}/bin/zsh $out/bin/x-default-shell
    ''
  )];

  home.shellAliases = {
    #
    # args
    #
    ls = "ls --color=auto -FhH";
    sudo = "sudo -E ";
    less = "less -SR";
    rm = "rm -I";
    tree = "tree -CF";
    rclone = "rclone --progress --transfers 16";

    diff = "diff --color=auto";
    grep = "grep --color=auto";
    ip = "ip --color=auto";
    dd = "dd bs=1M status=progress";
    watch = "watch --color ";

    ninja = "nice -n19 -- ninja";
    make = "nice -n19 -- make";

    #
    # complete after
    #
    tunnel-run = "tunnel-run ";

    #
    # abbreviations
    #
    sc = "systemctl";
    uc = "systemctl --user";
    jc = "journalctl";
    ujc = "journalctl --user";
    ll = "ls -Al";

    #
    # commands
    #

    cdtemp = "cd $(mktemp -d)";
    isatty = ''(){ script --return --quiet --flush --command "$(printf "%q " "$@")" /dev/null } '';
  };

  programs.zsh = {
    enable = true;

    enableAutosuggestions = true;
    enableCompletion = true;
    enableSyntaxHighlighting = true;

    defaultKeymap = "emacs";

    history = {
      path = "${config.xdg.dataHome}/zsh/history"; # TODO 2021-11-14 move this out of home directory
      extended = true;
      ignoreDups = true;
      share = false;
      save = 100000; # 100_000
      size = 100000;
    };

    options = {
      correct              = true;
      prompt_subst          = true;
      interactive_comments = true;
      nomatch              = false;
      sh_word_split        = true; # for closer to posix

      # from https://unix.stackexchange.com/a/157773/319760
      auto_pushd   = true;
      pushd_minus  = true;
      pushd_silent = true;

      # add commands to history, but don't import them when doing completion
      inc_append_history = true;

      # apply completions even when there are aliases
      completealiases = true;
    };

    shellAliases = {
      "$" = " ";
      "@" = "tunnel-run ";
      "@@" = ''tunnel-run sh -c "exec \$SHELL --login"'';

      dcc = "clang $DFLAGS";
      "d++" = "clang++ -std=c++14 $DFLAGS";
    };

    localVariables = {
      ZSH_AUTOSUGGEST_STRATEGY = "completion";
      ZSH_AUTOSUGGEST_USE_ASYNC = "1";
      DFLAGS = ''
        -Wall -Wextra -pedantic -O2 -Wshadow -Wformat=2 -Wfloat-equal
        -Wconversion -Wshift-overflow -Wcast-qual -Wcast-align -D_GLIBCXX_DEBUG
        -D_GLIBCXX_DEBUG_PEDANTIC -D_FORTIFY_SOURCE=2 -fsanitize=address
        -fsanitize=undefined -fno-sanitize-recover=undefined,integer -fstack-protector
        -Wno-unused-result -DL -g
      '';
    };

    bindkey = let
      zle-run = x: "zle push-input\nBUFFER=${escapeShellArg x}\nzle accept-line";
    in {
      # TODO ranger-like cd. In quick-cd mode:
      # - h adds .. to current path (or strips one path element)
      # - j goes to next suggestion
      # - k goes to previous suggestion
      # - l enters directory to dir/.
      # you are also shown a summary of the contents of the directory

      # standard meanings of keys
      Home.widget = "beginning-of-line";
      End.widget = "end-of-line";
      Insert.widget = "overwrite-mode";
      Delete.widget = "delete-char";
      # Up.widget = "up-line-or-history";
      # Down.widget = "down-line-or-history";
      Left.widget = "backward-char";
      Right.widget = "forward-char";

      Up.widget = "up-line-or-beginning-search";
      Down.widget = "down-line-or-beginning-search";
      C-Tab.widget = "reverse-menu-complete";
      C-Left.widget = "backward-word";
      C-Right.widget = "forward-word";

      " ".widget = "magic-space";
      "^H".widget = "backward-kill-word";
      "^_".widget = "run-help";

      "^z".script = zle-run "fg";
      "^u".script = "builtin cd .. && zle reset-prompt";
      "^p".script = "builtin popd && zle reset-prompt";
      "^g^i".script = zle-run "git status -sb";
      "^g^a".script = zle-run "git add -p";

      # better history
      "^r".script = ''
        local selected
        selected=$(
          ${pkgs.gnused}/bin/sed 's/^: [0-9]*:[0-9]*;//; :a; /\\$/ { s/\\$//; N; ba }; s/\n/\r/g' "$HISTFILE" |
          ${pkgs.fzf}/bin/fzf --height 10 --reverse --exact \
            --no-sort --no-multi --no-info -q "$BUFFER" --tac \
            --bind 'tab:accept-non-empty' \
            --bind 'backward-eof:abort' |
          ${pkgs.coreutils}/bin/tr '\r' '\n'
        )
        local ret=$?
        if [[ "$ret" == 0 ]]; then
          BUFFER="$selected"
          CURSOR="$#BUFFER"
        fi
        zle redisplay
      '';

      # ~/src jumping
      "^h".script = ''
        local root
        root=""
        local candidate
        for candidate in \
          "$(${pkgs.coreutils}/bin/df . --output=target | ${pkgs.gnused}/bin/sed -n 2p)/src" \
          "$(${pkgs.coreutils}/bin/df . --output=target | ${pkgs.gnused}/bin/sed -n 2p)/go/src" \
          "$HOME/src"; do
          if [ -d "$candidate" ]; then
            root=$candidate
            break
          fi
        done
        [ -z "$root" ] && return

        selected=$(
          ${pkgs.findutils}/bin/find "$root" -mindepth 3 -maxdepth 3 -printf '%P\n' |
          ${pkgs.fzf}/bin/fzf --height 10 --reverse --exact \
            --no-sort --no-multi --no-info \
            --bind 'backward-eof:abort'
        )
        local ret=$?
        if [[ "$ret" == 0 ]]; then
          builtin cd "$root/$selected"
          zle reset-prompt
        else
          zle redisplay
        fi
      '';
    };

    initExtra = ''
      # Make sure the terminal is in application mode, when zle is
      # active. Only then are the values from $terminfo valid.
      if echoti smkx >&/dev/null; then
        function zle-line-init () { echoti smkx }
        function zle-line-finish () { echoti rmkx }
        zle -N zle-line-init
        zle -N zle-line-finish
      fi

      .hm.hook.chpwd() {
        # see https://github.com/desyncr/auto-ls/blob/master/auto-ls.zsh
        if ! zle || { [[ "$WIDGET" == accept-line ]] && [[ $#BUFFER -eq 0 ]] }; then
          zle && echo
          # don't show for cd that is not run by user
          ls --color=auto -FhH
        fi
      }
      autoload -U add-zsh-hook
      add-zsh-hook chpwd .hm.hook.chpwd

      cdnix() {
        if [ "$#" -ne 1 ]; then
          echo >&2 "Usage: cdnix PACKAGE"
          return 1
        fi
        cd $(nix build --no-link --print-out-paths -f '<nixpkgs>' "$1" | head -n1)
      }

      ##
      ## completion options
      ##
      zstyle ':completion:*' completer _complete _ignored
      zstyle ':completion:*' list-colors ""
      zstyle ':completion:*' matcher-list "m:{[:lower:]}={[:upper:]}"
      zstyle ':completion:*' menu select
      zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
      zstyle ':completion:*' rehash true
      zstyle ':completion:*:warnings' format "%B$fg[red]%}--- no match for: %b$fg[white]%d"

      ##
      ## prompt
      ##
      VIRTUAL_ENV_DISABLE_PROMPT=1
      .prompt.venv() {
        [[ -z "$VIRTUAL_ENV" ]] && return
        echo " %F{blue}venv%f"
      }

      .prompt.cwd() {
        if [[ "$PWD" -ef . ]]; then
          echo "%~"
          return
        fi
        echo "%F{black}%K{red}%~%f%k"
      }

      () {
        local leader='%(?,%F{green},%F{red})┃%f '
        local errno='%(?,,%B%F{red}$?%f%b )'
        local jobline='%(1j,%F{green}$(jobs -r | wc -l | sed "s/0//")&$(jobs -s | wc -l | sed "s/0//")%f ,)'

        PS1="
      $leader$errno\$(.prompt.cwd)\$(.prompt.venv)
      $leader$jobline%(!,%F{red}#%f,$) "

        PS2="... "
      }

      ##
      ## motd
      ##
      () {
        echo
        ${pkgs.fortune}/bin/fortune "$HOME/.local/fortunes" | ${pkgs.cowsay}/bin/cowsay -n
      }
    '';

    plugins = [
      {
        name = "async";
        src = inputs.mafredri-zsh-async;
      }
    ];
  };
}
