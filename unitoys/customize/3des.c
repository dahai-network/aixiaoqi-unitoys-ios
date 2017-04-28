/***************************************************************************************
****************************************************************************************
* FILE		: 3des.c
* Description	: 3des process
*			  
* Copyright (c) 2011.11~2012.2 by wuzhixiong. All Rights Reserved.
* 
* History:
* Version		Name       		Date			Description
   1.0		wuzhixiong	2012/02/08	     Initial Version (MCU System)
 
****************************************************************************************
****************************************************************************************/

#include "3des.h"
#include "string.h"

#define DES_ENCRYPT 0
#define DES_DECRYPT 1

//unsigned char key[16]={0,1,2,3,4,5,6,7,8,9,1,2,3,4,5,6};
//��Կ����������ʱ�������ƶ���λ��
const unsigned char Table_Move_Left[16] = 
   {1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1};
const unsigned char Table_Move_Right[16] = 
   {0, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1};


// S�� 
const unsigned char Table_SBOX[8][64] = 
{
       {
              0xe,0x0,0x4,0xf,0xd,0x7,0x1,0x4,0x2,0xe,0xf,0x2,0xb,
              0xd,0x8,0x1,0x3,0xa,0xa,0x6,0x6,0xc,0xc,0xb,0x5,0x9,
              0x9,0x5,0x0,0x3,0x7,0x8,0x4,0xf,0x1,0xc,0xe,0x8,0x8,
              0x2,0xd,0x4,0x6,0x9,0x2,0x1,0xb,0x7,0xf,0x5,0xc,0xb,
              0x9,0x3,0x7,0xe,0x3,0xa,0xa,0x0,0x5,0x6,0x0,0xd  
       },

       { 
              0xf,0x3,0x1,0xd,0x8,0x4,0xe,0x7,0x6,0xf,0xb,0x2,0x3,
              0x8,0x4,0xe,0x9,0xc,0x7,0x0,0x2,0x1,0xd,0xa,0xc,0x6,
              0x0,0x9,0x5,0xb,0xa,0x5,0x0,0xd,0xe,0x8,0x7,0xa,0xb,
              0x1,0xa,0x3,0x4,0xf,0xd,0x4,0x1,0x2,0x5,0xb,0x8,0x6,
              0xc,0x7,0x6,0xc,0x9,0x0,0x3,0x5,0x2,0xe,0xf,0x9
       },
       
       { 
              0xa,0xd,0x0,0x7,0x9,0x0,0xe,0x9,0x6,0x3,0x3,0x4,0xf,
              0x6,0x5,0xa,0x1,0x2,0xd,0x8,0xc,0x5,0x7,0xe,0xb,0xc,
              0x4,0xb,0x2,0xf,0x8,0x1,0xd,0x1,0x6,0xa,0x4,0xd,0x9,
              0x0,0x8,0x6,0xf,0x9,0x3,0x8,0x0,0x7,0xb,0x4,0x1,0xf,
              0x2,0xe,0xc,0x3,0x5,0xb,0xa,0x5,0xe,0x2,0x7,0xc                                          
       },
       
       { 
              0x7,0xd,0xd,0x8,0xe,0xb,0x3,0x5,0x0,0x6,0x6,0xf,0x9,
              0x0,0xa,0x3,0x1,0x4,0x2,0x7,0x8,0x2,0x5,0xc,0xb,0x1,
              0xc,0xa,0x4,0xe,0xf,0x9,0xa,0x3,0x6,0xf,0x9,0x0,0x0,
              0x6,0xc,0xa,0xb,0x1,0x7,0xd,0xd,0x8,0xf,0x9,0x1,0x4,
              0x3,0x5,0xe,0xb,0x5,0xc,0x2,0x7,0x8,0x2,0x4,0xe                         
       },
       
       { 
              0x2,0xe,0xc,0xb,0x4,0x2,0x1,0xc,0x7,0x4,0xa,0x7,0xb,
              0xd,0x6,0x1,0x8,0x5,0x5,0x0,0x3,0xf,0xf,0xa,0xd,0x3,
              0x0,0x9,0xe,0x8,0x9,0x6,0x4,0xb,0x2,0x8,0x1,0xc,0xb,
              0x7,0xa,0x1,0xd,0xe,0x7,0x2,0x8,0xd,0xf,0x6,0x9,0xf,
              0xc,0x0,0x5,0x9,0x6,0xa,0x3,0x4,0x0,0x5,0xe,0x3
       },
       
       { 
              0xc,0xa,0x1,0xf,0xa,0x4,0xf,0x2,0x9,0x7,0x2,0xc,0x6,
              0x9,0x8,0x5,0x0,0x6,0xd,0x1,0x3,0xd,0x4,0xe,0xe,0x0,
              0x7,0xb,0x5,0x3,0xb,0x8,0x9,0x4,0xe,0x3,0xf,0x2,0x5,
              0xc,0x2,0x9,0x8,0x5,0xc,0xf,0x3,0xa,0x7,0xb,0x0,0xe,
              0x4,0x1,0xa,0x7,0x1,0x6,0xd,0x0,0xb,0x8,0x6,0xd
       },
       
       { 
              0x4,0xd,0xb,0x0,0x2,0xb,0xe,0x7,0xf,0x4,0x0,0x9,0x8,
              0x1,0xd,0xa,0x3,0xe,0xc,0x3,0x9,0x5,0x7,0xc,0x5,0x2,
              0xa,0xf,0x6,0x8,0x1,0x6,0x1,0x6,0x4,0xb,0xb,0xd,0xd,
              0x8,0xc,0x1,0x3,0x4,0x7,0xa,0xe,0x7,0xa,0x9,0xf,0x5,
              0x6,0x0,0x8,0xf,0x0,0xe,0x5,0x2,0x9,0x3,0x2,0xc
       },
       
       { 
              0xd,0x1,0x2,0xf,0x8,0xd,0x4,0x8,0x6,0xa,0xf,0x3,0xb,
              0x7,0x1,0x4,0xa,0xc,0x9,0x5,0x3,0x6,0xe,0xb,0x5,0x0,
              0x0,0xe,0xc,0x9,0x7,0x2,0x7,0x2,0xb,0x1,0x4,0xe,0x1,
              0x7,0x9,0x4,0xc,0xa,0xe,0x8,0x2,0xd,0x0,0xf,0x6,0xc,
              0xa,0x9,0xd,0x0,0xf,0x3,0x3,0x5,0x5,0x6,0x8,0xb
       } 
};

