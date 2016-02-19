#!/usr/bin/env python
#-*- coding: UTF-8 -*-

# autor: Ignacio Gilbaja
# date: 2015-04-30
# mail: jose-ignacio.gilbaja@deimos-space.com
# version 1.0: simple frame sender for WRC kyros
# version 1.1: now date, several devices features

from multiprocessing import Process, Queue
import fileinput
import time
import socket
import sys
import logging, logging.handlers
import os
from random import randint

FREQUENCY = 15

INTERNAL_LOG = "/tmp/correos-simulator.log"
#FRAME = "2003902205,20160208095338,-70.829691,43.487751,75,118,0,9,2,0.0,1,14.69,0.01,0,0,0"
FRAME = "imei,date,lon,lat,75,118,0,9,2,0.0,1,14.69,0.01,0,0,0"

IP = "172.26.30.210"
PORT = 6000

########################################################################

# definimos los logs internos que usaremos para comprobar errores
log_folder = os.path.dirname(INTERNAL_LOG)

if not os.path.exists(log_folder):
        os.makedirs(log_folder)

try:
        logger = logging.getLogger('correos-simulator')
        loggerHandler = logging.handlers.TimedRotatingFileHandler(INTERNAL_LOG , 'midnight', 1, backupCount=10)
        formatter = logging.Formatter('%(asctime)s %(levelname)s %(message)s')
        loggerHandler.setFormatter(formatter)
        logger.addHandler(loggerHandler)
        logger.setLevel(logging.DEBUG)
except:
        print '------------------------------------------------------------------'
        print '[ERROR] Error writing log at %s' % INTERNAL_LOG
        print '[ERROR] Please verify path folder exits and write permissions'
        print '------------------------------------------------------------------'
        exit()


########################################################################

#print time.strftime("%H%M%S")

def sendData(data):
	conn = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	try:
		conn.connect((IP,PORT))
		conn.send(data)
		print "Sent: " + data
	except Exception, error:
		print "Error sending data: " + str(error)


def help():
	print ""
	print "usage: ./correos-simulator imeis=<imeis-file> positions=<positions-file>"
	print ""
	print "--imeis-file: complete path to imeis file. If log file is at same folder as simulator only file name is required."
	print "--positions-file: complete path to positions file. If log file is at same folder as simulator only file name is required."
	print ""
	print "example: ./correos-simulator imeis=imeis.txt positions=/tmp/positions.txt"
	print ""
	sys.exit(0)

def parserImeis(params):
	try:
		if params.split("=")[1] == '':
			print "Error parsing imeis file!!"
			help()
		else:
			imeisFile = params.split("=")[1]
			imei=[]
			imeis = open(imeisFile)
			for line in imeis:
				imei.append(line.split("\n")[0])
		return imei
	except Exception, error:
		print "Error managing imeis file: %s" % error
		logger.error('Error parsing imeis: %s', error)
		help()
	

def parserPositions(params):
	try:
		if params.split("=")[1] == '':
			print "Error parsing positions file!!"
			help()
		else:
			positionsFile = params.split("=")[1]
			position=[]
			positions = open(positionsFile)
			for line in positions:
				position.append(line.split("\r\n")[0])
		return position
	except Exception, error:
		print "Error managing positions file: %s" % error
		logger.error('Error parsing positions: %s', error)
		help()


def worker(imei, positions, connection):
	print '---> Started process %d for vehicle %s' % (os.getpid(), imei)
	for position in positions:
		date = time.strftime("%Y%m%d%H%M%S")
		random = float(randint(1000, 9999))/100000
		lat = str(float (position.split(",")[0]) + random)
		lon = str(float (position.split(",")[1]) + random)
		frame = FRAME.replace("imei",imei).replace("date",date).replace("lon",lon).replace("lat",lat)
		connection.send(frame)
		logger.info('[%s][%s] sent: %s' , os.getpid(), imei, frame)
		print '[%s][%s] sent: %s' % (os.getpid(), imei, frame)
		time.sleep(FREQUENCY)
			
def main():
	if (len(sys.argv) == 3):
		
		imeis = parserImeis(sys.argv[1])
		vehicleCount = len(imeis)
		
		positions = parserPositions(sys.argv[2])
		positionCount = len(positions)
		
		print ""
		print "##################################################################"
		print " Starting correos simulation with next parameters:"
		print " Vehicles found at imeis file: " + str(vehicleCount)
		print " Positions found at positions file: " + str(positionCount)
		print " Time between frames sent : %d seconds" % FREQUENCY
		print " Total positions for simulation: %d" % (vehicleCount * positionCount)
		print "##################################################################"
		print ""
		
		time.sleep(1)
		
		connection = {}
		for imei in imeis:
			conn = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
			conn.connect((IP,PORT))
			print "Connection stablished for vehicle with imei %s..." % imei
			connection[imei]=conn
			#time.sleep(0.1)
			
		processes = []
		print "Starting processes for simulate every vehicle..."
		for i in range (vehicleCount):
			processes.append(Process(target=worker, args=(imeis[i], positions, connection[imeis[i]])))
			processes[i].start()
		for process in processes:
			process.join()

	else:
		help()

if __name__ == '__main__':
    main()
