void jacobi(doubl* x1, doubl* x2, doubl* x3, doubl* x4, doubl* x5, doubl* x1_end, doubl* x2_end, doubl* x3_end, doubl* x4_end, doubl* x5_end)
{

	const doubl a[25] = {0.999985, 0.076920, 0.074081, 0.000000, 0.000000, 0.000000, 0.999985, 0.000000, 0.071426, 0.068970, 0.039993, 0.076920, 0.999985, 0.142853, 0.068970, 0.080002, 0.000000, 0.074081, 0.999985, 0.068970, 0.039993, 0.115387, 0.037033, 0.000000, 0.999985, };
	const doubl y[5] = {0.199997, 0.333328, 0.428574, 0.500000, 0.555557};

	doubl x1_local = *x1;
	doubl x2_local = *x2;
	doubl x3_local = *x3;
	doubl x4_local = *x4;
	doubl x5_local = *x5;

	doubl x1_new,x2_new,x3_new,x4_new,x5_new;
	doubl mul_11,mul_12,mul_13,mul_14,mul_15,mul_21,mul_22,mul_23,mul_24,mul_25;
	doubl mul_31,mul_32,mul_33,mul_34,mul_35,mul_41,mul_42,mul_43,mul_44,mul_45;
	doubl mul_51,mul_52,mul_53,mul_54,mul_55;


	mul_12 = x2_local*a[1];
	mul_13 = x3_local*a[2];
	mul_14 = x4_local*a[3];
	mul_15 = x5_local*a[4];
	
	
	mul_21 = x1_local*a[5];
	mul_23 = x3_local*a[7];
	mul_24 = x4_local*a[8];
	mul_25 = x5_local*a[9];
	
	mul_31 = x1_local*a[10];
	mul_32 = x2_local*a[11];
	mul_34 = x4_local*a[13];
	mul_35 = x5_local*a[14];
	
	mul_41 = x1_local*a[15];
	mul_42 = x2_local*a[16];
	mul_43 = x3_local*a[17];
	mul_45 = x5_local*a[19];
	
	mul_51 = x1_local*a[20];
	mul_52 = x2_local*a[21];
	mul_53 = x3_local*a[22];
	mul_54 = x4_local*a[23];

	x1_new = y[0]-mul_12-mul_13-mul_14-mul_15;
	x2_new = y[1]-mul_21-mul_23-mul_24-mul_25;
	x3_new = y[2]-mul_31-mul_32-mul_34-mul_35;
	x4_new = y[3]-mul_41-mul_42-mul_43-mul_45;
	x5_new = y[4]-mul_51-mul_52-mul_53-mul_54;

	*x1_end = x1_new;
	*x2_end = x2_new;
	*x3_end = x3_new;
	*x4_end = x4_new;
	*x5_end = x5_new;

	return;
}
