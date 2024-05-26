#include "common.pml"

int packets = 10, exp_loss = 0, exp_corrupt = 0
bool tx_stop = false, rx_stop = false

/******************************************
 * rdt1.0: no checks
 *
 * not resistant to anything
 *****************************************/
proctype rdt1_sender(chan tx) {
    xs tx;
    bit packet[1];
    for(nr_packet, 0, packets)
       generate(packet[0]);
       udt_send(packet, 1, tx, exp_loss, exp_corrupt);
    rof(nr_packet);
    tx_stop = true
}


proctype rdt1_receiver(chan rx) {
    xr rx;
    bit packet[1];
    do
    :: (! tx_stop) ->
       udt_receive_single(packet[0], rx) -> sink(packet, 1)
    :: else -> break
    od;
    rx_stop = true
}

init {
    chan udchan = [1] of { bit };
    atomic {
        run rdt1_sender(udchan);
        run rdt1_receiver(udchan)
    };
    do
    :: ! (tx_stop || rx_stop) -> skip
    :: else -> break
    od;
    assert ( nstat_sent_pkts == nstat_received_pkts )
}
