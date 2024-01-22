debug:
	odin build ./src/ -resource:app.rc -out:zeno.exe -debug -extra-linker-flags:User32.lib

release:
	odin build ./src/ -resource:app.rc -out:zeno.exe -subsystem:windows -extra-linker-flags:User32.lib

run:
	./zeno.exe

clean:
	rm zeno.exe zeno.pdb
