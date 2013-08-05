# -*- coding: utf-8 -*-
'''
    generate-email-signatures.py
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    Generate HTML Signatures

    :codeauthor: :email:`Pedro Algarvio (pedro@algarvio.me)`
    :copyright: © 2013 by the UfSoft.org Team, see AUTHORS for more details.
    :license: BSD, see LICENSE for more details.
'''

# Import python libs
import os
import sys
import json
from jinja2 import Environment, FileSystemLoader


def url_to_image_data(fname):
    data_template = 'data:image/{0};base64,{1}'
    return data_template.format(
        fname.rsplit('.', 1)[-1],
        open(os.path.abspath(fname), 'rb').read().encode('base64').replace('\n', '')
    )

jinja2env = Environment(
    loader=FileSystemLoader(
        os.path.join(
            os.path.dirname(__file__), 'templates'
        )
    ),
    trim_blocks=True
)
jinja2env.filters['b64data'] = url_to_image_data

signatures_data = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    'signatures-data.json'
)
output_directory = os.path.dirname(
    os.path.dirname(
        os.path.abspath(__file__)
    )
)

for fname, details in json.loads(open(signatures_data).read()).iteritems():
    open(os.path.join(output_directory, fname), 'w').write(
        jinja2env.get_template('layout.html').render(
            name=details['name'],
            avatar=details['avatar'],
            contacts=details['contacts'],
            gittip=details.get('gittip', None)
        )
    )
