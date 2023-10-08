from intelhex import IntelHex

version = "R45.1.0"

src1 = IntelHex()

src1.fromfile("bin/x16-smc-header-" + version + ".hex", format="hex")
src1.tofile("bin/SMC-HEADER-" + version + ".BIN", format="bin")

src2 = IntelHex()

src2.fromfile("arduino/x16-smc-" + version + ".hex", format="hex")
src2.tofile("bin/SMC-" + version + ".BIN", format="bin")

# Try reading the file in binary mode and writing it back in binary
# mode. By default it reads files in text mode
input1 = open("bin/SMC-HEADER-" + version + ".BIN", "rb").read()
input2 = open("bin/SMC-" + version + ".BIN", "rb").read()

input1 += input2

with open("bin/SMC-" + version + ".BIN", "wb") as fp:
    fp.write(input1)