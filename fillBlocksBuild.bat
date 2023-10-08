% batch file file for compiling fillBlocks.asm

del asm.tap
del asm.sta

e:\ZXSpectrum\asm\pasmo.exe -1 --tapbas fillBlocks.asm asm.tap
pause
