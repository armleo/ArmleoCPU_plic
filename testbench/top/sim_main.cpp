#include <verilated.h>
#include <verilated_vcd_c.h>
#include <Varmleocpu_clint.h>
#include <iostream>

vluint64_t simulation_time = 0;
VerilatedVcdC	*m_trace;
bool trace = 1;
Varmleocpu_clint* armleocpu_clint;

using namespace std;

double sc_time_stamp() {
    return simulation_time;  // Note does conversion to real, to match SystemC
}
void dump_step() {
    simulation_time++;
    if(trace) {
        m_trace->dump(simulation_time);
        //m_trace->flush();
        //cout << "Dump step" << endl << flush;
    }
}
void update() {
    armleocpu_clint->eval();
    dump_step();
}

void posedge() {
    armleocpu_clint->clk = 1;
    update();
    update();
}

void till_user_update() {
    armleocpu_clint->clk = 0;
    update();
}
void after_user_update() {
    update();
}


void next_cycle() {
    after_user_update();

    posedge();
    till_user_update();
    armleocpu_clint->eval();
}

class axilite_writer {
    volatile uint16_t * AXI_AWADDR;
    volatile uint8_t * AXI_AWVALID;
    volatile uint8_t * AXI_AWREADY;
    volatile uint32_t * AXI_WDATA;
    volatile uint8_t * AXI_WSTRB;
    volatile uint8_t * AXI_WVALID;
    volatile uint8_t * AXI_WREADY;
    volatile uint8_t * AXI_BRESP;
    volatile uint8_t * AXI_BVALID;
    volatile uint8_t * AXI_BREADY;
    
public:
    axilite_writer(
        uint16_t * _AXI_AWADDR, uint8_t * _AXI_AWVALID, uint8_t * _AXI_AWREADY,
        uint32_t * _AXI_WDATA, uint8_t * _AXI_WSTRB, uint8_t * _AXI_WVALID, uint8_t * _AXI_WREADY,
        uint8_t * _AXI_BRESP, uint8_t * _AXI_BVALID, uint8_t * _AXI_BREADY
    ) : AXI_AWADDR(_AXI_AWADDR), AXI_AWVALID(_AXI_AWVALID), AXI_AWREADY(_AXI_AWREADY),
        AXI_WDATA(_AXI_WDATA), AXI_WSTRB(_AXI_WSTRB), AXI_WVALID(_AXI_WVALID), AXI_WREADY(_AXI_WREADY),
        AXI_BRESP(_AXI_BRESP), AXI_BVALID(_AXI_BVALID), AXI_BREADY(_AXI_BREADY)
     {
        *AXI_AWADDR = 0;
        *AXI_AWVALID = 0;
        *AXI_WDATA = 0;
        *AXI_WSTRB = 0;
        *AXI_WVALID = 0;

        *AXI_BREADY = 0;
    }

    void write32_success(uint32_t addr, uint32_t data) {
        *AXI_AWADDR = addr;
        *AXI_AWVALID = 1;
        *AXI_WDATA = data;
        *AXI_WSTRB = 0xf;
        *AXI_WVALID = 1;

        *AXI_BREADY = 0;
        bool AWDONE = 0, AWDONE_nxt = 0;
        bool WDONE = 0, WDONE_nxt = 0;
        bool BDONE = 0, BDONE_nxt = 0;
        bool last_cycle = 0;
        uint16_t timeout = 0;
        while(!(AWDONE && WDONE && BDONE && last_cycle) && !(timeout >= 1000)) {
            //cout << "AXI_AWREADY = " << (int)(*AXI_AWREADY) << endl;
            //cout << "AXI_BRESP = " << (int)(*AXI_BRESP) << endl;
            if(AWDONE)
                *AXI_AWVALID = 0;
            if(WDONE)
                *AXI_WVALID = 0;
            if(BDONE) {
                *AXI_BREADY = 1;
                last_cycle = 1;
            }
            armleocpu_clint->eval();

            if(*AXI_AWREADY && !AWDONE)
                AWDONE_nxt = 1;
            
            if(*AXI_WREADY && !WDONE)
                WDONE_nxt = 1;
            if(WDONE && AWDONE) {
                if(*AXI_BVALID) {
                    if(*AXI_BRESP != 0) {
                        cout << "Unexpexted AXI Write error" << endl << flush;
                        throw std::runtime_error("Unexpexted AXI Write error");
                    } else {
                        BDONE_nxt = 1;
                    }
                }
            } else if(*AXI_BVALID) {
                cout << "BVALID Before AW and W is accepted" << endl << flush;
                throw std::runtime_error("BVALID Before AW and W is accepted");
            }
            AWDONE = AWDONE_nxt;
            WDONE = WDONE_nxt;
            BDONE = BDONE_nxt;
            next_cycle();
            timeout++;
        }
        
    }
};


