import struct
from mmap import mmap
import swgcd
from flask import Flask, render_template, request, jsonify

# physical address of AXI GCD
GCD_offset = 0x41000000
GCD_size = 0x41000FFF - GCD_offset

# map the physical address of AXI GCD to the virtual address
with open("/dev/mem", "r+b" ) as f:
    mem = mmap(f.fileno(), GCD_size, offset=GCD_offset)

# function for calculating hardware GCD
def hw_gcd(a, b):
    mem[4:8] = struct.pack("<L", a)
    mem[8:12] = struct.pack("<L", b)
    mem[0:4] = struct.pack("<L", 1)
    while struct.unpack("<L", mem[0:4])[0] != 2:
        pass
    c = struct.unpack("<L", mem[12:16])[0]
    clks = struct.unpack("<L", mem[16:20])[0]
    return c, clks

app = Flask(__name__)

# handle HTTP GET request
@app.route('/', methods=['GET'])
def index():
    return render_template('index.html')

# handle HTTP POST request
@app.route('/', methods=['POST'])
def performance():
    # get HTTP request data
    message = request.get_json(force=True);
    # get input A and B
    a = message['a'];
    b = message['b'];
    
    # calculate hardware GCD
    hw_c, hw_clks = hw_gcd(int(a), int(b))
    # calculate software GCD
    sw_c, sw_clks = swgcd.sw_gcd(int(a), int(b))
    
    # calculate speed up in nanoseconds
    hw_time = hw_clks * 10;   # ZYBO's FPGA clock period = 10 ns
    sw_time = sw_clks * 10;
    speed_up = sw_clks/hw_clks
    # construct and send HTTP response data
    response = { 
        'c': hw_c,
        'hw_time': hw_time,
        'sw_time': sw_time,
        'speed_up': '%.2f' % (speed_up)
    }
    return jsonify(response)

if __name__ == '__main__':
    # run the web server on the ZYBO's IP address
    app.run(host='0.0.0.0')
