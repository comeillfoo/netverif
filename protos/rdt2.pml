#include "common.pml"

#define make_chksm(payload) (! payload)
#define check_chksm(payload, checksum) (payload != checksum)


int packets = 10, exp_loss = 0, exp_corrupt = 0
bool tx_stop = false, rx_stop = false

mtype { ack, nack }


/******************************************
 * rdt2.0 features: check checksum and ARQ
 *
 * not resistant to:
 * - packets drops
 * - bits corruptions in [N]ACKs
 *****************************************/
proctype rdt2_sender(chan tx, rx) {
    xs tx;
    xr rx;
    bit packet[2];
    for(nr_packet, 0, packets)
        mtype response = nack;
        generate(packet[0]);
        packet[1] = make_chksm(packet[0]);
        do
        :: response == ack -> break
        :: response == nack ->
           udt_send(packet, 2, tx, exp_loss, exp_corrupt);
           udt_receive_single(response, rx)
        od;
    rof(nr_packet);
    tx_stop = true
}


proctype rdt2_receiver(chan rx, tx) {
    xs tx;
    xr rx;
    bit packet[2];
    do
    :: udt_receive_single(packet[0], rx);
       udt_receive_single(packet[1], rx);
       if
       :: check_chksm(packet[0], packet[1]) -> // ACK
          sink(packet, 2);
          tx ! ack
       :: else -> tx ! nack                    // NACK: wrong checksum
       fi
    :: tx_stop && nfull(rx) -> break
    od;
    rx_stop = true
}


init {
    chan udata_c = [2] of { bit };
    chan uack_c = [1] of { mtype };
    atomic {
        run rdt2_sender(udata_c, uack_c);
        run rdt2_receiver(udata_c, uack_c);
    };
    do
    :: ! rx_stop -> skip
    :: else -> break
    od;
    assert ( nstat_sent_pkts == nstat_received_pkts )
}
