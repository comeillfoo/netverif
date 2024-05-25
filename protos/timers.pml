int tm_count = 0, tm_should_stop = false;

active proctype time() {
    do
    :: ! tm_should_stop -> tm_count++
    od
}


