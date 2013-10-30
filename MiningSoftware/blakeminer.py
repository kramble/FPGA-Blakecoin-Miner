#!/usr/bin/env python

# by teknohog

# Python wrapper for Xilinx Serial Miner

# CONFIGURATION - SOLO MINING via blakecoind
host = "localhost"	# Set hostname here (usually localhost)
user = "username"
password = "password"
http_port = "8772"	# Getwork port

# CONFIGURATION - CHANGE THIS (eg try COM1, COM2, COM3, COM4 etc)
serial_port = "COM4"
# serial_port = "/dev/ttyUSB0"	# raspberry pi

# CONFIGURATION - how often to refresh work
askrate = 1						# 800Mhash/S needs frequent getwork to avoid rehashing old work

###############################################################################

from jsonrpc import ServiceProxy
from time import ctime, sleep, time
from serial import Serial
from threading import Thread, Event
from Queue import Queue
import sys
import subprocess
import os
import struct
from ctypes import *
from binascii import hexlify, unhexlify
from blake8 import BLAKE as BLAKE

dynclock = 0
dynclock_hex = "0000"

def stats(count, starttime, hw_err):
	# BTC 2**32 hashes per share (difficulty 1)
	# mhshare = 4294.967296
	# LTC 2**32 / 2048 hashes per share (difficulty 32)
	# khshare = 2097.152	# CHECK THIS !!
	khshare = 65.536 * writer.diff

	s = sum(count)
	tdelta = time() - starttime
	rate = s * khshare / tdelta

	# This is only a rough estimate of the true hash rate,
	# particularly when the number of events is low. However, since
	# the events follow a Poisson distribution, we can estimate the
	# standard deviation (sqrt(n) for n events). Thus we get some idea
	# on how rough an estimate this is.

	# s should always be positive when this function is called, but
	# checking for robustness anyway
	if s > 0:
		stddev = rate / s**0.5
	else:
		stddev = 0

	# return "[%i accepted, %i failed, %.2f +/- %.2f khash/s]" % (count[0], count[1], rate, stddev)
	return "%i accepted, %i failed, %d errors" % (count[0], count[1], hw_err)	# Rate calcs invalid for BLAKE

class Reader(Thread):
	def __init__(self):
		Thread.__init__(self)

		self.daemon = True

		# flush the input buffer
		ser.read(1000)

	def run(self):
		while True:
			nonce = ser.read(4)

			if len(nonce) == 4:
				# Keep this order, because writer.block will be
				# updated due to the golden event.
				submitter = Submitter(writer.block, nonce)
				submitter.start()
				golden.set()


class Writer(Thread):
	def __init__(self,dynclock_hex):
		Thread.__init__(self)

		# Keep something sensible available while waiting for the
		# first getwork
		self.block = "0" * 256
		# self.target = "f" * 56 + "ff070000"		# diff=32
		self.target = "f" * 56 + "ff7f0000"			# diff=2
		self.diff = 2.0	# NB This is updated from target (default 2 is safer than 32 to avoid losing shares)
		self.dynclock_hex = dynclock_hex

		self.daemon = True

	def run(self):
		while True:
			try:
				work = bitcoin.getwork()
				self.block = work['data']
				self.target = work['target']
			except:
				print("RPC getwork error")
				# In this case, keep crunching with the old data. It will get 
				# stale at some point, but it's better than doing nothing.

			# print("block " + self.block + " target " + self.target)	# DEBUG

			# Target is unused in BLAKE so just disable warnings for now
			sdiff = self.target.decode('hex')[31:27:-1]
			intTarget = int(sdiff.encode('hex'), 16)
			if (intTarget < 1):
				#print "WARNING zero target, defaulting to diff=2", intTarget
				#print "target", self.target
				#print("sdiff", sdiff)	# NB Need brackets here else prints binary
				self.target = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f0000"
			else:
				newdiff = 65536.0 / (intTarget+1)
				# if (self.diff != newdiff):
				#	print "New target diff =", newdiff
				self.diff = newdiff

			# Replace MSB 16 bits of target with clock (NB its reversed)
			self.target = self.target[0:60] + self.dynclock_hex
			self.dynclock_hex = "0000"	# Once only
			
			# print("Sending data to FPGA")	# DEBUG
			
			midstate_blake8 = BLAKE(256).midstate(struct.pack("<16I", *struct.unpack(">16I", self.block.decode('hex')[:64])))
			# print('midstate_blake8 %s' % (hexlify(midstate_blake8).decode()))
			midstate_blake8_swap = struct.pack("<8I", *struct.unpack(">8I", midstate_blake8))
			# print('midswap_blake8  %s' % (hexlify(midstate_blake8_conv).decode()))

			midstate = hexlify(midstate_blake8_swap)
				
			# for blakecoin send 16 bytes data plus midstate plus 4 bytes of 32 byte target (used for dynclock only)
			payload = self.target.decode('hex')[31:27:-1] + self.block.decode('hex')[79:63:-1] + midstate.decode('hex')[::-1] 
			
			# print("Payload " + payload.encode('hex_codec'))	# DEBUG
			
			ser.write(payload)
			
			result = golden.wait(askrate)

			if result:
				golden.clear()

