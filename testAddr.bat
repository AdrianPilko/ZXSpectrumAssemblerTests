% batch file file for compiling testAddr.asm

del asm.tap

e:\ZXSpectrum\asm\pasmo.exe -1 --tapbas testAddr.asm asm.tap
pause