#!/usr/bin/env python3

from pathlib import Path
import asyncio
import datetime as dt
import itertools
import os
import random
import sys

_has_pandas = False
try:
    import pandas as pd
    _has_pandas = True
except ImportError:
    pass

_has_numpy = False
try:
    import numpy as np
    _has_numpy = True
except ImportError:
    pass

try:
    from tqdm.auto import tqdm
except ImportError:
    pass
else:
    if _has_pandas:
        tqdm.pandas()

try:
    import plotly.express as px
except ImportError:
    pass
