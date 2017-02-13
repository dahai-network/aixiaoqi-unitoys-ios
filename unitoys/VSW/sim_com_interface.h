
#ifndef SIM_COM_INTERFACE_H
#define SIM_COM_INTERFACE_H

#include "eos_typedef.h"

enum
{
    EN_APPEVT_NONE = 0,
    EN_APPEVT_SETSIMTYPE,//设置sim卡类型（pData=1是移动联通，2是电信）
    EN_APPEVT_CMD_SETRST,//重新初始化
    EN_APPEVT_CMD_SIMCLR,//sim命令重置
    EN_APPEVT_RSTRSP,
    EN_APPEVT_PRDATA,//预读数据
    EN_APPEVT_SIMDATA,//鉴权数据
    EN_APPEVT_SIMINFO//iccid和imsi数据
};//EN_APP_SUBEVT;

//这个是消息参数的结构体
/*chn都是传0
 evtIndex是上面那些数据
 len是pData的长度
 pData是数据*/
typedef struct stSimComAppEvt
{
	_UCHAR8  chn;	
	_UCHAR8  evtIndex;    //EN_APP_EVT
    _UINT32  len;
	_UCHAR8 *pData;
}ST_SIMCOM_APPEVT;


_INT32 SimComInit(_VOID);
_INT32 SimComEvtApp2Drv(ST_SIMCOM_APPEVT * evtMsg);
_INT32 SimComEvtDrv2App(ST_SIMCOM_APPEVT * evtMsg);

#endif

#ifndef __cdemo__CFunc__
#define __cdemo__CFunc__

#include <stdio.h>

void printSomething(char *sendStr);

#endif /* defined(__cdemo__CFunc__) */
