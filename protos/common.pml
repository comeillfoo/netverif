#define for(it, low, high) \
    int it = low; \
    do \
    :: else -> break \
    :: it < high ->

#define rof(it) \
       it++ \
    od


int act_loss = 0, act_corrupt = 0


inline generate(payload) {
    if
    :: payload = 0
    :: payload = 1
    fi;
    printf("pkt [%d] sending...\n", payload)
}


inline udt_send(packet, size, output, exp_loss, exp_corrupt) {
    if
    :: act_corrupt < exp_corrupt -> atomic { // corrupt payload
         for(i, 0, size)
            if
            :: output ! (! packet[i])
            :: output ! packet[i]
            fi;
         rof(i)
       };
       act_corrupt++;
    :: act_loss < exp_loss -> act_loss++ // drop
    :: atomic { // just send
         for(j, 0, size)
            output ! packet[j];
         rof(j)
       }
    fi
}

inline udt_receive_single(payload, input) {
    input ? payload
}

inline sink(payloads, size) {
    d_step {
        printf("pkt [ ");
        for(i, 0, size)
            printf("%d ", payloads[i]);
        rof(i);
        printf("]: received\n")
    }
}
