# vim: ft=zsh ts=2 sts=2 et

_zsh_pyenv_load() {
  export PYTHONIOENCODING="UTF-8"
  export PYTHON_CONFIGURE_OPTS="--enable-shared"
  export VIRTUAL_ENV_DISABLE_PROMPT=1
  eval "$(pyenv init --path)"
  eval "$(pyenv init - --no-rehash zsh)"
  eval "$(pyenv virtualenv-init - zsh)"
}

if command -v pyenv &>/dev/null; then
  _zsh_pyenv_load
fi
