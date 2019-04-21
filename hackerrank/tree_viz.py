#!/usr/bin/env python3

# Help visualize [some?] binary tree exercise testcase input from
# Hackerrank challenges via GraphViz (or http://viz-js.com/)
#
# E.g., https://www.hackerrank.com/challenges/tree-top-view/problem


import fileinput

def build_tree(nodes):
    """Returns dictionary structure containing binary tree w/ simple insertion scheme:
        <= left
        > right
    """
    tree = {'root': nodes[0]}
    tree[nodes[0]] = {'left': -1, 'right': -1}
    for i in range(1,len(nodes)):
        x = nodes[i]                    # value to insert
        p = tree['root']                # current node (value) on tree
        # Find insertion point
        while 1:
            if (x <= p):
                if (tree[p]['left'] > -1):
                    p = tree[p]['left']
                else:                   # Insert left child
                    tree[p]['left'] = x
                    tree[x] = {'left': -1, 'right': -1}
                    break
            else:
                if (tree[p]['right'] > -1):
                    p = tree[p]['right']
                else:                   # Insert right child
                    tree[p]['right'] = x
                    tree[x] = {'left': -1, 'right': -1}
                    break
    return tree


def tree2graphviz(tree):
    """Output tree graphviz-compatible digraph syntax format, compatible w/
    Graphviz and [web interface] http://viz-js.com/

    Uses some [DOT language] binary tree formatting tips from:
    https://eli.thegreenplace.net/2009/11/23/visualizing-binary-trees-with-graphviz
    """
    idx = 0                             # null point index
    print('digraph tree {')
    print('        nodesep=0.8;')
    print('        ranksep=0.5;')
    print('        size="6,6";')
    print('        node [color=khaki, style=filled];')
    for k, v in tree.items():
        if (k == 'root'):
            continue
        if (v['left'] > -1):
            print('        "{}" -> "{}";'.format(k, v['left']))
        else:
            null_node = "null{}".format(idx)
            print('        {} [style=invis,label=""];'.format(null_node))
            print('        "{}" -> "{}";'.format(k, null_node))
            idx += 1
        if (v['right'] > -1):
            print('        "{}" -> "{}";'.format(k, v['right']))
        else:
            null_node = "null{}".format(idx)
            print('        {} [style=invis,label=""];'.format(null_node))
            print('        "{}" -> "{}";'.format(k, null_node))
            idx += 1
    print('}')


def main():
    """Testcase input on the hackerrank graph files I'm trying to parse is:

        Number of nodes
        node(0) node(1) node(2) node(3) ... node(N-1)  node(N)

    Assumptions:
        for all i;    node(i) is always >= 0
        for all i, j; node(i) != node(j)
    """
    [count_str, nodes_str] = fileinput.input()
    count = int(count_str.rstrip('\n'))
    assert count > 0, "?not valid testcase input?"

    nodes = [int(e) for e in nodes_str.split()]
    assert count == len(nodes), "?only {} nodes seen, should be {}".format(len(nodes), count)

    tree = build_tree(nodes)
    tree2graphviz(tree)


if __name__== "__main__":
    main()

