from intelhex import IntelHex

src1 = IntelHex()

src1.fromfile("C:/Users/svenv/OneDrive/Documents/GitHub/x16-flash/python/x16-smc-header.hex", format="hex")
src1.tofile("python/SMC-HEADER.BIN", format="bin")

src2 = IntelHex()

src2.fromfile("C:/Users/svenv/OneDrive/Documents/GitHub/x16-flash/python/x16-smc-r45.1.0.hex", format="hex")
src2.tofile("python/SMC-R45.1.0.BIN", format="bin")

# Try reading the file in binary mode and writing it back in binary
# mode. By default it reads files in text mode
input1 = open('python/SMC-HEADER.BIN', 'rb').read()
input2 = open('python/SMC-R45.1.0.bin', 'rb').read()

input1 += input2

with open('python/SMC.BIN', 'wb') as fp:
    fp.write(input1)