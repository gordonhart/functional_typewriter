import java.io.IOException;

import java.util.*;
import jssc.*; 


public class Sender {
	private static SerialPort sp;


/* try to get better flow control operational...
	public static void main(String[] args) throws InterruptedException {
		if(args.length == 0) {
			System.out.printf("Call with argument: java -cp \"jssc-2.8.0.jar\" Sender <cmd>");
		} else { // don't need to try/catch here since all of the methods used do it
			String tg = "/dev/tty.usbserial-DA00866A";
			if(connect(tg)) { // if we were able to establish a connection
				// split commands into groups
				ArrayList<String> commands = new ArrayList<String>(Arrays.asList(args[0].split("\\s+")));

				if(commands.size()==0) { // simple command case
					sendGCode(args[0]);
					disconnect();
				} else { // long string of commands
					boolean sentmsg = false;
					while(!sentmsg) {
						int numout = 0;

						try { numout = sp.getOutputBufferBytesCount(); }
						catch (Exception e) { System.out.println("whatever"); }

						if(numout==0) {
							String thiscmd = commands.get(0);
							commands.remove(0);

							sendGCode(thiscmd);
							Thread.sleep(250);

							if(commands.size() == 0) sentmsg = true;
						}
					}
					disconnect();
				}
			} 
		}
	}
*/

	public static void main(String[] args) throws InterruptedException {
		if(args.length == 0) {
			System.out.printf("Call with argument: java -cp \"jssc-2.8.0.jar\" Sender <cmd>");
		} else { // don't need to try/catch here since all of the methods used do it
			String tg = "/dev/tty.usbserial-DA00866A";
			if(connect(tg)) { // if we were able to establish a connection
				sendGCode(args[0]);
				disconnect();
			} 
		}
	}

	private static boolean connect(String port){
		try{
			sp = new SerialPort(port);
			sp.openPort();

			sp.setParams(
				SerialPort.BAUDRATE_115200,
				SerialPort.DATABITS_8,
				SerialPort.STOPBITS_1,
				SerialPort.PARITY_NONE);

			sp.setFlowControlMode(SerialPort.FLOWCONTROL_XONXOFF_IN | SerialPort.FLOWCONTROL_XONXOFF_OUT);
//			sp.setFlowControlMode(SerialPort.FLOWCONTROL_RTSCTS_IN | SerialPort.FLOWCONTROL_RTSCTS_OUT); // try RTS/CTS
//			sp.setRTS(true);

			//sp.addEventListener(new PortListener(), SerialPort.MASK_RXCHAR);
			sp.addEventListener(new PortListener());

			return true;
		} catch (SerialPortException ex) { System.out.println("Couldn't open port: " + ex); }
		return false; // if we get here, the connect was unsuccessful
	}

	private static void disconnect() {
		try{
			sendGCode("$md"); //kill motors
			sp.closePort();
		} catch (SerialPortException ex) { System.out.println("Couldn't close port: " + ex); }
	}

	private static void sendGCode(String gCode){
		try { sp.writeString(gCode+"\n"); } 
		catch (SerialPortException ex) { System.out.println("Couldn't write to port: " + ex); }
	}


	private static class PortListener implements SerialPortEventListener {

		public void serialEvent(SerialPortEvent event) {
			// System.out.println(event);
			// System.out.println(event.toString());
			if(event.getEventValue() == 8) { // cts char
				System.out.println("clear to send");
			}

/*			if(event.isRXCHAR() && event.getEventValue() > 0) {
				try {
					String receivedData = sp.readString(event.getEventValue());
//					System.out.println(receivedData);
				} catch (SerialPortException ex) {
					System.out.println("Error in receiving string from COM-port: " + ex);
				}
			}
*/		}
	}
}