#define TST_BIT(p_in, bit_num)	(p_in[(bit_num-1)>>3] & (0x80>>((bit_num-1)&0x07))  )	

#define PERMUTATION_ONE_BYTE(p_in,b_num1,b_num2,b_num3,b_num4,b_num5,b_num6,b_num7,b_num8, cout)		\
{	\
	cout = 0;									\
	if(TST_BIT(p_in, b_num1))	cout |= 0x80;	\
	if(TST_BIT(p_in, b_num2))	cout |= 0x40;	\
	if(TST_BIT(p_in, b_num3))	cout |= 0x20;	\
	if(TST_BIT(p_in, b_num4))	cout |= 0x10;	\
	if(TST_BIT(p_in, b_num5))	cout |= 0x08;	\
	if(TST_BIT(p_in, b_num6))	cout |= 0x04;	\
	if(TST_BIT(p_in, b_num7))	cout |= 0x02;	\
	if(TST_BIT(p_in, b_num8))	cout |= 0x01;	\
}

//////////////////////// ��ʼ�û� /////////////////////
/*
const unsigned char Table1_IP[64] = 
{ 
   58, 50, 42, 34, 26, 18, 10, 2,	60, 52, 44, 36, 28, 20, 12, 4, 
   62, 54, 46, 38, 30, 22, 14, 6,	64, 56, 48, 40, 32, 24, 16, 8, 
   57, 49, 41, 33, 25, 17,  9, 1,	59, 51, 43, 35, 27, 19, 11, 3, 
   61, 53, 45, 37, 29, 21, 13, 5,	63, 55, 47, 39, 31, 23, 15, 7 
}; */
//////////////////////////////////////////////////////
#define		PermutationDataFirst(p_in, p_out, cout)		\
	{	\
		PERMUTATION_ONE_BYTE(p_in,	58, 50, 42, 34, 26, 18, 10, 2, p_out[0]);	\
		PERMUTATION_ONE_BYTE(p_in,	60, 52, 44, 36, 28, 20, 12, 4, p_out[1]);	\
		PERMUTATION_ONE_BYTE(p_in,	62, 54, 46, 38, 30, 22, 14, 6, p_out[2]);	\
		PERMUTATION_ONE_BYTE(p_in,	64, 56, 48, 40, 32, 24, 16, 8, p_out[3]);	\
		PERMUTATION_ONE_BYTE(p_in,	57, 49, 41, 33, 25, 17,  9, 1, p_out[4]);	\
		PERMUTATION_ONE_BYTE(p_in,	59, 51, 43, 35, 27, 19, 11, 3, p_out[5]);	\
		PERMUTATION_ONE_BYTE(p_in,	61, 53, 45, 37, 29, 21, 13, 5, p_out[6]);	\
		PERMUTATION_ONE_BYTE(p_in,	63, 55, 47, 39, 31, 23, 15, 7, p_out[7]);	\
	}


