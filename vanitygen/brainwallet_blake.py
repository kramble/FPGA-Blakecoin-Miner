# brainwallet_blake.py
# Incorporates code from ...
# jackjack's pywallet.py
# https://github.com/jackjack-jj/pywallet
# https://bitcointalk.org/index.php?topic=23241.0

import hashlib
from blake8 import BLAKE as BLAKE

# Code from pywallet.py for bas58 encoding

__b58chars = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
__b58base = len(__b58chars)

def b58encode(v):
	""" encode v, which is a string of bytes, to base58.		
	"""

	long_value = 0L
	for (i, c) in enumerate(v[::-1]):
		long_value += (256**i) * ord(c)

	result = ''
	while long_value >= __b58base:
		div, mod = divmod(long_value, __b58base)
		result = __b58chars[mod] + result
		long_value = div
	result = __b58chars[long_value] + result

	# Bitcoin does a little leading-zero-compression:
	# leading 0-bytes in the input become leading-1s
	nPad = 0
	for c in v:
		if c == '\0': nPad += 1
		else: break

	return (__b58chars[0]*nPad) + result

def b58decode(v, length):
	""" decode v into a string of len bytes
	"""
	long_value = 0L
	for (i, c) in enumerate(v[::-1]):
		long_value += __b58chars.find(c) * (__b58base**i)

	result = ''
	while long_value >= 256:
		div, mod = divmod(long_value, 256)
		result = chr(mod) + result
		long_value = div
	result = chr(long_value) + result

	nPad = 0
	for c in v:
		if c == __b58chars[0]: nPad += 1
		else: break

	result = chr(0)*nPad + result
	# print "len=", len(result), "res=", result.encode('hex_codec') # DEBUG
	if length is not None and len(result) != length:
		return None

	return result

# end of bitcointools base58 implementation
	
# https://bitcointalk.org/index.php?topic=23241.0

class CurveFp( object ):
		def __init__( self, p, a, b ):
		 	self.__p = p
		 	self.__a = a
		 	self.__b = b

		def p( self ):
		 	return self.__p

		def a( self ):
		 	return self.__a

		def b( self ):
		 	return self.__b

		def contains_point( self, x, y ):
		 	return ( y * y - ( x * x * x + self.__a * x + self.__b ) ) % self.__p == 0

class Point( object ):
		def __init__( self, curve, x, y, order = None ):
		 	self.__curve = curve
		 	self.__x = x
		 	self.__y = y
		 	self.__order = order
		 	if self.__curve: assert self.__curve.contains_point( x, y )
		 	if order: assert self * order == INFINITY
	
		def __add__( self, other ):
		 	if other == INFINITY: return self
		 	if self == INFINITY: return other
		 	assert self.__curve == other.__curve
		 	if self.__x == other.__x:
		 	 	if ( self.__y + other.__y ) % self.__curve.p() == 0:
		 	 	 	return INFINITY
		 	 	else:
		 	 	 	return self.double()

		 	p = self.__curve.p()
		 	l = ( ( other.__y - self.__y ) * \
		 	 	 	 	inverse_mod( other.__x - self.__x, p ) ) % p
		 	x3 = ( l * l - self.__x - other.__x ) % p
		 	y3 = ( l * ( self.__x - x3 ) - self.__y ) % p
		 	return Point( self.__curve, x3, y3 )

		def __mul__( self, other ):
		 	def leftmost_bit( x ):
		 	 	assert x > 0
		 	 	result = 1L
		 	 	while result <= x: result = 2 * result
		 	 	return result / 2

		 	e = other
		 	if self.__order: e = e % self.__order
		 	if e == 0: return INFINITY
		 	if self == INFINITY: return INFINITY
		 	assert e > 0
		 	e3 = 3 * e
		 	negative_self = Point( self.__curve, self.__x, -self.__y, self.__order )
		 	i = leftmost_bit( e3 ) / 2
		 	result = self
		 	while i > 1:
		 	 	result = result.double()
		 	 	if ( e3 & i ) != 0 and ( e & i ) == 0: result = result + self
		 	 	if ( e3 & i ) == 0 and ( e & i ) != 0: result = result + negative_self
		 	 	i = i / 2
		 	return result

		def __rmul__( self, other ):
		 	return self * other

		def __str__( self ):
		 	if self == INFINITY: return "infinity"
		 	return "(%d,%d)" % ( self.__x, self.__y )

		def double( self ):
		 	if self == INFINITY:
		 	 	return INFINITY

		 	p = self.__curve.p()
		 	a = self.__curve.a()
		 	l = ( ( 3 * self.__x * self.__x + a ) * \
		 	 	 	 	inverse_mod( 2 * self.__y, p ) ) % p
		 	x3 = ( l * l - 2 * self.__x ) % p
		 	y3 = ( l * ( self.__x - x3 ) - self.__y ) % p
		 	return Point( self.__curve, x3, y3 )

		def x( self ):
		 	return self.__x

		def y( self ):
		 	return self.__y

		def curve( self ):
		 	return self.__curve
		
		def order( self ):
		 	return self.__order
		 	
