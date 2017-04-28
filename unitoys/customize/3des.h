/***************************************************************************************
****************************************************************************************
* FILE		: 3des.h
* Description	: 3des process
*			  
* Copyright (c) 2011.11~2012.2 by wuzhixiong. All Rights Reserved.
* 
* History:
* Version		Name       		Date			Description
   1.0		wuzhixiong	2012/02/08	     Initial Version (MCU System)
 
****************************************************************************************
****************************************************************************************/
#ifndef __3DES_H__
#define __3DES_H__

#ifndef uchar
typedef unsigned char uchar;
#endif


typedef enum {
    DT_ECB = 0,
    DT_CBC
}DesType;

void tdes_encrypt(uchar *data, uchar *key);
void encrypt_key(uchar *key);
void decrypt_key(uchar *key);
void generate_tmp_key(uchar *key);
unsigned char increase_ksn_counter(unsigned char *ori_ksn_counter);
void generate_current_key(unsigned char *ksn, unsigned char *init_key, unsigned char* tmp_key, unsigned char *output_key);
void tdes_encrypt_for_ecb(unsigned char* pBuffer, int len, unsigned char* pKey);
void tdes_decrypt_for_ecb(unsigned char* pBuffer, int len, unsigned char* pKey);
void tdes_encrypt_for_cbc(unsigned char* pBuffer, int len, unsigned char* pKey, unsigned char* pVi);
void generate_init_key_by_bdk(unsigned char *base_derived_key, unsigned char *ksn, unsigned char *output_init_key);
#endif // __3DES_H__