////////////////////////////����ĩ�û� ///////////////////////////////////
/*
const unsigned char Table2_InverseIP[64] = 
{ 
   40, 8, 48, 16, 56, 24, 64, 32,	39, 7, 47, 15, 55, 23, 63, 31, 
   38, 6, 46, 14, 54, 22, 62, 30,	37, 5, 45, 13, 53, 21, 61, 29, 
   36, 4, 44, 12, 52, 20, 60, 28,	35, 3, 43, 11, 51, 19, 59, 27, 
   34, 2, 42, 10, 50, 18, 58, 26,	33, 1, 41,  9, 49, 17, 57, 25 
}; */
//////////////////////////////////////////////////////////////////////////
#define		PermutationDataLast(p_in, p_out, cout)		\
	{	\
		PERMUTATION_ONE_BYTE(p_in,	40, 8, 48, 16, 56, 24, 64, 32, p_out[0]);	\
		PERMUTATION_ONE_BYTE(p_in,	39, 7, 47, 15, 55, 23, 63, 31, p_out[1]);	\
		PERMUTATION_ONE_BYTE(p_in,	38, 6, 46, 14, 54, 22, 62, 30, p_out[2]);	\
		PERMUTATION_ONE_BYTE(p_in,	37, 5, 45, 13, 53, 21, 61, 29, p_out[3]);	\
		PERMUTATION_ONE_BYTE(p_in,	36, 4, 44, 12, 52, 20, 60, 28, p_out[4]);	\
		PERMUTATION_ONE_BYTE(p_in,	35, 3, 43, 11, 51, 19, 59, 27, p_out[5]);	\
		PERMUTATION_ONE_BYTE(p_in,	34, 2, 42, 10, 50, 18, 58, 26, p_out[6]);	\
		PERMUTATION_ONE_BYTE(p_in,	33, 1, 41,  9, 49, 17, 57, 25, p_out[7]);	\
	}


/*
// ��Կ��ʼ�û�,�õ�һ��56λ����Կ���� 
const unsigned char Table4_PC1[56] = { 
   57, 49, 41, 33, 25, 17,  9,  1,		58, 50, 42, 34, 26, 18, 10,  2, 
   59, 51, 43, 35, 27, 19, 11,  3,		60, 52, 44, 36, 63, 55, 47, 39, 
   31, 23, 15,  7, 62, 54, 46, 38,		30, 22, 14,  6, 61, 53, 45, 37,			29, 21, 13,  5, 28, 20, 12,  4 
}; 
*/
#define		PermutationKeyFirst(p_in, p_out, cout)		\
	{	\
		PERMUTATION_ONE_BYTE(p_in,	57, 49, 41, 33, 25, 17,  9,  1, p_out[0]);	\
		PERMUTATION_ONE_BYTE(p_in,	58, 50, 42, 34, 26, 18, 10,  2, p_out[1]);	\
		PERMUTATION_ONE_BYTE(p_in,	59, 51, 43, 35, 27, 19, 11,  3, p_out[2]);	\
		PERMUTATION_ONE_BYTE(p_in,	60, 52, 44, 36, 63, 55, 47, 39, p_out[3]);	\
		PERMUTATION_ONE_BYTE(p_in,	31, 23, 15,  7, 62, 54, 46, 38, p_out[4]);	\
		PERMUTATION_ONE_BYTE(p_in,	30, 22, 14,  6, 61, 53, 45, 37, p_out[5]);	\
		PERMUTATION_ONE_BYTE(p_in,	29, 21, 13,  5, 28, 20, 12,  4, p_out[6]);	\
	}


/*��Կѹ���û�
const unsigned char Table5_PC2[48] = 
{ 
   14, 17, 11, 24,  1,  5,  3, 28,		15,  6, 21, 10, 23, 19, 12,  4, 
   26,  8, 16,  7, 27, 20, 13,  2,		41, 52, 31, 37, 47, 55, 30, 40, 
   51, 45, 33, 48, 44, 49, 39, 56,		34, 53, 46, 42, 50, 36, 29, 32 
}; 
Permutation(key_tmp, sub_key,5 , 48);//Table5_PC2�û���5�ű�
��Կ�ڶ�����С��λ���õ�һ��48λ������Կ������subkey��	
*/
#define		PermutationSubkey(p_in, p_out, cout)		\
	{	\
		PERMUTATION_ONE_BYTE(p_in,	14, 17, 11, 24,  1,  5,  3, 28, p_out[0]);	\
		PERMUTATION_ONE_BYTE(p_in,	15,  6, 21, 10, 23, 19, 12,  4, p_out[1]);	\
		PERMUTATION_ONE_BYTE(p_in,	26,  8, 16,  7, 27, 20, 13,  2, p_out[2]);	\
		PERMUTATION_ONE_BYTE(p_in,	41, 52, 31, 37, 47, 55, 30, 40, p_out[3]);	\
		PERMUTATION_ONE_BYTE(p_in,	51, 45, 33, 48, 44, 49, 39, 56, p_out[4]);	\
		PERMUTATION_ONE_BYTE(p_in,	34, 53, 46, 42, 50, 36, 29, 32, p_out[5]);	\
	}


