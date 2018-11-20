#include "common.h"

int main(void)
{
	int Begin_Time, User_Time;
	int i;
	int ctr0,ctr1,ctr2,ctr3;
	int ctr00,ctr11,ctr22,ctr33;

	printf("Hello world!\n");

	REG32(0x99000000) = 0;
	REG32(0x99000004) = 0;
	REG32(0x99000008) = 0;
	REG32(0x9900000c) = 0;
	ctr0 = REG32(0x99000000);
	ctr1 = REG32(0x99000004);
	ctr2 = REG32(0x99000008);
	ctr3 = REG32(0x9900000c);

	Begin_Time = get_timer(0);

	for (i=0; i<3; i++) {
		led(i); /* Set the led display on the card */
		printf("%d\n",i);
		sleep(1); /* sleep 1 s */
	}

	User_Time = get_timer(Begin_Time);
	printf("Time= %d s\n", User_Time);
	
	ctr00 = REG32(0x99000000);
	ctr11 = REG32(0x99000004);
	ctr22 = REG32(0x99000008);
	ctr33 = REG32(0x9900000c);
	printf("ctr0: %d \n", ctr0);
	printf("ctr1: %d \n", ctr1);
	printf("ctr2: %d \n", ctr2);
	printf("ctr3: %d \n", ctr3);
	printf("ctr00: %d \n", ctr00);
	printf("ctr11: %d \n", ctr11);
	printf("ctr22: %d \n", ctr22);
	printf("ctr33: %d \n", ctr33);
	
	

	return(0);
}
