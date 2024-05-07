proctype generator(chan output) {
    output ! 0, 0, 0;
    output ! 1, 1, 0;
    output ! 1, 0, 1;
    output ! 0, 1, 1;
    output ! 0, 0, 0;
}


proctype udt_sender(chan input, output) {

    bit payload, seq_num, checksum;

    do
    :: atomic {
        input ? payload, seq_num, checksum;
        if
        :: output ! ! payload,   seq_num,   checksum // corrupt payload
        :: output !   payload, ! seq_num,   checksum // corrupt sequence number
        :: output !   payload,   seq_num, ! checksum // corrupt checksum
        :: skip                                      // drop
        :: output !   payload,   seq_num,   checksum // just send
        fi;
      }
    od
}

proctype udt_receiver(chan input, output) {
    bit payload, seq_num, checksum;
    do
    :: atomic {
        input ? payload, seq_num, checksum;
        output ! payload, seq_num, checksum
      }
    od
}


proctype sinker(chan input) {
    bit payload, seq_num, checksum;
    do
    :: atomic {
        input ? payload, seq_num, checksum;
        skip
      }
    od
}

init {
    /* sending payload, sequence number, checksum */

    chan L3_1 = [1] of { bit, bit, bit };
    chan L2 = [1] of { bit, bit, bit };
    chan L3_2 = [1] of { bit, bit, bit };
    atomic {
        run generator(L3_1);
        run udt_sender(L3_1, L2);
        run udt_receiver(L2, L3_2);
        run sinker(L3_2)
    }
}