/*��չ�û�
const unsigned char Table3_E[48] = 
{ 
	32,  1,  2,  3,  4,  5,  4,  5,		 6,  7,  8,  9,  8,  9, 10, 11,
	12, 13, 12, 13, 14, 15, 16, 17, 	16, 17, 18, 19, 20, 21, 20, 21,
	22, 23, 24, 25, 24, 25, 26, 27,		28, 29, 28, 29, 30, 31, 32,  1 
}; 
*/
#define		PermutationAndExtend(p_in, p_out, cout)		\
	{	\
		PERMUTATION_ONE_BYTE(p_in,	32,  1,  2,  3,  4,  5,  4,  5, p_out[0]);		\
		PERMUTATION_ONE_BYTE(p_in,	 6,  7,  8,  9,  8,  9, 10, 11, p_out[1]);		\
		PERMUTATION_ONE_BYTE(p_in,	12, 13, 12, 13, 14, 15, 16, 17, p_out[2]);		\
		PERMUTATION_ONE_BYTE(p_in,	16, 17, 18, 19, 20, 21, 20, 21, p_out[3]);		\
		PERMUTATION_ONE_BYTE(p_in,	22, 23, 24, 25, 24, 25, 26, 27, p_out[4]);		\
		PERMUTATION_ONE_BYTE(p_in,	28, 29, 28, 29, 30, 31, 32,  1, p_out[5]);		\
	}


/*
const unsigned char Table6_P[32] = 
{ 
	16, 7, 20, 21, 29, 12, 28, 17,		 1, 15, 23, 26, 5, 18, 31, 10, 
	2,  8, 24, 14, 32, 27, 3,  9,		19, 13, 30, 6, 22, 11,  4,  25 
}; */
// P���û� 
#define		PermutationPbox(p_in, p_out, cout)		\
	{	\
		PERMUTATION_ONE_BYTE(p_in,	16, 7, 20, 21, 29, 12, 28, 17, p_out[0]);	\
		PERMUTATION_ONE_BYTE(p_in,	 1,15, 23, 26,  5, 18, 31, 10, p_out[1]);	\
		PERMUTATION_ONE_BYTE(p_in,	 2, 8, 24, 14, 32, 27,  3,  9, p_out[2]);	\
		PERMUTATION_ONE_BYTE(p_in,	19,13, 30,  6, 22, 11,  4, 25, p_out[3]);	\
	}


//����С��λ���56λ��Կ��Ϊ��28λ����28λ,
//����ʱ����28λ����28λ�ֱ�ѭ������, �õ�һ��������
#define move_left_rotation(key_tmp,cin,cout,offset)		\
	do	\
	{	\
		cin = key_tmp[0];	cout = key_tmp[3];	\
		\
		key_tmp[0] <<= 1;	{ if(key_tmp[1] & 0x80)	key_tmp[0] |= 0x01;	}	\
		key_tmp[1] <<= 1;	{ if(key_tmp[2] & 0x80)	key_tmp[1] |= 0x01;	}	\
		key_tmp[2] <<= 1;	{ if(key_tmp[3] & 0x80)	key_tmp[2] |= 0x01;	}	\
		\
		key_tmp[3] <<= 1;	key_tmp[3] &= (~0x10);	\
		{ if(cin & 0x80)	key_tmp[3] |= (0x01<<4);	}	{ if(key_tmp[4] & 0x80)	key_tmp[3] |= 0x01;	}	\
		\
		key_tmp[4] <<= 1;	{ if(key_tmp[5] & 0x80)	key_tmp[4] |= 0x01;	}	\
		key_tmp[5] <<= 1;	{ if(key_tmp[6] & 0x80)	key_tmp[5] |= 0x01;	}	\
		key_tmp[6] <<= 1;	{ if(cout & 0x08)		key_tmp[6] |= 0x01;	}	\
	}	\
	while(--offset);


