from IPython import get_ipython
ipython = get_ipython()

ipython.run_line_magic("autoreload", "2")

import logging
logging.basicConfig(
    format="%(asctime)s.%(msecs)03d [%(levelname)s] [%(name)s:%(lineno)d] %(message)s",
    datefmt="%Y%m%d:%H:%M:%S",
    level=logging.INFO,
)
