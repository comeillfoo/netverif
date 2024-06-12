#include "common.pml"

inline make2_chksm(payload, seqnum, chksm0, chksm1) {
    chksm0 = payload ^ seqnum;
    chksm1 = payload & seqnum
}

#define check2_chksm(pkt) \
    ((pkt[2] == (pkt[0] ^ pkt[1])) && (pkt[3] == (pkt[0] & pkt[1])))


int packets = 10, exp_loss = 0, exp_corrupt = 5
bool tx_stop = false, rx_stop = false

/******************************************
 * rdt2.2 features:
 * - sequence numbers in payload
 * - checksums in [N]ACKs
 * - sequence numbers in [N]ACKs
 * - ARQ
 *
 * not resistant to:
 * - packets drops
 *****************************************/
proctype rdt2_2_sender(chan tx, rx) {
    xs tx;
    xr rx;
    bit packet[4];
    packet[1] = 1;
    for(nr_packet, 0, packets)
        bit response[4];
        generate(packet[0]);
        packet[1] = ! packet[1];
        make2_chksm(packet[0], packet[1], packet[2], packet[3]);

        udt_send(packet, 4, tx, exp_loss, exp_corrupt);

        udt_receive_single(response[0], rx);
        udt_receive_single(response[1], rx);
        udt_receive_single(response[2], rx);
        udt_receive_single(response[3], rx);
        do
        :: ! response[0] && check2_chksm(response) && response[1] == packet[1] ->
           break // not corrupted ACK
        :: else -> // corrupted ACK or NACK or wrong sequence number
           printf("warn: retransmitting...\n");
           udt_send(packet, 4, tx, exp_loss, exp_corrupt);
           udt_receive_single(response[0], rx);
           udt_receive_single(response[1], rx);
           udt_receive_single(response[2], rx);
           udt_receive_single(response[3], rx)
        od;
    rof(nr_packet);
    tx_stop = true
}

proctype rdt2_2_receiver(chan rx, tx) {
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
       :: hasseq == packet[1] && check2_chksm(packet) ->
          sink(packet, 4);
          response[1] = hasseq;
          hasseq = ! hasseq
       :: else ->
          response[1] = ! hasseq; // force wrong seqnum
          printf("warn: suppressed broken\n")
       fi;
       make2_chksm(response[0], response[1], response[2], response[3]);
       udt_send(response, 4, tx, exp_loss, exp_corrupt)
    :: tx_stop && nfull(rx) -> break
    od;
    rx_stop = true
}


init {
    chan udata_c = [4] of { bit };
    chan uack_c = [4] of { bit };
    atomic {
        run rdt2_2_sender(udata_c, uack_c);
        run rdt2_2_receiver(udata_c, uack_c);
    };
    do
    :: ! rx_stop -> skip
    :: else -> break
    od;
    assert ( nstat_sent_pkts == nstat_received_pkts )
}