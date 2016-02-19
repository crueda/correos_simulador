#!/usr/bin/env python
#-*- coding: UTF-8 -*-

import fileinput
import time

imeis = [format(item, "03d") for item in xrange(801)]

with open('imeis.txt', 'a') as imeisFile:
	for imei in imeis:
		imeisFile.write("2000000"+ imei + "\n")
