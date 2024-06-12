#include "common.pml"

inline make2_chksm(payload, seqnum, chksm0, chksm1) {
    chksm0 = payload ^ seqnum;
    chksm1 = payload & seqnum
}

#define check2_chksm(pkt) \
    ((pkt[2] == (pkt[0] ^ pkt[1])) && (pkt[3] == (pkt[0] & pkt[1])))


int packets = 10, exp_loss = 2, exp_corrupt = 2
bool tx_stop = false, rx_stop = false

/******************************************
 * rdt3.0 features:
 * - sequence numbers in payload
 * - checksums in [N]ACKs
 * - sequence numbers in [N]ACKs
 * - ARQ
 * - retransmission on timeout
 *
 *****************************************/
proctype rdt3_sender(chan tx, rx) {
    xs tx;
    xr rx;
    bit packet[4];
    packet[1] = 1;
    for(nr_packet, 0, packets)
        bit response[4];
        generate(packet[0]);
        packet[1] = ! packet[1];
        make2_chksm(packet[0], packet[1], packet[2], packet[3]);

resend:
        udt_send(packet, 4, tx, exp_loss, exp_corrupt);

        // retransmission timeout
        for(tm_count, 0, 3)
          if
          :: full(rx) ->
             udt_receive_single(response[0], rx);
             udt_receive_single(response[1], rx);
             udt_receive_single(response[2], rx);
             udt_receive_single(response[3], rx);
             goto handle_reply
          :: nfull(rx) -> skip
          fi;
        rof(tm_count);
        printf("warn: retransmitting on timeout...\n");
        goto resend;

handle_reply:
        if
        :: ((response[0]) || (! check2_chksm(response)) || (response[1] != packet[1])) ->
           printf("warn: retransmitting on broken reply...\n");
           goto resend
        :: else -> skip
        fi; // not corrupted ACK
    rof(nr_packet);
    tx_stop = true
}

proctype rdt3_receiver(chan rx, tx) {
    xs tx;
    xr rx;
    bit packet[4], response[4], hasseq = 0;
    response[0] = 0; // always ACK
    do
    :: udt_receive_single(packet[0], rx);
       udt_receive_single(packet[1], rx);
       udt_receive_single(packet[2], rx);
       udt_receive_single(packet[3], rx);
       if
       :: ((hasseq == packet[1]) && check2_chksm(packet)) ->
          sink(packet, 4);
          response[1] = hasseq;
          hasseq = ! hasseq
       :: else ->
          response[1] = ! hasseq; // force wrong seqnum
          printf("warn: suppressed broken\n")
       fi;
       make2_chksm(response[0], response[1], response[2], response[3]);
       udt_send(response, 4, tx, exp_loss, exp_corrupt);
    :: tx_stop && nfull(rx) -> break
    od;
    rx_stop = true
}


init {
    chan udata_c = [4] of { bit };
    chan uack_c = [4] of { bit };
    atomic {
        run rdt3_sender(udata_c, uack_c);
        run rdt3_receiver(udata_c, uack_c);
    };
    do
    :: ! rx_stop -> skip
    :: else -> break
    od;
    assert ( nstat_sent_pkts == nstat_received_pkts )
}