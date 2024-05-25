#include "common.pml"

int packets = 10, exp_loss = 0, exp_corrupt = 0


/******************************************
 * rdt1.0: no checks
 *
 * not resistant to anything
 *****************************************/
proctype rdt1_sender(chan output) {
    bit packet[1];
    for(nr_packet, 0, packets)
       generate(packet[0]);
       udt_send(packet, 1, output, exp_loss, exp_corrupt);
    rof(nr_packet)
}


proctype rdt1_receiver(chan input) {
    bit packet[1];
    do
    :: udt_receive_single(packet[0], input) -> sink(packet, 1)
    od
}

init {
    chan udchan = [1] of { bit };
    atomic {
        run rdt1_sender(udchan);
        run rdt1_receiver(udchan)
    }
}
