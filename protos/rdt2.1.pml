#include "common.pml"

// TODO: write rdt2.1 that introduces sequence numbers
init {
    /* sending payload, sequence number, checksum */
    chan app_L2 = [1] of { bit };
    chan L2 = [1] of { bit };
    chan L2_app = [1] of { bit };
    atomic {
        run generator(app_L2);
        run udt_sender(app_L2, L2);
        run udt_receiver(L2, L2_app);
        run sinker(L2_app)
    }
}