#!/usr/bin/env python

import r2pipe
from json import loads

r = r2pipe.open('bomb')

# Define binary tree structure
struct_btree = """\"td struct btree {int32_t content; struct btree *left; struct btree *right;} btree;\"
"""

r.cmd(struct_btree)

# Generate print formats from type
fmt = r.cmd('t btree').rstrip().split(' ')
fmt.pop(0)


def node_get(location):
    return loads(r.cmd(f'pfj {" ".join(fmt)} @ {location}'))


def node_print(node, indent = 0, label='─>'):
    content = 0
    left = 0
    right = 0

    for member in node:
        name = member['name']
        value = member['value']

        if name == 'content':
            content = int(value)
        elif name == 'left':
            left = int(value)
        elif name == 'right':
            right = int(value)

    if left != 0:
        node_print(node_get(left), indent + 1, '┌>')

    padding = indent * 3 * ' '

    print(f'{padding}{label} {content}')

    if right != 0:
        node_print(node_get(right), indent + 1, '└>')


root = node_get('obj.n1')

node_print(root)
