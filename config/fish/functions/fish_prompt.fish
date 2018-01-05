function fish_prompt --description 'Write out the prompt'
  set -l last_status $status

  if not set -q __fish_git_prompt_show_informative_status
      set -g __fish_git_prompt_show_informative_status 1
  end
  if not set -q __fish_git_prompt_hide_untrackedfiles
      set -g __fish_git_prompt_hide_untrackedfiles 1
  end

  if not set -q __fish_git_prompt_color_branch
      #set -g __fish_git_prompt_color_branch magenta --bold
      set -g __fish_git_prompt_color_branch "#0087ff" --bold
  end
  if not set -q __fish_git_prompt_showupstream
      set -g __fish_git_prompt_showupstream "informative"
  end
  if not set -q __fish_git_prompt_char_upstream_ahead
      set -g __fish_git_prompt_char_upstream_ahead "↑"
  end
  if not set -q __fish_git_prompt_char_upstream_behind
      set -g __fish_git_prompt_char_upstream_behind "↓"
  end
  if not set -q __fish_git_prompt_char_upstream_prefix
      set -g __fish_git_prompt_char_upstream_prefix ""
  end

  if not set -q __fish_git_prompt_char_stagedstate
      set -g __fish_git_prompt_char_stagedstate "●"
  end
  if not set -q __fish_git_prompt_char_dirtystate
      set -g __fish_git_prompt_char_dirtystate "✚"
  end
  if not set -q __fish_git_prompt_char_untrackedfiles
      set -g __fish_git_prompt_char_untrackedfiles "…"
  end
  if not set -q __fish_git_prompt_char_conflictedstate
      set -g __fish_git_prompt_char_conflictedstate "✖"
  end
  if not set -q __fish_git_prompt_char_cleanstate
      set -g __fish_git_prompt_char_cleanstate "✔"
  end

  if not set -q __fish_git_prompt_color_dirtystate
      set -g __fish_git_prompt_color_dirtystate "#ff5f00"
  end
  if not set -q __fish_git_prompt_color_stagedstate
      set -g __fish_git_prompt_color_stagedstate yellow
  end
  if not set -q __fish_git_prompt_color_invalidstate
      set -g __fish_git_prompt_color_invalidstate red
  end
  if not set -q __fish_git_prompt_color_untrackedfiles
      set -g __fish_git_prompt_color_untrackedfiles $fish_color_normal
  end
  if not set -q __fish_git_prompt_color_cleanstate
      set -g __fish_git_prompt_color_cleanstate green --bold
  end

  if not set -q __fish_prompt_normal
      set -g __fish_prompt_normal (set_color normal)
  end

  # PWD
  echo -n (prompt_pwd)

  set -l color_cwd
  set -l prefix
  set -l suffix
  switch "$USER"
      case root toor
          if set -q fish_color_cwd_root
              set color_cwd $fish_color_cwd_root
              set fish_cwd_suffix_color $fish_color_cwd_root
          else
              set color_cwd $fish_color_cwd
              set fish_cwd_suffix_color $fish_color_cwd
          end
          set suffix '#'
      case '*'
          set color_cwd $fish_color_cwd
          set fish_cwd_suffix_color $fish_color_cwd
          set suffix '$'
  end
  set suffix "❯"

  printf '%s ' (__fish_vcs_prompt)

  if not set -q fish_virtualenv_color
    set -g fish_virtualenv_color "#ffaf00" --bold
  end

  if set -q VIRTUAL_ENV
    set_color $fish_virtualenv_color
    printf '%s' (echo -n (basename "$VIRTUAL_ENV"))
    set_color normal
  end

  if not test $last_status -eq 0
      set_color $fish_color_error
      printf ' exitcode: %s' (echo $last_status)
  end

  set_color $fish_cwd_suffix_color

  printf "\n%s" (echo -n "$suffix ")

  set_color normal
end

function x_fish_right_prompt --description 'Write out the right prompt'
  set_color normal

  printf '%s ' (__fish_vcs_prompt)
end