class axilite_reader {
    volatile uint16_t * AXI_ARADDR;
    volatile uint8_t * AXI_ARVALID;
    volatile uint8_t * AXI_ARREADY;
    volatile uint32_t * AXI_RDATA;
    volatile uint8_t * AXI_RRESP;
    volatile uint8_t * AXI_RVALID;
    volatile uint8_t * AXI_RREADY;
    
public:
    axilite_reader(
        uint16_t * _AXI_ARADDR, uint8_t * _AXI_ARVALID, uint8_t * _AXI_ARREADY,
        uint32_t * _AXI_RDATA, uint8_t * _AXI_RRESP, uint8_t * _AXI_RVALID, uint8_t * _AXI_RREADY
    ) : AXI_ARADDR(_AXI_ARADDR), AXI_ARVALID(_AXI_ARVALID), AXI_ARREADY(_AXI_ARREADY),
        AXI_RDATA(_AXI_RDATA), AXI_RRESP(_AXI_RRESP), AXI_RVALID(_AXI_RVALID), AXI_RREADY(_AXI_RREADY)
     {
        *AXI_ARADDR = 0;
        *AXI_ARVALID = 0;
        *AXI_RREADY = 0;
    }

    uint32_t read32_success(uint32_t addr) {
        *AXI_ARADDR = addr;
        *AXI_ARVALID = 1;
        bool ARDONE = 0, ARDONE_nxt = 0;
        bool RDONE = 0, RDONE_nxt = 0;
        bool last_cycle = 0, last_cycle_nxt = 0;
        uint16_t timeout = 0;
        uint32_t result;
        while(!(ARDONE && RDONE && last_cycle) && !(timeout >= 1000)) {
            if(ARDONE)
                *AXI_ARVALID = 0;
            if(last_cycle)
                *AXI_RREADY = 0;
            armleocpu_clint->eval();
            if(*AXI_ARREADY)
                ARDONE_nxt = 1;
            if(*AXI_RVALID) {
                *AXI_RREADY = 1;
                RDONE_nxt = 1;
                if(*AXI_RRESP != 0) {
                    cout << "Unexptected RRESP" << endl << flush;
                    throw std::runtime_error("Unexptected RRESP");
                }
                result = *AXI_RDATA;
            }
            if(RDONE && ARDONE)
                last_cycle_nxt = 1;
            
            
            // TODO:
            ARDONE = ARDONE_nxt;
            RDONE = RDONE_nxt;
            last_cycle = last_cycle_nxt;

            next_cycle();
            timeout++;
        }
        return result;
        
    }
};




string testname;
int testnum;

void test_begin(int num, string tn) {
    testname = tn;
    testnum = num;
    cout << testnum << " - " << testname << endl;
}

void test_end() {
    next_cycle();
    cout << testnum << " - " << testname << " DONE" << endl;
}


