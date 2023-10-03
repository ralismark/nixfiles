#!/usr/bin/env python3

from IPython.core.magic import register_line_magic

@register_line_magic
def rewind(s=''):
    """attempt to reset IPython to an earlier state

    implemented by resetting IPython, and replaying the
    history up to (but not including) the specified index.
    """

    ip = get_ipython()

    if s:
        stop = min(int(s), ip.execution_count)
    else:
        # backup 1 by default
        stop = ip.execution_count-1
    # fetch the history
    hist = list(ip.history_manager.get_range(stop=stop))
    # reset IPython
    ip.reset()
    ip.execution_count=0
    # replay the history
    for _,i,cell in hist:
        ip.run_cell(cell, store_history=True)

del rewind
