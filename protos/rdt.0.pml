
proctype Sender(chan c) {
    // TODO: implement sender routine including:
    // provoking re-transmission requests, errors and etc.
}

proctype Receiver(chan c) {
    // TODO: implement receiver routine
}

init {
    /* sending payload, sequence number, checksum */
    chan unreliable_channel = [1] of { bit, bit, bit };
    run Sender(unreliable_channel);
    run Receiver(unreliable_channel);
}
