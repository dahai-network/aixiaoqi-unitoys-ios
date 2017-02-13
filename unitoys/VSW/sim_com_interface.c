
#include    "sim_com_app.h"
#include    "sim_com_debug.h"
#include    "sim_com_interface.h"
#include <string.h>
#include "Test.h"


#if (__SIMCOM_OS_TYPE__ == __SIMCOM_OS_ANDROID__)
#include "CToJava.h"
#include "zlib.h"

static char g_buffer[1024 * 20];

void printSomething(char *sendStr)
{
    logSomething(sendStr);
    sendICCIDValue(sendStr);
    sendTLVLength(sendStr);
}

int structToHexBuffer(ST_SIMCOM_APPEVT * evtMsg, char* buffer, int length)
{
    int offset = 0;
    int i = 0;

    offset += sprintf(buffer + offset, "%02X", evtMsg->chn);
    offset += sprintf(buffer + offset, "%02X", evtMsg->evtIndex);
    offset += sprintf(buffer + offset, "%04X", evtMsg->len);
    if(evtMsg->len>1000){
        int err;

        Byte compr[20000];    // big enough

        uLong comprLen ;

        comprLen  = sizeof(compr) / sizeof(compr[0]);



        err = compress(compr, &comprLen, evtMsg->pData, evtMsg->len);
        SIMCOM_INFO("succeed  %d",err);
        SIMCOM_INFO("succeed  %d",comprLen);
        if (err != Z_OK) {
            SIMCOM_INFO("succeed");
        }
        for (i = 0; i < comprLen; i++) {
            offset += sprintf(buffer + offset, "%02X", compr[i]);
        }
    }else{
        for (i = 0; i < evtMsg->len; i++) {
            offset += sprintf(buffer + offset, "%02X", evtMsg->pData[i]);
        }
    }
    return offset;
}

#endif

SIMCOMROOTST stSimComRootSt;

_INT32 SimComInit(_VOID)
{
    PSIMCOMROOTST         pSimComRootSt;

    pSimComRootSt = (PSIMCOMROOTST)&stSimComRootSt;
	pSimComRootSt->SimComInitFunPtr = (_VOID (*)(_VOID))SimCom_Init;
    pSimComRootSt->SimComTask  = SimCom_Task;
    pSimComRootSt->SimComInitFunPtr(); 
	
    return EOS_OK;
}

#if (__SIMCOM_OS_TYPE__ == __SIMCOM_OS_IOS__)
#include "zlib.h"

static char g_buffer[1024 * 20];

int structToHexBuffer(ST_SIMCOM_APPEVT * evtMsg, char* buffer, int length)
{
    int offset = 0;
    int i = 0;
    
    //offset += sprintf(buffer + offset, "%02X", evtMsg->chn);
    //offset += sprintf(buffer + offset, "%02X", evtMsg->evtIndex);
    //offset += sprintf(buffer + offset, "%04X", evtMsg->len);
    if(evtMsg->len>1000){
        int err;
        
        Byte compr[20000];    // big enough
        
        uLong comprLen ;
        
        comprLen  = sizeof(compr) / sizeof(compr[0]);
        
        
        
        err = compress(compr, &comprLen, evtMsg->pData, evtMsg->len);
        SIMCOM_INFO("succeed  %d",err);
        SIMCOM_INFO("succeed  %lu",comprLen);
        if (err != Z_OK) {
            SIMCOM_INFO("succeed");
        }
        for (i = 0; i < comprLen; i++) {
            offset += sprintf(buffer + offset, "%02X", compr[i]);
        }
    }else{
        for (i = 0; i < evtMsg->len; i++) {
            offset += sprintf(buffer + offset, "%02X", evtMsg->pData[i]);
        }
    }
    return offset;
}

#endif

_INT32 SimComEvtApp2Drv(ST_SIMCOM_APPEVT * evtMsg)
{
    SIMCOM_INFO("IO - get msg from app\n");
    SimComAppEvtHdl(evtMsg);
    return 1;
}

_INT32 SimComEvtDrv2App(ST_SIMCOM_APPEVT * evtMsg)
{
#if (__SIMCOM_OS_TYPE__ == __SIMCOM_OS_ANDROID__)
//    char *pBuffer = NULL;
//    char *pTmp = NULL;
//    int bufferSize = 0;
//    int length = 0;
//    SIMCOM_INFO("IO - send msg to app\n -data.length - %d\n", evtMsg->len);
//    SIMCOM_INFO("IO - send msg to app\n -data.evtIndex - %d\n", evtMsg->evtIndex);
//    SIMCOM_INFO("IO - send msg to app\n -data.chn - %d\n", evtMsg->chn);
//    // SIMCOM_INFO("IO - send msg to app\n -data - %s\n", evtMsg->pData);
//
//    bufferSize = sizeof(g_buffer);
//    pBuffer = g_buffer;
//    memset(pBuffer, 0, bufferSize);
//    length = structToHexBuffer(evtMsg, pBuffer, bufferSize);
//
//    SIMCOM_INFO("buffer length %d \n", length);
//    GetTime(pBuffer);

#elif (__SIMCOM_OS_TYPE__ == __SIMCOM_OS_IOS__)
    //fill ios code
    char *pBuffer = NULL;
    char *pTmp = NULL;
    int bufferSize = 0;
    int length = 0;
    SIMCOM_INFO("IO - send msg to app\n -data.length - %d\n", evtMsg->len);
    SIMCOM_INFO("IO - send msg to app\n -data.evtIndex - %d\n", evtMsg->evtIndex);
    SIMCOM_INFO("IO - send msg to app\n -data.chn - %d\n", evtMsg->chn);
    // SIMCOM_INFO("IO - send msg to app\n -data - %s\n", evtMsg->pData);
    
    bufferSize = sizeof(g_buffer);
    pBuffer = g_buffer;
    memset(pBuffer, 0, bufferSize);
    length = structToHexBuffer(evtMsg, pBuffer, bufferSize);
    
    SIMCOM_INFO("buffer length %d \n", length);
//    GetTime(pBuffer);
    if (evtMsg->evtIndex == 5) {
        logSomething(pBuffer);
    }
#endif
    
    if(evtMsg->evtIndex == EN_APPEVT_PRDATA) {
        SIMCOM_INFO("IO - send msg to app: (chn = %d, evtIndex = %d, len = %d)\n", evtMsg->chn, evtMsg->evtIndex, evtMsg->len);
        sendTLVLength(evtMsg->len);
    } else if(evtMsg->evtIndex == 6) {
        SIMCOM_INFO("IO - send msg to app: (chn = %d, evtIndex = %d, len = %d)\n (data = %s)\n", evtMsg->chn, evtMsg->evtIndex, evtMsg->len, evtMsg->pData);
        receiveNewData(pBuffer);
    } else {
        /* 下面为获取到Java中对应的实例类中的变量*/
        SIMCOM_INFO("IO - send msg to app: (chn = %d, evtIndex = %d, len = %d)\n (data = %s)\n", evtMsg->chn, evtMsg->evtIndex, evtMsg->len, evtMsg->pData);
        sendICCIDValue(evtMsg->pData);
    }
    return 1;
}