class Submitter(Thread):
	def __init__(self, block, nonce):
		Thread.__init__(self)

		self.block = block
		self.nonce = nonce

	def run(self):
		# This thread will be created upon every submit, as they may
		# come in sooner than the submits finish.

		# print("Block found on " + ctime())
		print("Share found on " + ctime() + " nonce " + self.nonce.encode('hex_codec'))
		sys.stdout.flush()	
		hrnonce = self.nonce[::-1].encode('hex')

		data = self.block[:152] + hrnonce + self.block[160:]
		sys.stdout.flush()
		
		hash_blake8 = BLAKE(256).digest(struct.pack("<20I", *struct.unpack(">20I", data.decode('hex')[:80])))
		hash_str = hexlify(hash_blake8).decode()
		print('hash %s' % hash_str)
		
		if (os.name == "nt"):
			os.system ("echo checkblake " + data + ">>logmine-ms.log")		# Log file is runnable (rename .BAT)
		else:
			os.system ("echo ./checkblake " + data + ">>logmine-ms.log")	# Log file is runnable as a shell script

		# Uncomment ONE of the following to configure
		if (hash_str[56:64] == "00000000"):		# Submit diff=1 shares (POOL mining)
		# if (hash_str[55:64] == "000000000"):	# Only submit diff=16 shares to reduce blakecoind loading
		# if (hash_str[54:64] == "0000000000"):	# Only submit diff=256 shares to reduce blakecoind loading
			try:
				print ("submitting " + data)
				result = bitcoin.getwork(data)
				print("Upstream result: " + str(result))
			except:
				print("RPC send error")
				result = False
		else:
			if (hash_str[56:64] == "00000000"):		# Submit diff=1 shares (POOL mining)
				print ("Share not submitted")
			else:
				print ("HARDWARE ERROR INVALID HASH")
				disp.hw_err = disp.hw_err + 1		# Probably needs some sort of lock, should use results_queue instead
			result = False

		sys.stdout.flush()	
		results_queue.put(result)

class Display_stats(Thread):
	def __init__(self):
		Thread.__init__(self)

		self.count = [0, 0]
		self.starttime = time()
		self.hw_err = 0
		self.daemon = True

		print("Miner started on " + ctime())
		sys.stdout.flush()	

	def run(self):
		while True:
			result = results_queue.get()
			
			if result:
				self.count[0] += 1
			else:
				self.count[1] += 1
				
			print(stats(self.count, self.starttime, self.hw_err))
			sys.stdout.flush()	
				
			results_queue.task_done()

# ======= main =======

# Process command line

if (len(sys.argv) > 2):
	print "ERROR too many command line arguments"
	print "usage:", sys.argv[0], "clockfreq"
	quit()

if (len(sys.argv) == 1):
	print "WARNING no clockfreq supplied, not setting freq"
else:
	# TODO ought to check the value is a valid integer
	try:
		dynclock = int(sys.argv[1])
	except:
		print "ERROR parsing clock frequency on command line, needs to be an integer"
		print "usage:", sys.argv[0], "clockfreq"
		quit()
	if (dynclock==0):
		print "ERROR parsing clock frequency on command line, cannot be zero"
		print "usage:", sys.argv[0], "clockfreq"
		quit()
	if (dynclock>254):	# Its 254 since onescomplement(255) is zero, which is not allowed
		print "ERROR parsing clock frequency on command line, max 254"
		print "usage:", sys.argv[0], "clockfreq"
		quit()
	dynclock_hex = "{0:04x}".format((255-dynclock)*256+dynclock)	# both value and ones-complement
	print "INFO will set clock to", dynclock, "MHz hex", dynclock_hex

golden = Event()

url = 'http://' + user + ':' + password + '@' + host + ':' + http_port

bitcoin = ServiceProxy(url)

results_queue = Queue()

# default is 8 bit no parity which is fine ...
# http://pyserial.sourceforge.net/shortintro.html#opening-serial-ports

ser = Serial(serial_port, 115200, timeout=askrate)

reader = Reader()
writer = Writer(dynclock_hex)
disp = Display_stats()

reader.start()
writer.start()
disp.start()

try:
	while True:
		# Threads are generally hard to interrupt. So they are left
		# running as daemons, and we do something simple here that can
		# be easily terminated to bring down the entire script.
		sleep(10000)
except KeyboardInterrupt:
	print("Terminated")