//����С��λ���56λ��Կ��Ϊ��28λ����28λ,
//����ʱ����28λ����28λ�ֱ�ѭ������, �õ�һ��������
#define move_rigth_rotation(key_tmp,cin,cout,offset)		\
	while(offset--)		\
	{		\
		cin = key_tmp[6];	cout = key_tmp[3];		\
		\
		key_tmp[6] >>= 1;	{ if(key_tmp[5] & 0x01)	key_tmp[6] |= 0x80;	}		\
		key_tmp[5] >>= 1;	{ if(key_tmp[4] & 0x01)	key_tmp[5] |= 0x80;	}		\
		key_tmp[4] >>= 1;	{ if(key_tmp[3] & 0x01)	key_tmp[4] |= 0x80;	}		\
		\
		key_tmp[3] >>= 1;	key_tmp[3] &= (~0x08);		\
		{ if(cin & 0x01)	key_tmp[3] |= 0x08;	}	{ if(key_tmp[2] & 0x01)	key_tmp[3] |= 0x80;	}		\
		\
		key_tmp[2] >>= 1;	{ if(key_tmp[1] & 0x01)	key_tmp[2] |= 0x80;	}		\
		key_tmp[1] >>= 1;	{ if(key_tmp[0] & 0x01)	key_tmp[1] |= 0x80;	}		\
		key_tmp[0] >>= 1;	{ if(cout & 0x10)		key_tmp[0] |= 0x80;	}		\
	}		

///////////////////////////////////////////////////////////////
//   �� �� �� : des
//   �������� : DES�ӽ���
//   ������� : ���ݱ�׼��DES�����㷨�������64λ��Կ��64λ���Ľ��м�/����
//            ������/���ܽ���洢��p_output��
//   ʱ    �� : 2006��9��2��
//   �� �� ֵ : 
//   ����˵�� :   const char * p_data      ����, ����ʱ��������, ����ʱ��������, 64λ(8�ֽ�)
//            const char * p_key      ����, ��Կ, 64λ(8�ֽ�)
//            char * p_output         ���, ����ʱ�������, ����ʱ��������, 64λ(8�ֽ�)
//            unsigned char mode            DES_ENCRYPT ����  DES_DECRYPT ����
///////////////////////////////////////////////////////////////
void des( unsigned char  p_data[],  unsigned char  p_key[], unsigned char mode)
{
#define p_left	p_output
#define p_right	((unsigned char *)(p_output+4))
    unsigned char cin,cout;
    unsigned char offset;

    unsigned char loop = 0;     //16�������ѭ��������
    unsigned char key_tmp[8];   //��Կ����ʱ�洢�м���
    unsigned char sub_key[6];   //���ڴ洢����Կ

    unsigned char p_right_ext[8];   //R[i]������չ�û����ɵ�48λ����(6�ֽ�), �����ս���Ĵ洢
    unsigned char p_right_s[4];      //����S_BOX�û����32λ����(4�ֽ�)
    unsigned char p_output[8];

   //���ĳ�ʼ���û�
	p_right_ext[0] = p_data[0];		p_right_ext[1] = p_data[1];		p_right_ext[2] = p_data[2];		p_right_ext[3] = p_data[3];	
	p_right_ext[4] = p_data[4];		p_right_ext[5] = p_data[5];		p_right_ext[6] = p_data[6];		p_right_ext[7] = p_data[7];	
	PermutationDataFirst(p_right_ext, p_output, cout);

   //��Կ��һ����С��λ, �õ�һ��56λ����Կ����
	p_right_ext[0] = p_key[0];		p_right_ext[1] = p_key[1];		p_right_ext[2] = p_key[2];		p_right_ext[3] = p_key[3];	
	p_right_ext[4] = p_key[4];		p_right_ext[5] = p_key[5];		p_right_ext[6] = p_key[6];		p_right_ext[7] = p_key[7];	
	PermutationKeyFirst(p_right_ext, key_tmp,cout);


   for(loop = 0; loop < 16; loop++)
   {
		if(mode == DES_ENCRYPT)
		{
			offset = Table_Move_Left[loop];
			move_left_rotation(key_tmp,cin,cout,offset);
		}
		else
		{
			offset = Table_Move_Right[loop];
			move_rigth_rotation(key_tmp,cin,cout,offset);
		}

		PermutationSubkey(key_tmp, sub_key, cout);
		PermutationAndExtend(p_right, p_right_ext, cout);


		//��R0��չ�û���õ���48λ����(6�ֽ�)������Կ�������     // Xor(p_right_ext, sub_key, 6);
		p_right_ext[0] ^= sub_key[0];		p_right_ext[1] ^= sub_key[1];	p_right_ext[2] ^= sub_key[2];
		p_right_ext[3] ^= sub_key[3];		p_right_ext[4] ^= sub_key[4];	p_right_ext[5] ^= sub_key[5];

      
		{//S_BOX�û�
			p_right_s[0] = (Table_SBOX[0][p_right_ext[0]>>2]<<4);	
			offset = ((p_right_ext[0]&0x3)<<4);		p_right_s[0] |= Table_SBOX[1][(p_right_ext[1]>>4) | offset ]; //byte0

			offset = (p_right_ext[1]<<4);	offset |= (p_right_ext[2]>>4);		offset >>= 2;	p_right_s[1] = (Table_SBOX[2][offset]<<4);
			p_right_s[1] |= Table_SBOX[3][p_right_ext[2] & 0x3f]; //byte1

			p_right_s[2] = (Table_SBOX[4][p_right_ext[3]>>2]<<4);	
			offset = ((p_right_ext[3]&0x3)<<4);		p_right_s[2] |= Table_SBOX[5][(p_right_ext[4]>>4) | offset ]; //byte2

			offset = (p_right_ext[4]<<4);	offset |= (p_right_ext[5]>>4);		offset >>= 2;	p_right_s[3] = (Table_SBOX[6][offset]<<4);
			p_right_s[3] |= Table_SBOX[7][p_right_ext[5] & 0x3f]; //byte3
		}

		PermutationPbox(p_right_s, p_right_ext, cout);

		//Xor(p_right_ext, p_left, 4);
		p_right_ext[0] ^= p_left[0];		p_right_ext[1] ^= p_left[1];	p_right_ext[2] ^= p_left[2];	  p_right_ext[3] ^= p_left[3];	

		//memcpy(p_left, p_right, 4);
		p_left[0] = p_right[0];		p_left[1] = p_right[1];		p_left[2] = p_right[2];		p_left[3] = p_right[3];	
		//memcpy(p_right, p_right_ext, 4);
		p_right[0] = p_right_ext[0];	p_right[1] = p_right_ext[1];		p_right[2] = p_right_ext[2];		p_right[3] = p_right_ext[3];	
  }

   //memcpy(p_right_ext,   p_right, 4);
	p_right_ext[0] = p_right[0];	p_right_ext[1] = p_right[1];	p_right_ext[2] = p_right[2];	p_right_ext[3] = p_right[3];
 
   //memcpy(&p_right_ext[4], p_left, 4);
	p_right_ext[4] = p_left[0];	p_right_ext[5] = p_left[1];	p_right_ext[6] = p_left[2];	p_right_ext[7] = p_left[3];


   //����ٽ���һ�����û�, �õ����ռ��ܽ��
   PermutationDataLast(p_right_ext, p_output, cout);

   //memcpy(p_data, p_output, 8);	//������ܺ�Ľ��
	p_data[0] = p_output[0];	p_data[1] = p_output[1];	p_data[2] = p_output[2];	p_data[3] = p_output[3];	
	p_data[4] = p_output[4];	p_data[5] = p_output[5];	p_data[6] = p_output[6];	p_data[7] = p_output[7];	
}

