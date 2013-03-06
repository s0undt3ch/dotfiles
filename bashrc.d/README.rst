The files found within this directory should be automaticaly sourced by ``~/.bash_aliases``.

If the above did not happen to you, in order to source the files contained in this directory
append to your bashrc file the following:

.. code-block:: bash

    # Source any files found under ~/.bashrc.d
    if [ -d ~/.bashrc.d ]; then
        for f in $(ls ~/.bashrc.d/*.sh ); do
            . ${f}
        done
    fi