INFINITY = Point( None, None, None )

def inverse_mod( a, m ):
		if a < 0 or m <= a: a = a % m
		c, d = a, m
		uc, vc, ud, vd = 1, 0, 0, 1
		while c != 0:
		 	q, c, d = divmod( d, c ) + ( c, )
		 	uc, vc, ud, vd = ud - q*uc, vd - q*vc, uc, vc
		assert d == 1
		if ud > 0: return ud
		else: return ud + m

# secp256k1
_p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2FL
_r = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141L
_b = 0x0000000000000000000000000000000000000000000000000000000000000007L
_a = 0x0000000000000000000000000000000000000000000000000000000000000000L
_Gx = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798L
_Gy = 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8L

class Signature( object ):
		def __init__( self, r, s ):
		 	self.r = r
		 	self.s = s
		 	
class Public_key( object ):
		def __init__( self, generator, point ):
		 	self.curve = generator.curve()
		 	self.generator = generator
		 	self.point = point
		 	n = generator.order()
		 	if not n:
		 	 	raise RuntimeError, "Generator point must have order."
		 	if not n * point == INFINITY:
		 	 	raise RuntimeError, "Generator point order is bad."
		 	if point.x() < 0 or n <= point.x() or point.y() < 0 or n <= point.y():
		 	 	raise RuntimeError, "Generator point has x or y out of range."

		def verifies( self, hash, signature ):
		 	G = self.generator
		 	n = G.order()
		 	r = signature.r
		 	s = signature.s
		 	if r < 1 or r > n-1: return False
		 	if s < 1 or s > n-1: return False
		 	c = inverse_mod( s, n )
		 	u1 = ( hash * c ) % n
		 	u2 = ( r * c ) % n
		 	xy = u1 * G + u2 * self.point
		 	v = xy.x() % n
		 	return v == r

class Private_key( object ):
		def __init__( self, public_key, secret_multiplier ):
		 	self.public_key = public_key
		 	self.secret_multiplier = secret_multiplier

		def der( self ):
		 	hex_der_key = '06052b8104000a30740201010420' + \
		 	 	 	 	 	 	 	 	'%064x' % self.secret_multiplier + \
		 	 	 	 	 	 	 	 	'a00706052b8104000aa14403420004' + \
		 	 	 	 	 	 	 	 	'%064x' % self.public_key.point.x() + \
		 	 	 	 	 	 	 	 	'%064x' % self.public_key.point.y()
		 	return hex_der_key.decode('hex')

		def sign( self, hash, random_k ):
		 	G = self.public_key.generator
		 	n = G.order()
		 	k = random_k % n
		 	p1 = k * G
		 	r = p1.x()
		 	if r == 0: raise RuntimeError, "amazingly unlucky random number r"
		 	s = ( inverse_mod( k, n ) * \
		 	 	 	 	( hash + ( self.secret_multiplier * r ) % n ) ) % n
		 	if s == 0: raise RuntimeError, "amazingly unlucky random number s"
		 	return Signature( r, s )

curve_256 = CurveFp( _p, _a, _b )
generator_256 = Point( curve_256, _Gx, _Gy, _r )
g = generator_256

