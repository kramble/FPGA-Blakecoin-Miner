LX150-Midstate         Original version, 16 clocks/hash, up to 16 cores
                       Best speed to date 89MHash/sec at 50MHz

LX150-Unrolled         Unrolled, 16 clocks/hash, 16 stages, up to 4 cores
                       Best speed to date 270MHash/sec at 45MHz (3 cores)

LX150-UnrolledPiped    32 clocks/hash, 32 stages, up to 4 cores
                       NB runs approx double clock speed due to extra pipelining
                       Best speed to date 450MHash/sec at 75MHz (3 cores)

LX150-MaxPiped         96 clocks/hash, 96 stages (6 latency G Function)
                       This is resource heavy, so FourPiped may be better

LX150-FourPiped        64 clocks/hash, 64 stages (4 latency G Function)
                       Work in progress