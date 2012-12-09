#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
    symlink-dotfiles.py
    ~~~~~~~~~~~~~~~~~~~

    Run this code to create all the symlinks to your home directory.
    NOTE: Remember to run this script as the users you desire to setup.
    WARNING: This is not a dotfiles maintainer, it's just a litle helping hack.


    :codeauthor: :email:`Pedro Algarvio (pedro@algarvio.me)`
    :copyright: © 2012 by the UfSoft.org Team, see AUTHORS for more details.
    :license: BSD, see LICENSE for more details.
"""

import os
import shutil
import optparse
import subprocess

DOTFILES_DIR = os.path.abspath(os.path.dirname(__file__))
HOME_DIR = os.path.expanduser('~')
GLOBAL_SKIPS = (
    'README.rst',
    'symlink-dotfiles.py',
    'vim/colortest.vim',
    'vim/.syntax'
)


def symlink(source, dest, force=False):
    if os.path.relpath(source, DOTFILES_DIR) in GLOBAL_SKIPS:
        return

    print 'Linking {0} -> {1} ...'.format(source, dest),
    if os.path.lexists(dest) and not force:
        # There's already a link and we're not forcing overwrite
        print 'Skipped. Not overwriting link'
        return
    elif os.path.lexists(dest) and os.path.islink(dest) and force:
        os.unlink(dest)
    elif os.path.exists(dest) and not os.path.islink(dest) and not force:
        print 'Skipped. Real file not overwritten'
        return
    elif os.path.exists(dest) and not os.path.islink(dest) and force:
        print 'Overwriting existint file...',
        if os.path.isdir(dest):
            shutil.rmtree(dest)
        else:
            os.unlink(dest)

    os.symlink(
        os.path.relpath(
            source,
            os.path.dirname(dest)
        ),
        dest
    )
    print 'OK!'


def symlink_fonts(force=False, skip_fonts_cache=False):
    fontsdir = os.path.join(HOME_DIR, '.fonts')
    if not os.path.isdir(fontsdir):
        os.makedirs(fontsdir)

    for font in os.listdir(os.path.join(DOTFILES_DIR, 'fonts')):
        sfontpath = os.path.join(DOTFILES_DIR, 'fonts', font)
        dfontpath = os.path.join(fontsdir, font)
        symlink(sfontpath, dfontpath, force)

    if skip_fonts_cache:
        return

    print 'Regenerating fonts cache'
    subprocess.call(['fc-cache', '-vf'])


def symlink_vim(force=False):
    # Symlink .vimrc
    symlink(
        os.path.join(DOTFILES_DIR, 'vimrc'),
        os.path.join(HOME_DIR, '.vimrc'),
        force
    )
    HOME_DIR_VIM = os.path.join(HOME_DIR, '.vim')
    DOTFILES_DIR_VIM = os.path.join(DOTFILES_DIR, 'vim')
    # Symlink the .vim direectory
    for fname in os.listdir(DOTFILES_DIR_VIM):
        spath = os.path.join(DOTFILES_DIR, 'vim', fname)
        if os.path.isfile(spath):
            symlink(spath, os.path.join(HOME_DIR_VIM, fname))
            continue
        ddir = os.path.join(HOME_DIR_VIM, fname)
        sdir = os.path.join(DOTFILES_DIR_VIM, fname)
        if not os.path.exists(ddir):
            os.makedirs(ddir)
        for sname in os.listdir(sdir):
            symlink(
                os.path.join(sdir, sname),
                os.path.join(ddir, sname),
                force
            )


def symlink_ssh(force):
    dssh = os.path.join(HOME_DIR, '.ssh')
    if not os.path.exists(dssh):
        os.makedirs(dssh, 0700)
    for fname in os.listdir(os.path.join(DOTFILES_DIR, 'ssh')):
        symlink(
            os.path.join(DOTFILES_DIR, 'ssh', fname),
            os.path.join(dssh, fname),
            force
        )


def symlink_single_files(force=False):
    dont_sync_fnames = ('vimrc',)
    for fname in os.listdir(DOTFILES_DIR):
        spath = os.path.join(DOTFILES_DIR, fname)
        if fname in dont_sync_fnames:
            continue
        elif not os.path.isfile(spath):
            continue
        elif fname.startswith('.'):
            continue
        dpath = os.path.join(HOME_DIR, '.{0}'.format(fname))
        symlink(spath, dpath, force)


if __name__ == '__main__':
    parser = optparse.OptionParser(
        description=' '.join([
            l.strip() for l in __doc__.split('\n\n')[1].splitlines()
        ])
    )
    parser.add_option(
        '-F', '--force',
        action='store_true',
        default=False,
        help='Force symlinks on existing resources'
    )
    parser.add_option(
        '-S', '--skip-fonts-cache',
        action='store_true',
        default=False,
        help='Skip regenerating fonts cache'
    )
    (options, args) = parser.parse_args()
    if args:
        parser.error('No arguments are supported')
    symlink_fonts(
        force=options.force, skip_fonts_cache=options.skip_fonts_cache
    )
    symlink_vim(force=options.force)
    symlink_ssh(force=options.force)
    symlink_single_files(force=options.force)
