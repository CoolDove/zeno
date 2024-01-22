easytab:
	powershell -Command "Enter-VsDevShell x64; pushd ./src/easytab/easytab_c ; ./build_msvc.ps1"
debug:
	odin build ./src/ -resource:app.rc -out:zeno.exe -debug -extra-linker-flags:"User32.lib Gdi32.lib"

release:
	odin build ./src/ -resource:app.rc -out:zeno.exe -subsystem:windows -extra-linker-flags:"User32.lib Gdi32.lib"

run:
	./zeno.exe

clean:
	rm zeno.exe zeno.pdb
