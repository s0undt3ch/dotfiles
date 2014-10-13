#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
    symlink-dotfiles.py
    ~~~~~~~~~~~~~~~~~~~

    Run this code to create all the symlinks to your home directory.
    NOTE: Remember to run this script as the user who's home directory
    you're trying to set up.
    WARNING: This is not a dotfiles maintainer script, it's just a litle
    helping hack.


    :codeauthor: :email:`Pedro Algarvio (pedro@algarvio.me)`
    :copyright: © 2012 by the UfSoft.org Team, see AUTHORS for more details.
    :license: BSD, see LICENSE for more details.
"""

import os
import shutil
import optparse
import subprocess

try:
    import jinja2
    HAS_JINJA = True
except ImportError:
    HAS_JINJA = False

HOME_DIR = os.path.expanduser('~')
DOTFILES_DIR = os.path.abspath(os.path.dirname(__file__))
GLOBAL_SKIPS = (
    'README.rst',
    'symlink-dotfiles.py',
    'vim/colortest.vim',
    'vim/.syntax',
    'update-dotfiles-submodules.sh'
)


def __skip_path(path):
    relative_path = os.path.relpath(path, DOTFILES_DIR).rstrip(os.sep)
    # Let's check for an exact or a `.startswith()` match
    for rule in GLOBAL_SKIPS:
        if relative_path == rule.rstrip(os.sep):
            # This is an exact match. Skip it!
            return True
        elif relative_path.startswith(rule.rstrip(os.sep)):
            # This is a `.startswith()` partial match. Skip it!
            return True
    return False


def symlink(source, dest, force=False):
    if __skip_path(source):
        # Return now if this meant to be skipped
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
        print 'Overwriting existing file...',
        if os.path.isdir(dest):
            shutil.rmtree(dest)
        else:
            os.unlink(dest)

    if not os.path.isdir(os.path.dirname(dest)):
        os.makedirs(os.path.dirname(dest))

    os.symlink(
        os.path.relpath(
            source,
            os.path.dirname(dest)
        ),
        dest
    )
    print 'OK!'


def symlink_fonts(opts):
    try:
        subprocess.call(['fc-cache', '-V'])
    except OSError:
        print 'The \'fc-cache\' binary is not found. Skip handling fonts...'
        return

    FONTS_CONF_DIR = os.path.join(
        HOME_DIR, '.config', 'fontconfig', 'conf.d'
    )

    if not os.path.isdir(FONTS_CONF_DIR):
        os.makedirs(FONTS_CONF_DIR)

    symlink(
        os.path.join(
            DOTFILES_DIR, 'config', 'fontconfig', 'conf.d', 'fonts.conf'
        ),
        os.path.join(
            FONTS_CONF_DIR, 'fonts.conf'
        ),
        opts.force
    )

    fontsdir = os.path.join(HOME_DIR, '.fonts')
    if not os.path.isdir(fontsdir):
        os.makedirs(fontsdir)

    for font in os.listdir(os.path.join(DOTFILES_DIR, 'fonts')):
        if font in ('original', 'private'):
            continue
        sfontpath = os.path.join(DOTFILES_DIR, 'fonts', font)
        dfontpath = os.path.join(fontsdir, font)
        symlink(sfontpath, dfontpath, opts.force)

    if opts.skip_fonts_cache:
        return

    print 'Regenerating fonts cache'
    subprocess.call(['fc-cache', '-vf'])


def symlink_vim(opts):
    # Symlink .vimrc
    symlink(
        os.path.join(DOTFILES_DIR, 'vimrc'),
        os.path.join(HOME_DIR, '.vimrc'),
        opts.force
    )
    HOME_DIR_VIM = os.path.join(HOME_DIR, '.vim')
    DOTFILES_DIR_VIM = os.path.join(DOTFILES_DIR, 'vim')
    # Symlink the .vim directory
    for fname in os.listdir(DOTFILES_DIR_VIM):
        spath = os.path.join(DOTFILES_DIR_VIM, fname)
        if os.path.isfile(spath):
            symlink(
                spath,
                os.path.join(HOME_DIR_VIM, fname),
                opts.force
            )
            continue
        # It's a directory, descent into it
        ddir = os.path.join(HOME_DIR_VIM, fname)
        sdir = os.path.join(DOTFILES_DIR_VIM, fname)
        if not __skip_path(sdir) and not os.path.exists(ddir):
            os.makedirs(ddir)
        for sname in os.listdir(sdir):
            symlink(
                os.path.join(sdir, sname),
                os.path.join(ddir, sname),
                opts.force
            )

   # Symlink the .vimrc.d directory
    HOME_DIR_VIMRC = os.path.join(HOME_DIR, '.vimrc.d')
    DOTFILES_DIR_VIMRC = os.path.join(DOTFILES_DIR, 'vimrc.d')
    if not os.path.isdir(HOME_DIR_VIMRC):
        os.makedirs(HOME_DIR_VIMRC)

    for fname in os.listdir(DOTFILES_DIR_VIMRC):
        spath = os.path.join(DOTFILES_DIR_VIMRC, fname)
        if os.path.isfile(spath):
            symlink(
                spath,
                os.path.join(HOME_DIR_VIMRC, fname),
                opts.force
            )
            continue

    # Setup the Powerline Configuration
    POWERLINE_SRC = os.path.join(
        DOTFILES_DIR, 'config', 'powerline'
    )
    POWERLINE_DEST = os.path.join(
        HOME_DIR, '.config', 'powerline'
    )
    if not os.path.isdir(POWERLINE_SRC):
        return

    if not os.path.isdir(POWERLINE_DEST):
        os.makedirs(POWERLINE_DEST)

    for fname in os.listdir(POWERLINE_SRC):
        spath = os.path.join(POWERLINE_SRC, fname)
        if os.path.isfile(spath):
            symlink(
                spath,
                os.path.join(POWERLINE_DEST, fname),
                opts.force
            )


def symlink_ssh(opts):
    dssh = os.path.join(HOME_DIR, '.ssh')
    if not os.path.exists(dssh):
        os.makedirs(dssh, 0700)
    for fname in os.listdir(os.path.join(DOTFILES_DIR, 'ssh')):
        symlink(
            os.path.join(DOTFILES_DIR, 'ssh', fname),
            os.path.join(dssh, fname),
            opts.force
        )
        os.chmod(os.path.join(dssh, fname), 0600)
    os.chmod(os.path.join(dssh), 0700)


def symlink_thunderbird(opts):
    source = os.path.join(DOTFILES_DIR, 'thunderbird')
    dest = os.path.join(HOME_DIR, '.thunderbird')

    if not os.path.isdir(dest):
        os.makedirs(dest)

    print 'Generating the HTML email signatures'
    subprocess.call([os.path.join(source, 'generate-signatures', 'generate-email-signatures.py')])
    for fname in os.listdir(source):
        if not fname.endswith('.html'):
            # We only want the signatures for now
            continue
        symlink(
            os.path.join(source, fname),
            os.path.join(dest, fname),
            opts.force
        )


def symlink_bin(opts):
    source = os.path.join(DOTFILES_DIR, 'bin')
    dest = os.path.join(HOME_DIR, 'bin')

    if not os.path.isdir(dest):
        os.makedirs(dest)

    for fname in os.listdir(source):
        symlink(
            os.path.join(source, fname),
            os.path.join(dest, fname),
            opts.force
        )


def symlink_single_files(opts):
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
        symlink(spath, dpath, opts.force)


def symlink_bashrcd(opts):
    bashrcd_source = os.path.join(DOTFILES_DIR, 'bashrc.d')
    bashrcd_dest = os.path.join(HOME_DIR, '.bashrc.d')
    if not os.path.isdir(bashrcd_dest):
        os.makedirs(bashrcd_dest)

    dont_sync_fnames = ()
    for fname in os.listdir(bashrcd_source):
        spath = os.path.join(bashrcd_source, fname)
        if fname in dont_sync_fnames or fname in GLOBAL_SKIPS:
            continue
        elif fname.startswith('.'):
            continue
        elif not os.path.isfile(spath):
            continue
        dpath = os.path.join(bashrcd_dest, fname)
        symlink(spath, dpath, opts.force)


def symlink_config(opts):
    source = os.path.join(DOTFILES_DIR, 'config')
    dest = os.path.join(HOME_DIR, '.config')
    if not os.path.isdir(dest):
        os.makedirs(dest)

    dont_sync_fnames = ()
    for fname in os.listdir(source):
        spath = os.path.join(source, fname)
        if fname in dont_sync_fnames or fname in GLOBAL_SKIPS:
            continue
        elif fname.startswith('.'):
            continue
        elif os.path.isdir(spath):
            dest_dir_path = os.path.join(dest, fname)
            if not os.path.isdir(dest_dir_path):
                os.makedirs(dest_dir_path)
            for fname in os.listdir(spath):
                dpath = os.path.join(dest_dir_path, fname)
                symlink(spath, dpath, opts.force)
            continue
        dpath = os.path.join(dest, fname)
        symlink(spath, dpath, opts.force)


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
    if HAS_JINJA:
        parser.add_option(
            '-E', '--email-signatures',
            action='store_true',
            default=False,
            help='Generate the email signatures'
        )
    (options, args) = parser.parse_args()
    if args:
        parser.error('No arguments are supported')
    symlink_fonts(options)
    symlink_vim(options)
    symlink_ssh(options)
    symlink_single_files(options)
    symlink_bashrcd(options)
    if HAS_JINJA and options.email_signatures:
        symlink_thunderbird(options)
    symlink_bin(options)
    symlink_config(options)


# vim: sw=4 ts=4 fenc=utf-8 et spell spelllang=en
