#!/usr/bin/env python


intro = """
    blake_test.py
    version 4
    
    This program tests blake.py individually and against a C 
    reference implementation wrapped with blake_wrapper.py.  
    It works for both Python2 and Python3.
        
      Copyright (c) 2009-2012 by Larry Bugbee, Kent, WA
      ALL RIGHTS RESERVED.
      
      blake_test.py IS EXPERIMENTAL SOFTWARE FOR EDUCATIONAL
      PURPOSES ONLY.  IT IS MADE AVAILABLE "AS-IS" WITHOUT 
      WARRANTY OR GUARANTEE OF ANY KIND.  ITS USE SIGNIFIES 
      FULL ACCEPTANCE OF ALL RISK, UNDER ALL CIRCUMSTANCES, NO 
      EXCEPTIONS.

    To make your learning and experimentation less cumbersome, 
    blake_test.py is free for any use.      
    
    
    Enjoy,
        
    Larry Bugbee
    April 2012
    
"""


import sys
import struct
from ctypes import *
from binascii import hexlify, unhexlify

_version = '1'


# import two modules with identical class and method names, but
# keep them individually identifiable
have_blake = False
have_blake_wrapper = False

try:
	from blake8 import BLAKE as BLAKEpy
	have_blake = True
except:
	print('\n   *** unable to import blake8.py *** \n')


#---------------------------------------------------------------
# test vectors

def basic_tests():

	def test_BLAKE(hashlen, msg, expect):
		#HMMM This gives UnicodeDecodeError: 'ascii' codec can't decode byte 0xdc in position 36: ordinal not in range(128)
		#print('      BLAKE-%d:  msg = %s  length = %d' % 
		#						(hashlen, msg.decode(), len(msg)))
		digest = BLAKE(hashlen).digest(msg)
		print('        %s %s' % ('valid    ' if digest == unhexlify(expect)
								else 'ERROR >>>', hexlify(digest).decode()))

	if 1:
		# Genesis block
		msgin = b'000000700000000000000000000000000000000000000000000000000000000000000000f8206ddc46aeec7ff4d88417ed10ac1757761d06c3dbbaeebb91c7239e4654d55250f3111e00ffff0792bdff000000800000000000000000000000000000000000000000000000000000000000000000010000000000000080020000'
		
		# From MPBM job.py
		# return struct.pack("<8I", *struct.unpack(">8I", SHA256.hash(struct.pack("<16I", *struct.unpack(">16I", data[:64])), False)))
		# return sha256(sha256(struct.pack("<20I", *struct.unpack(">20I", data[:80]))).digest()).digest()

		data = msgin.decode('hex')		# Either of these work OK
		# data = unhexlify(msgin)

		msg = struct.pack("<20I", *struct.unpack(">20I", data[:80]))

		# The original test (works)
		hashlen = 256
		expect = (b'be39762c0b8042bbc6394b23d7965d4e42c34cf823b8a2b14846ae5cba000000')
		test_BLAKE(hashlen, msg, expect)
		
		# Standalone invocation
		digest = BLAKE(256).digest(msg)
		print('hash     %s' % (hexlify(digest).decode()))
		
		# Midstate
		midmsg = struct.pack("<16I", *struct.unpack(">16I", data[:64]))
		digest = BLAKE(256).midstate(midmsg)
		print('midstate %s' % (hexlify(digest).decode()))					# This is the wrong-endian cf midstate.c
		midconv = struct.pack("<8I", *struct.unpack(">8I", digest))
		print('midconv  %s' % (hexlify(midconv).decode()))					# This matches midstate.c

#--------------------------------------------------------------------------
#--------------------------------------------------------------------------

if have_blake:
	# testing blake.py independently
	BLAKE      = BLAKEpy
	print('\n  Testing blake8.py:')
	print(  '  -----------------')
	basic_tests()

print('Done')


#--------------------------------------------------------------------------
#--------------------------------------------------------------------------
#--------------------------------------------------------------------------
