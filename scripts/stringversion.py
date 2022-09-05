#!/bin/env python

import sys
from portage.dep import Atom

for arg in sys.argv[1:]:
	atom = Atom(arg)
	print(atom.cp)


# https://github.com/graaff/ruby-tinderbox/blob/master/bin/packages.py
