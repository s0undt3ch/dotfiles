if test -d ~/.dotfiles/.ext/pyenv
    # If the pyenv checkout exists, update environment
    set -U --export PYENV_ROOT ~/.dotfiles/.ext/pyenv
    string match -q ~/.dotfiles/.ext/pyenv/bin $PATH; or set -gx PATH ~/.dotfiles/.ext/pyenv/bin $PATH
    string match -q ~/.dotfiles/.ext/pyenv/shims $PATH; or set -gx PATH ~/.dotfiles/.ext/pyenv/shims $PATH

    set -x PYENV_SHELL fish
    set -x PYTHONIOENCODING "UTF-8"
    set -x PYTHON_CONFIGURE_OPTS "--enable-shared"

    set --export VIRTUAL_ENV_DISABLE_PROMPT 1
    status --is-interactive; and source (pyenv init -|psub)
    status --is-interactive; and source (pyenv virtualenv-init -|psub)
end
