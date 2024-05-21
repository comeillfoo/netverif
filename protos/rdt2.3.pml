#include "common.pml"

/******************************************
 * rdt2.2: check checksum, add sequence
 * numbers both payload and ACKs, and ARQ
 *
 * not resistant to:
 * - separate bit drops
 * - ACKs/NACKs corruptions
 *****************************************/
proctype rdt2_3_sender(chan inupper, outlower, inlower) {
    bit payload, seq_num = 1, checksum;
    bit is_nack, ack_seq, ack_chksm;
    do
    :: inupper ? payload;
       seq_num = seq_num ^ 1;
       checksum = payload ^ seq_num;
       // ARQ loop
       do
       :: outlower ! payload;
          outlower ! seq_num;
          outlower ! checksum;
          inlower ? is_nack;
          inlower ? ack_seq;
          inlower ? ack_chksm;
          if
          :: ! is_nack && (seq_num == ack_seq) && (is_nack ^ ack_seq == ack_chksm) -> break
          fi
       od
    od
}

proctype rdt2_3_receiver(chan inlower, outupper, outlower) {
    bit payload, seq_num, prev_seq = 1, checksum;
    do
    :: inlower ? payload;
       inlower ? seq_num;
       inlower ? checksum;
       if
       :: payload ^ seq_num != checksum ->
            outlower ! 1;  // NACK: wrong checksum
            outlower ! seq_num;
            outlower ! seq_num ^ 1
       :: prev_seq == seq_num ->
            outlower ! 1; // NACK: wrong packet's sequence number
            outlower ! seq_num;
            outlower ! seq_num ^ 1
       :: else ->
            outlower ! 0; // ACK
            outlower ! seq_num;
            outlower ! seq_num ^ 0;
            prev_seq = seq_num;
            outupper ! payload
       fi
    od
}


init {
    /* sending payload, sequence number, checksum */
    chan app_L4 = [1] of { bit };
    chan L4_app = [1] of { bit };

    chan L4_L2_tx = [1] of { bit };
    chan L4_L2_rx = [1] of { bit };

    chan L2_L4_tx = [1] of { bit };
    chan L2_L4_rx = [1] of { bit };

    chan L2_tx = [1] of { bit };
    chan L2_rx = [1] of { bit };
    atomic {
        run generator(app_L4);
        run rdt2_3_sender(app_L4, L4_L2_tx, L4_L2_rx);
        // payload channels
        run udt_sender(L4_L2_tx, L2_tx);
        run udt_receiver(L2_tx, L2_L4_tx);

        // ack channels
        run udt_receiver(L2_rx, L4_L2_rx);
        run udt_sender(L2_L4_rx, L2_rx);

        run rdt2_3_receiver(L2_L4_tx, L4_app, L2_L4_rx);
        run sinker(L4_app)
    }
}