int main(int argc, char** argv, char** env) {
    cout << "Test started" << endl;
    // This is a more complicated example, please also see the simpler examples/make_hello_c.

    // Prevent unused variable warnings
    if (0 && argc && argv && env) {}

    // Set debug level, 0 is off, 9 is highest presently used
    // May be overridden by commandArgs
    Verilated::debug(0);

    // Randomization reset policy
    // May be overridden by commandArgs
    Verilated::randReset(2);

    // Verilator must compute traced signals
    Verilated::traceEverOn(true);

    // Pass arguments so Verilated code can see them, e.g. $value$plusargs
    // This needs to be called before you create any model
    Verilated::commandArgs(argc, argv);

    // Create logs/ directory in case we have traces to put under it
    Verilated::mkdir("logs");

    // Construct the Verilated model, from Varmleocpu_clint.h generated from Verilating "armleocpu_clint.v"
    armleocpu_clint = new Varmleocpu_clint;  // Or use a const unique_ptr, or the VL_UNIQUE_PTR wrapper
    m_trace = new VerilatedVcdC;
    armleocpu_clint->trace(m_trace, 99);
    m_trace->open("vcd_dump.vcd");


    try {
        cout << "Starting tests" << endl;
        armleocpu_clint->rst_n = 0;
        armleocpu_clint->AXI_ARVALID = 0;
        armleocpu_clint->AXI_AWVALID = 0;
        armleocpu_clint->AXI_WVALID = 0;
        armleocpu_clint->AXI_BREADY = 0;
        armleocpu_clint->AXI_RREADY = 0;
        till_user_update();
        cout << "First eval successful" << endl;
        armleocpu_clint->rst_n = 0;
        
        next_cycle();
        armleocpu_clint->rst_n = 1;
        next_cycle();
        cout << "Reset done" << endl << flush;

        uint32_t MSIP_OFFSET = 0;
        uint32_t MTIMECMP_OFFSET = 0x4000;
        uint32_t MTIME_OFFSET = 0xBFF8;

        uint8_t harts = 8;
        

        axilite_writer writer(
            &armleocpu_clint->AXI_AWADDR, &armleocpu_clint->AXI_AWVALID, &armleocpu_clint->AXI_AWREADY,
            &armleocpu_clint->AXI_WDATA, &armleocpu_clint->AXI_WSTRB, &armleocpu_clint->AXI_WVALID, &armleocpu_clint->AXI_WREADY,
            &armleocpu_clint->AXI_BRESP, &armleocpu_clint->AXI_BVALID, &armleocpu_clint->AXI_BREADY
        );

        axilite_reader reader(
            &armleocpu_clint->AXI_ARADDR, &armleocpu_clint->AXI_ARVALID, &armleocpu_clint->AXI_ARREADY,
            &armleocpu_clint->AXI_RDATA, &armleocpu_clint->AXI_RRESP, &armleocpu_clint->AXI_RVALID, &armleocpu_clint->AXI_RREADY
        );

    
    
        
        for(int i = 0; i < harts; ++i) {
            int hart_id = i;
            cout << "Writing" << endl;
            writer.write32_success(MSIP_OFFSET + (hart_id << 2), 0x1);

            if(armleocpu_clint->hart_swi & (1 << hart_id)) {
                cout << "Test for hart: " << hart_id << "correct hart_swi" << endl;
            }

            uint64_t mtime;
            bool success = 1;
            
            mtime = reader.read32_success(MTIME_OFFSET);
            mtime = mtime | ((uint64_t)(reader.read32_success(MTIME_OFFSET + 4)) << 32);
            writer.write32_success(MTIMECMP_OFFSET + (i << 3), mtime + 4);
            writer.write32_success(MTIMECMP_OFFSET + (i << 3) + 4, (mtime + 4) >> 32);
            for(int j = 0; j < 6; ++j) {
                if(armleocpu_clint->hart_timeri & (1 << i)) {
                    cout << "MTIMECMP test done for hart: " << i << endl;
                    success = true;
                    break;
                }
            }
            if(!success){
                cout << "Failed test for MTIMECMP" << endl;
                throw "Failed test for MTIMECMP";
            }
        }
        // TODO: Add test for outside registers access


        cout << "CLINT Tests done" << endl;

    } catch(runtime_error e) {
        cout << e.what();
        cout << "Error intercepted" << endl << flush;
        
    }
    next_cycle();
    next_cycle();
    armleocpu_clint->final();
    if (m_trace) {
        m_trace->flush();
        m_trace->close();
        delete m_trace;
        m_trace = NULL;
    }
#if VM_COVERAGE
    Verilated::mkdir("logs");
    VerilatedCov::write("logs/coverage.dat");
#endif

    // Destroy model
    delete armleocpu_clint; armleocpu_clint = NULL;

    // Fin
    exit(0);
}