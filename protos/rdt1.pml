#include "common.pml"


/******************************************
 * rdt1.0: no checks
 *****************************************/
proctype rdt1_sender(chan input, output) {
    bit payload, seq_num = 0, checksum;
    do
    :: input ? payload;
       seq_num = seq_num ^ 1;
       checksum = payload ^ seq_num;
       output ! payload;
       output ! seq_num;
       output ! checksum
    od
}


proctype rdt1_receiver(chan input, output) {
    bit payload, seq_num, checksum;
    do
    :: input ? payload;
       input ? seq_num;
       input ? checksum;
       output ! payload
    od
}


init {
    /* sending payload, sequence number, checksum */
    chan app_L4 = [1] of { bit };
    chan L4_L2 = [1] of { bit };
    chan L2 = [1] of { bit };
    chan L2_L4 = [1] of { bit };
    chan L4_app = [1] of { bit };
    atomic {
        run generator(app_L4);
        run rdt1_sender(app_L4, L4_L2);
        run udt_sender(L4_L2, L2);
        run udt_receiver(L2, L2_L4);
        run rdt1_receiver(L2_L4, L4_app);
        run sinker(L4_app)
    }
}
