#include "fir.h"
#include <defs.h>
int taps[N] = {0,-10,-9,23,56,63,56,23,-9,-10,0};
void __attribute__ ( ( section ( ".mprjram" ) ) ) initfir() {
	reg_user_start = 1;
}

int __attribute__ ( ( section ( ".mprjram" ) ) ) fir(){
	initfir();
	int n;
	int y;
	for(n = 0; n < 63; n++) {
            reg_user_x = n;
	    reg_user_y;
        }
        reg_user_x = n;
	y = reg_user_y;
	return y;
}
