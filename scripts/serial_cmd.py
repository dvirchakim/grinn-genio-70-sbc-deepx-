import serial
import sys
import time

def run_serial_cmd(port, baud, cmd):
    try:
        with serial.Serial(port, baud, timeout=2) as ser:
            ser.write(f"\n{cmd}\n".encode())
            time.sleep(1)
            output = ser.read_all().decode(errors='ignore')
            print(output)
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python serial_cmd.py <command>")
    else:
        run_serial_cmd('COM4', 115200, sys.argv[1])