void tdes_encrypt(uchar *data, uchar *key)
{
    des(data, key, DES_ENCRYPT);
    des(data, key + 8, DES_DECRYPT);
    des(data, key, DES_ENCRYPT);
}

void tdes_decrypt(uchar *data, uchar *key)
{
	des(data, key, DES_DECRYPT);
	des(data, key + 8, DES_ENCRYPT);
    des(data, key, DES_DECRYPT);
}

/******************************************************************/
//��ɢ��Կ��(һ��)
//���������
//random    : �����
//key       : ����Կ
//���������
//key       : ��ɢ���key
/******************************************************************/
void div_i_key(uchar *random, uchar *key)
{
   uchar tmp[8];
	 uchar i = 0;
   for (i = 0; i < 8; i++) {
      tmp[i]= 0xFF - random[i];
   }

   tdes_encrypt(random, key);
   tdes_encrypt(tmp, key);
   memcpy(key, random, 8);
   memcpy(key + 8, tmp, 8);
}

void xor_buf(unsigned char *input_buf1, unsigned char *input_buf2, unsigned char *output_buf, unsigned char num)
{
    unsigned char i;
    for(i = 0; i < num; i++)
    {
        output_buf[i] = input_buf1[i] ^ input_buf2[i];
    }
}

void nonreversible_key_generation(unsigned char *ksn, unsigned char *input_key, unsigned char *output_key)
{
    xor_buf(ksn, input_key + 8, output_key + 8, 8);	//Crypto Register-1 XORed with the right half of the Key Register goes to Crypto Register-2(right half of output_key).
    des(output_key + 8, input_key, DES_ENCRYPT);//Crypto Register-2 DEA-encrypted using, as the key, the left half of the Key Register goes to Crypto Register-2.
    xor_buf(output_key + 8, input_key + 8, output_key + 8, 8);//Crypto Register-2 XORed with the right half of the Key Register goes to Crypto Register-2.

    //XOR the Key Register with hexadecimal C0C0 C0C0 0000 0000 C0C0 C0C0 0000 0000.
    input_key[0] ^= 0xc0;	input_key[1] ^= 0xc0;	input_key[2] ^= 0xc0;	input_key[3] ^= 0xc0;
    input_key[0+8] ^= 0xc0;	input_key[1+8] ^= 0xc0;	input_key[2+8] ^= 0xc0;	input_key[3+8] ^= 0xc0;

    xor_buf(ksn, input_key+8, output_key, 8);	//Crypto Register-1 XORed with the right half of the Key Register goes to Crypto Register-1(left half of output_key).
    des(output_key, input_key, DES_ENCRYPT);//Crypto Register-1 DEA-encrypted using, as the key, the left half of the Key Register goes to Crypto Register-1.
    xor_buf(output_key, input_key+8, output_key, 8);//Crypto Register-1 XORed with the right half of the Key Register goes to Crypto Register-1.
}