def hexprivkey2addr(privkey_hex):
	print privkey_hex, " priv key HEX"

	# Encode the private key in WIF see https://en.bitcoin.it/wiki/Base58Check_encoding

	data_hex = "80" + privkey_hex
	data_bin = data_hex.decode('hex')

	# hash = hashlib.sha256(hashlib.sha256(data_bin).digest()).digest()
	hash_blake8 = BLAKE(256).digest(data_bin)
	sha_hex = hash_blake8.encode('hex_codec')

	step2_hex = data_hex + sha_hex[:8]

	privkey = b58encode(step2_hex.decode('hex'))
	# print privkey, " private key WIF"

	# Now print the compressed WIF private key
	# bitaddress.org appends 01 so try that ...

	data_hex = "80" + privkey_hex + "01"
	data_bin = data_hex.decode('hex')

	# hash = hashlib.sha256(hashlib.sha256(data_bin).digest()).digest()
	hash_blake8 = BLAKE(256).digest(data_bin)
	sha_hex = hash_blake8.encode('hex_codec')

	step2_hex = data_hex + sha_hex[:8]

	privkey = b58encode(step2_hex.decode('hex'))
	# print "=========================================================="
	print "BLAKE PRIVKEY..."
	# print privkey, " private key WIF (comp)"
	print privkey
	# print "=========================================================="
	
	# ===========================================
	# The next step is to convert to a public key
	# ===========================================
	
	secret = int(privkey_hex,16)	# Need this as decimal number

	# generate pubkey
	pubkey = Public_key( g, g * secret )
	# print 'pubkey', hex(pubkey.point.x()), hex(pubkey.point.y())
	
	# This is clunky, there is probably a better way ...
	x_hex = hex(pubkey.point.x())
	x_hex = x_hex[2:]	# Remove leading 0x
	x_hex = x_hex[:-1]	# Remove trailing L
	# Pad with leading 0's to 64 chars...
	x_hex = x_hex.zfill(64)
	# print "x", x_hex
	y_hex = hex(pubkey.point.y())
	y_hex = y_hex[2:]	# Remove leading 0x
	y_hex = y_hex[:-1]	# Remove trailing L
	# Probably need to pad with leading 0's to 64 chars...
	y_hex = y_hex.zfill(64)
	# print "y", y_hex
	
	pubkey_hex = "04" + x_hex + y_hex
	# print pubkey_hex, " public key"
	
	# ==================
	# Address generation
	# ==================
	
	pubkey = pubkey_hex

	data_bin = pubkey.decode('hex')

	# First step is a SHA256
	data_bin = hashlib.sha256(data_bin).digest()

	# Second step is RIPEMD160
	hash = hashlib.new('ripemd160')
	hash.update(data_bin)
	hash_digest = hash.digest()
	hash_hex = hash.hexdigest()

	# print hash_hex + "  uncompressed hash (pubkey)"

	# Now encode the address

	data_hex = "1a" + hash_hex	# 1a is version byte for BLAKE (26 decimal)
	data_bin = data_hex.decode('hex')

	#hash = hashlib.sha256(hashlib.sha256(data_bin).digest()).digest()
	hash_blake8 = BLAKE(256).digest(data_bin)
	sha_hex = hash_blake8.encode('hex_codec')
	step2_hex = data_hex + sha_hex[:8]

	# print b58encode(step2_hex.decode('hex')), " address"

	# ============================================================================================
	# Now do the same for the COMPRESSED public key (see https://bitcointalk.org/index.php?topic=205490.0)
	# ============================================================================================

	lastchar = pubkey[-2:]
	val = lastchar.decode('hex')
	if (ord(val)%2):
		# print "odd"
		xpubkey = "03" + pubkey[2:66]	
	else:
		# print "even"
		xpubkey = "02" + pubkey[2:66]	

	# print xpubkey + "  comp pubkey"

	data_bin = xpubkey.decode('hex')

	# First step is a SHA256
	data_bin = hashlib.sha256(data_bin).digest()

	# Second step is RIPEMD160
	hash = hashlib.new('ripemd160')
	hash.update(data_bin)
	hash_digest = hash.digest()
	hash_hex = hash.hexdigest()		# Saves the encoding step

	# print hash_hex + "  hash (compressed pubkey)"

	# Now encode the address

	# print "=========================================================="
	print "BLAKE ADDRESS..."
	data_hex = "1a" + hash_hex	# 1a is version byte for BLAKE (26 decimal)
	data_bin = data_hex.decode('hex')

	# !!!! WRONG, need to use blake hash, not sha256d for checksum !!!!
	# hash = hashlib.sha256(hashlib.sha256(data_bin).digest()).digest()
	hash_blake8 = BLAKE(256).digest(data_bin)

	sha_hex = hash_blake8.encode('hex_codec')
	step2_hex = data_hex + sha_hex[:8]

	# print b58encode(step2_hex.decode('hex')), " compressed address"
	print b58encode(step2_hex.decode('hex'))
	# print "=========================================================="
	
def brainwallet(keyphrase):
	print "keyphrase=[" + keyphrase + "]"
	privkey_bin = hashlib.sha256(keyphrase).digest()		# Single sha256 (standard brain algorithm)
	# privkey_bin = hashlib.sha256(privkey_bin).digest()	# Double sha256 (not useful)

	# privkey_hex = hashlib.sha256(keyphrase).hexdigest()	# Can generate hex directly
	privkey_hex = privkey_bin.encode('hex_codec')			# Alternatively from bin
	hexprivkey2addr(privkey_hex)
	
def WIFpriv2addr(WIFkey):
	# Will want to try both len 37 and 38 (compressed)
	# rawaddr = b58decode(WIFkey, 37) # 37 since 08 + 32bytes +4bytes
	rawaddr = b58decode(WIFkey, 38) # Blake blakecoind generates compressed address, so 38
	# Todo check for result "None"
	hexaddr = rawaddr.encode('hex_codec')
	print hexaddr
	# Todo verify checksum
	privkey_hex = hexaddr[2:66]
	hexprivkey2addr(privkey_hex)

	# ============================= main ==============================
if __name__ == "__main__":
	# Examples
	input = raw_input("Enter passphrase: ")
	# brainwallet("correct horse battery staple")
	brainwallet(input)
