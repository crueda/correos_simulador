#!/usr/bin/env python
#-*- coding: UTF-8 -*-

# autor: Ignacio Gilbaja
# date: 2015-04-30
# mail: jose-ignacio.gilbaja@deimos-space.com
# version 1.0: simple frame sender for WRC kyros
# version 1.1: now date, several devices features


from random import randint

base = "1.0000"
red = float(randint(1000, 9999))/100000



print "%.6f" % (float(base)+red)



