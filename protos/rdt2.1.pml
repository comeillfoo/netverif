#include "common.pml"

// TODO: more reliable checksum
#define make_chksm(payload, seqnum) (! payload)
#define check_chksm(payload, seqnum, checksum) (payload != checksum)

int packets = 10, exp_loss = 0, exp_corrupt = 0

/******************************************
 * rdt2.1 features:
 * - sequence numbers for payload
 * - checksums in [N]ACKs
 * - ARQ
 *
 * not resistant to:
 * - packets drops
 * - phantom ACKs 'cause of bits corruption
 *****************************************/
proctype rdt2_1_sender(chan tx, rx) {
    // TODO: rewrite
}

proctype rdt2_1_receiver(chan rx, tx) {
    // TODO: rewrite
}


init {
    chan udata_c = [3] of { bit };
    chan uack_c = [1] of { mtype };
    atomic {
        run rdt2_1_sender(udata_c, uack_c);
        run rdt2_1_receiver(udata_c, uack_c);
    }
}