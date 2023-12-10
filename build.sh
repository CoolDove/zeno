if [ "$1" == "release" ]; then
    odin build ./src/ -resource:app.rc -out:zeno.exe -subsystem:windows
else
    odin build ./src/ -resource:app.rc -out:zeno.exe -debug
fi