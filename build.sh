if [ "$1" == "debug" ]; then
    odin build ./src/ -resource:app.rc -out:zeno.exe -debug
else
    odin build ./src/ -resource:app.rc -out:zeno.exe -subsystem:windows
fi