from intelhex import IntelHex

src1 = IntelHex()
src1.fromfile("C:/Users/svenv/OneDrive/Documents/GitHub/x16-flash/python/x16-smc-r45.1.hex", format="hex")
src1.tofile("r45.1.preview.bin", format="bin")
