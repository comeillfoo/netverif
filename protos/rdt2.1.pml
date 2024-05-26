#include "common.pml"

inline make2_chksm(payload, seqnum, chksm0, chksm1) {
    chksm0 = payload ^ seqnum;
    chksm1 = payload & seqnum
}

#define check2_chksm(pkt) \
    ((pkt[2] == (pkt[0] ^ pkt[1])) && (pkt[3] == (pkt[0] & pkt[1])))

#define make_chksm(payload) (! payload)
#define check_chksm(payload, checksum) (payload != checksum)

int packets = 10, exp_loss = 0, exp_corrupt = 5
bool tx_stop = false, rx_stop = false

/******************************************
 * rdt2.1 features:
 * - sequence numbers for payload
 * - checksums in [N]ACKs
 * - ARQ
 * - ACK on wrong sequence number
 *
 * not resistant to:
 * - packets drops
 * - packets order violation
 *****************************************/
proctype rdt2_1_sender(chan tx, rx) {
    xs tx;
    xr rx;
    bit packet[4];
    packet[1] = 1;
    for(nr_packet, 0, packets)
        bit response[2];
        generate(packet[0]);
        packet[1] = ! packet[1];
        make2_chksm(packet[0], packet[1], packet[2], packet[3]);

        udt_send(packet, 4, tx, exp_loss, exp_corrupt);

        udt_receive_single(response[0], rx);
        udt_receive_single(response[1], rx);
        do
        :: ! response[0] && check_chksm(response[0], response[1]) -> break // not corrupted ACK
        :: else -> // corrupted ACK or NACK
           udt_send(packet, 4, tx, exp_loss, exp_corrupt);
           udt_receive_single(response[0], rx);
           udt_receive_single(response[1], rx)
        od;
    rof(nr_packet);
    tx_stop = true
}

proctype rdt2_1_receiver(chan rx, tx) {
    xs tx;
    xr rx;
    bit packet[4], hasseq = 0, is_nack = 0;
    do
    :: udt_receive_single(packet[0], rx);
       udt_receive_single(packet[1], rx);
       udt_receive_single(packet[2], rx);
       udt_receive_single(packet[3], rx);
       if
       :: check2_chksm(packet) && hasseq == packet[1] ->
          hasseq = ! hasseq;
          sink(packet, 4);
          is_nack = 0 // ACK
       :: check2_chksm(packet) && hasseq != packet[1] ->
          is_nack = 0 // ACK
       :: else ->
          is_nack = 1 // NACK
       fi;
       tx ! is_nack;
       tx ! make_chksm(is_nack)
    :: tx_stop && nfull(rx) -> break
    od;
    rx_stop = true
}


init {
    chan udata_c = [4] of { bit };
    chan uack_c = [2] of { bit };
    atomic {
        run rdt2_1_sender(udata_c, uack_c);
        run rdt2_1_receiver(udata_c, uack_c);
    };
    do
    :: ! rx_stop -> skip
    :: else -> break
    od;
    assert ( nstat_sent_pkts == nstat_received_pkts )
}