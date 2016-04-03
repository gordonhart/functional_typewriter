# very simple shell script to invoke the serialclient library for communications
if [ -z "$1" ]; then
	echo "needs a command"
else
	echo "$1" | serialclient -p /dev/tty.usbserial-DA00866A -s 115200 -d 8 -t 1 -a NONE &> /dev/null  # silence output
	wait # ; sleep 2 # this two second delay is enough but goddamn is it slow.
fi
