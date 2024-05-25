int r_seed = 123456789, r_a = 1103515245, r_m = 1 << 31, r_c = 12345

inline rand(result) {
    r_seed = (r_a * r_seed + r_c) % r_m;
    result = ( r_seed < 0 -> -r_seed : r_seed )
}

inline randrange(min, max, result) {
    rand(result);
    result = min + result % (max - min)
}