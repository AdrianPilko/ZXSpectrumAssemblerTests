% batch file file for compiling racingCarGame.asm

del asm.tap
del asm.sta

e:\ZXSpectrum\asm\pasmo.exe -1 --tapbas racingCarGame.asm asm.tap
pause