//ksn: buffer address of 8 least_significant bytes including ksn counter
//init_key: buffer address of Initial Loaded Key which length is 16 bytes
//tmp_key: buffer used to store the temporary Key of calculation( the buffer must allocated by caller, and size should be 16 bytes or larger)
//output_key: buffer used to store the Current Key of current ksn( the buffer must allocated by caller, and size should be 16 bytes or larger)
void generate_current_key(unsigned char *ksn, unsigned char *init_key, unsigned char* tmp_key, unsigned char *output_key)
{
    unsigned char ksn_counter[3],bit_mask,byte_offset;
    unsigned char i;

    ksn_counter[0] = ksn[5];
    ksn_counter[1] = ksn[6];
    ksn_counter[2] = ksn[7];
    ksn[5] &= 0xE0;
    ksn[6] = 0x0;
    ksn[7] &= 0x0;		//clear the 21 least-significant bits in KSN
    bit_mask = 0x10;
    memcpy(tmp_key, init_key, 16);
    for(i = 3; i < 24; i++)
    {
        byte_offset = i >> 3;
        if(ksn_counter[byte_offset] & bit_mask)
        {
            ksn[5 + byte_offset] |= bit_mask;
            nonreversible_key_generation(ksn, tmp_key, output_key);
            memcpy(tmp_key, output_key, 16);
        }

        bit_mask >>= 1;
        if(bit_mask == 0)	bit_mask = 0x80;
    }

    ksn[5] = ksn_counter[0];
    ksn[6] = ksn_counter[1];
    ksn[7] = ksn_counter[2];
}

#define KSN_COUNTER_OVER_1M				1
#define NEW_KSN_COUNTER_GENERATED_OK	0
//this function will increase KSN counter and skip all the counter which 'ONE's  number is greater than 10
//if all bits of new counter are zero, return: KSN_COUNTER_OVER_1M, otherwise return: NEW_KSN_COUNTER_GENERATED_OK
unsigned char increase_ksn_counter(unsigned char *ori_ksn_counter)
{
    unsigned char i;
    unsigned char num_of_bit_one, bit_mask, byte_offset;
    unsigned char least_significant_one_pos, least_significant_one_bit_mask;
    unsigned char ksn_counter[3];

    ksn_counter[0] = ori_ksn_counter[0] & 0x1F;
    ksn_counter[1] = ori_ksn_counter[1];
    ksn_counter[2] = ori_ksn_counter[2];

    least_significant_one_pos = 0x80;
    bit_mask = 0x01;
    num_of_bit_one = 0;
    for(i = 0; i < 21; i++)
    {
        byte_offset = 2 - (i>>3);
        if(ksn_counter[byte_offset] & bit_mask)
        {
            num_of_bit_one += 1;
            if(least_significant_one_pos & 0x80)
            {
                least_significant_one_pos = i;
                least_significant_one_bit_mask = bit_mask;
            }
        }

        bit_mask <<= 1;
        if(bit_mask == 0) bit_mask = 0x01;
    }

    if(num_of_bit_one > 10) return KSN_COUNTER_OVER_1M;
    if(num_of_bit_one < 10)
    {
        ksn_counter[2] += 1;
        if(ksn_counter[2] == 0x0)
        {
            ksn_counter[1] += 1;
            if(ksn_counter[1] == 0x0) ksn_counter[0] += 1;
        }
    }
    else
    {
        //the number of 'ONE' is 10
        byte_offset = 2 - (least_significant_one_pos>>3);
        if(byte_offset == 2)
        {
            ksn_counter[2] += least_significant_one_bit_mask;
            if(ksn_counter[2] == 0)
            {
                ksn_counter[1] += 1;
                if(ksn_counter[1] == 0x0)
                    ksn_counter[0] += 1;
            }
        }
        else if(byte_offset == 1)
        {
            ksn_counter[1] += least_significant_one_bit_mask;
            if(ksn_counter[1] == 0)
            {
                ksn_counter[0] += 1;
                if(ksn_counter[0] > 0x1f)
                    return KSN_COUNTER_OVER_1M;
            }
        }
        else
        {
            return KSN_COUNTER_OVER_1M;
        }
    }

    ori_ksn_counter[0] &= 0xE0;
    ori_ksn_counter[0] |= ksn_counter[0];
    ori_ksn_counter[1] = ksn_counter[1];
    ori_ksn_counter[2] = ksn_counter[2];
    return NEW_KSN_COUNTER_GENERATED_OK;
}


