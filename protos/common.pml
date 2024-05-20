proctype generator(chan output) {
    output ! 0;
    output ! 1;
    output ! 1;
    output ! 0;
    output ! 0
}


proctype udt_sender(chan input, output) {
    bit payload;
    do
    :: input ? payload;
       if
       :: output ! ! payload // corrupt payload
       :: skip               // drop
       :: output !   payload // pass upper level
       fi
    od
}

proctype udt_receiver(chan input, output) {
    bit payload;
    do
    :: input ? payload;
       output ! payload
    od
}

proctype sinker(chan input) {
    bit payload;
    do
    :: input ? payload;
       printf("got %d\n", payload);
       skip
    od
}
