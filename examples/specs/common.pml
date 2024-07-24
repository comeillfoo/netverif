#define for(it, low, high) \
    int it = low; \
    do \
    :: else -> break \
    :: it < high ->

#define rof(it) \
       it++ \
    od


int nstat_actual_loss = 0, nstat_actual_corrupt = 0, nstat_sent_pkts = 0, nstat_received_pkts = 0


inline generate(payload) {
    d_step {
        if
        :: payload = 0
        :: payload = 1
        fi;
        nstat_sent_pkts++;
        printf("pkt [%d] sending...\n", payload)
    }
}


inline udt_send(packet, size, output, exp_loss, exp_corrupt) {
    if
    :: nstat_actual_corrupt < exp_corrupt -> atomic { // corrupt payload
         for(i, 0, size)
            if
            :: output ! (! packet[i])
            :: output ! packet[i]
            fi;
         rof(i)
       };
       nstat_actual_corrupt++;
    :: nstat_actual_loss < exp_loss -> nstat_actual_loss++ // drop
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
        nstat_received_pkts++;
        printf("pkt [ ");
        for(i, 0, size)
            printf("%d ", payloads[i]);
        rof(i);
        printf("]: received\n")
    }
}