void generate_tmp_key(uchar *key)
{
    uchar k1 = 0xab;
    uchar k2 = 0xcd;
    uchar i = 0;
    for(i = 0; i < 8; i++)
    {
        key[i] = (k1 << i) + (k1 >> (8 - i)); //��ѭ����iλ
        key[i] ^= (k2 >> i) + (k2 << (8 - i)); //��ѭ����iλ
    }
}

void encrypt_key(uchar *key)
{
    uchar tmp[8];
    memset(tmp, 0, sizeof(tmp));
    generate_tmp_key(tmp);
    des(key, tmp, DES_ENCRYPT);
    des(key + 8, tmp, DES_ENCRYPT);
}

void decrypt_key(uchar *key)
{
    uchar tmp[8];
    memset(tmp, 0, sizeof(tmp));
    generate_tmp_key(tmp);
    des(key, tmp, DES_DECRYPT);
    des(key + 8, tmp, DES_DECRYPT);
}

void xorBuffer(unsigned char *des, const unsigned char *src, unsigned char len)
{
    unsigned char i;
    for(i = 0; i < len; i++)
    {
        des[i] ^= src[i];
    }
}

// Note: mac init to 0
void mac_calculate(uchar *buffer, int len, uchar* key, uchar *mac)
{
	uchar tmp[8] = {0};
	int i = 0;
	int tmpLen = (len / 8) * 8;
	for(i = 0; i < tmpLen; i += 8) {
		xorBuffer(mac, buffer + i, 8);
		des(mac, key, DES_ENCRYPT);
	}

	if (tmpLen != len) {
		memcpy(tmp, buffer + tmpLen, len - tmpLen);
		xorBuffer(mac, tmp, 8);
		des(mac, key, DES_ENCRYPT);
	}
}

void tdes_encrypt_for_cbc(unsigned char* pBuffer, int len, unsigned char* pKey, unsigned char* pVi)
{
	unsigned char * pre = pVi;
	unsigned char * cur = pBuffer;
	int i = 0;
	
	for (i = 0; i < len / 8; i++) {
		xor_buf(cur, pre, cur, 8);
		tdes_encrypt(cur, pKey);
		pre = cur;
		cur += 8;
	}
}
void tdes_encrypt_for_ecb(unsigned char* pBuffer, int len, unsigned char* pKey)
{
	int i = 0;
	for (i = 0; i < len / 8; i++) {
		tdes_encrypt(pBuffer + i * 8, pKey);
	}
}

void tdes_decrypt_for_ecb(unsigned char* pBuffer, int len, unsigned char* pKey)
{
	int i = 0;
	for (i = 0; i < len / 8; i++) {
		tdes_decrypt(pBuffer + i * 8, pKey);
	}
}

void generate_init_key_by_bdk(unsigned char *base_derived_key, unsigned char *ksn, unsigned char *output_init_key)
{
    memcpy(output_init_key,ksn,8);
    tdes_encrypt(output_init_key, base_derived_key);

    base_derived_key[0] ^= 0xc0;	base_derived_key[1] ^= 0xc0;	base_derived_key[2] ^= 0xc0;	base_derived_key[3] ^= 0xc0;
    base_derived_key[0+8] ^= 0xc0;	base_derived_key[1+8] ^= 0xc0;	base_derived_key[2+8] ^= 0xc0;	base_derived_key[3+8] ^= 0xc0;
    memcpy(output_init_key+8,ksn,8);
    tdes_encrypt(output_init_key+8, base_derived_key);
}
