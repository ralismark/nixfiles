{ config, lib, pkgs, ... }:
let
  tmux-bin = "${config.programs.tmux.package}/bin/tmux";
  gui-clip = {
    copy = "${pkgs.wl-clipboard}/bin/wl-copy";
    paste = "${pkgs.wl-clipboard}/bin/wl-paste";
  };

  map-lines = list: fn: lib.concatStringsSep "\n" (map fn list);
in
{
  programs.tmux = {
    enable = true;

    baseIndex = 1; # 1-index windows so it lines up with keys
    escapeTime = 10; # make esc key work
    keyMode = "vi";
    prefix = "M-w";
    secureSocket = false; # avoid the global env var

    extraConfig = ''
      #
      # Options
      #
      setw -g mode-keys vi # Vi copy mode
      set -g mouse on # Mouse control
      set -g default-command "''${SHELL}"

      # copy stuff
      set-option -s set-clipboard off
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "${gui-clip.copy}"
      bind-key p run "${gui-clip.paste} | ${tmux-bin} load-buffer - ; ${tmux-bin} paste-buffer"
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "${gui-clip.copy}"
      bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "${gui-clip.copy}"

      # Term support
      # TODO what does this do?
      set -ag terminal-overrides ',*:Ss=\E[%p1%d q:Se=\E[2 q'
      set -as terminal-features ",*:Tc,*:RGB"

      #
      # Bindings
      #
      bind - split-window -v
      bind | split-window -h

      # switch windows alt+number
      ${map-lines (map builtins.toString (lib.range 1 9)) (i: ''
        bind-key -n M-${i} if-shell '${tmux-bin} select-window -t :${i}' "" 'new-window -t :${i}; select-window -t ${i}'
      '')}
      bind-key -n M-0 if-shell '${tmux-bin} select-window -t :10' "" 'new-window -t :10; select-window -t 10'

      bind -n M-h select-pane -L
      bind -n M-j select-pane -D
      bind -n M-k select-pane -U
      bind -n M-l select-pane -R
      bind H move-pane -fhb -t "{left}"
      bind J move-pane -fv  -t "{bottom}"
      bind K move-pane -fvb -t "{top}"
      bind L move-pane -fh  -t "{right}"

      #
      # Styling
      #
      set -g status-justify centre
      set -g status-position bottom
      set -g status-left ""
      set -g status-right ""
      set -g status-style 'bg=color53'
      setw -g window-status-separator ""
      setw -g window-status-format '#[fg=color53]#[default] #I:#W #[fg=color53]#[default]'
      setw -g window-status-style 'fg=white'
      setw -g window-status-current-format '#[fg=color53]#[default] #I:#W #[fg=color53]#[default]'
      setw -g window-status-current-style 'bg=terminal fg=terminal'
      setw -g monitor-bell on
      setw -g window-status-activity-style 'bg=color126'

      set -g set-titles on # set window titles
      set -g set-titles-string '#S:#W'
    '';
  };
}
