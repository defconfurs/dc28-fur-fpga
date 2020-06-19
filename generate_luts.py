# Luts to be generated:
#
# brightness_lut_rom.txt





# brightness_lut_rom.txt
#   a 256 x 16bit LUT which converts RGB field values into timer counts
#   to increase the quality, I'm going to use 3 segments, one for red, green and blue respectively
#   for now they'll be linear and equal until I figure out how to do better
with open("brightness_lut_rom.txt", "w") as lut:
    print("Generating brightness_lut_rom.txt")
    lut.write("// generated using generate_luts.py\n")
    lut.write("//   used in led_matrix.v\n")
    lut.write("%04X\n" % (0))
    for i in range(1,64):
        lut.write("%04X\n" % (int((i/63)**2.2 * 2046 + 1)))
    lut.write("%04X\n" % (0))
    for i in range(1,64):
        lut.write("%04X\n" % (int((i/63)**2.2 * 2046 + 1)))
    lut.write("%04X\n" % (0))
    for i in range(1,64):
        lut.write("%04X\n" % (int((i/63)**2.2 * 2046 + 1)))
    lut.write("%04X\n" % (0))
    for i in range(1,64):
        lut.write("%04X\n" % (0))
        

with open("filter_bank_mem.txt", "w") as coef:
    print("Generating filter_bank_mem.txt")
    coef.write("// generated using generate_luts.py\n")
    coef.write("//   used in filter_bank.v\n")

    # right now these are using 1khz sample rate
    # these were created using: https://www.earlevel.com/main/2013/10/13/biquad-calculator-v2/
    #
    #                  k             b0          b1           b2                     a1                      a2
    coefficients = [[ 1.00, 0.03776213467171289, 0, -0.03776213467171289, -1.9206782174067882,  0.9244757306565741  ], # f= 10hz, Q=0.8
                    [ 1.00, 0.21018049366874755, 0, -0.21018049366874755, -1.4293001117877477,  0.5796390126625048  ], # f= 70hz, Q=0.8
                    [ 1.00, 0.33582867877810796, 0, -0.33582867877810796, -0.7807802152196699,  0.32834264244378397 ], # f=150hz, Q=0.8
                    [ 1.00,  0.3728088775063099, 0,  -0.3728088775063099,   0.387625431143299,  0.25438224498738016 ]] # f=300hz, Q=0.8

    line_num = 0
    for line in coefficients:
        coef.write("%04X\n" % (0xFFFF & int( line[0] *16000))) # 0-k
        coef.write("%04X\n" % (0xFFFF & int(-line[4] *16000))) # 0-a1
        coef.write("%04X\n" % (0xFFFF & int(-line[5] *16000))) # 0-a2
        coef.write("%04X\n" % (0xFFFF & int( line[1] *16000))) # 0-b0
        coef.write("%04X\n" % (0xFFFF & int( line[2] *16000))) # 0-b1
        coef.write("%04X\n" % (0xFFFF & int( line[3] *16000))) # 0-b2
        line_num = line_num + 1
    

    for i in range(line_num, 31):
        coef.write("0000\n")
        
