
#include "sim_com_debug.h"
#include "sim_com_app.h"
#include "sim_com_preread.h"
#include "sim_com_interface.h"
#include "sim_com_serial.h"
#include <stdio.h>
//#include <time.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

#include <time.h>
#include <sys/time.h>

#ifdef __MACH__
#include <mach/clock.h>
#include <mach/mach.h>
#endif


extern SIMCOMROOTST stSimComRootSt;

static _UINT32 SimComSetSimTypeTimerCB(_UINT32 uiChannelId, _UINT32 tmp);
static _UINT32 simcomDetectPollTimerCB(_UINT32 uiRsvd0, _UINT32 uiRsvd1);
static _VOID   SimComReadData(_VOID);
static _UINT32 simcomGetRstRspTimerCB(_UINT32 uiChannelId, _UINT32 bLightLed);
static _UINT32 simcomRstSim(_UINT32 uiChannelId);
static _UINT32 simcomGetPPSRspTimerCB(_UINT32 uiChannelId, _UINT32 bLightLed);
static _UINT32 simcomSetRstTimerCB(_UINT32 uiChannelId, _UINT32 uiRsvd1);
static _INT32  simcomSetFPGAEtu(_UINT32 uiChannelId, _INT32 ETU);


#define SIMPOOL_MAX_CHANNEL 1

#define USE_HIGH_BAUDRATE		0

#define SIMCOM_PRINT_DATA 1 /* for debug	*/

//#define SIMCOM_PKT_STAT   1 /* for statistics	*/

#define SP_MAX_CMD_LIST_NUMBER    4

extern ST_PREREAD_FID PreReadFID_UC15_SIM[];
extern ST_PREREAD_FID PreReadFID_MC323[];

unsigned long GetSysTimeSec(void)
{
    struct timespec ts;
    
#ifdef __MACH__ // OS X does not have clock_gettime, use clock_get_time
    clock_serv_t cclock;
    mach_timespec_t mts;
    host_get_clock_service(mach_host_self(), CLOCK_REALTIME, &cclock);
    clock_get_time(cclock, &mts);
    mach_port_deallocate(mach_task_self(), cclock);
    ts.tv_sec = mts.tv_sec;
    ts.tv_nsec = mts.tv_nsec;
#else
    clock_gettime(CLOCK_MONOTONIC, &ts);
#endif

//    clock_gettime(CLOCK_MONOTONIC, &ts);
//    printf("nsec -- %ld sec -- %ld\n", ts.tv_nsec, ts.tv_sec);
    return (ts.tv_sec * 1000 + ts.tv_nsec / 1000000);
}

//get sys time,10 ms = 1 tick
unsigned long GetSysTickCount(void)
{
    struct timespec ts;
    
#ifdef __MACH__ // OS X does not have clock_gettime, use clock_get_time
    clock_serv_t cclock;
    mach_timespec_t mts;
    host_get_clock_service(mach_host_self(), CLOCK_REALTIME, &cclock);
    clock_get_time(cclock, &mts);
    mach_port_deallocate(mach_task_self(), cclock);
    ts.tv_sec = mts.tv_sec;
    ts.tv_nsec = mts.tv_nsec;
#else
    clock_gettime(CLOCK_MONOTONIC, &ts);
#endif

//    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (ts.tv_sec * 100 + ts.tv_nsec / 10000000);
}

unsigned long tickGet(void)
{
    return GetSysTickCount();
}

#if (__SIMCOM_OS_TYPE__ == __SIMCOM_OS_IOS__)

#define TIMER_SYS_MAX    10

typedef struct {
    _UCHAR8 status;     // 0-empty, 1-busy,
    _UCHAR8 id;
    _UINT32 timems;
    unsigned long startSec;
    _INT32 (*timeHdl)(_INT32, _INT32);
}ST_TIMER_SYS;

static ST_TIMER_SYS timerList[TIMER_SYS_MAX];

int CommonTimerCreate(_UINT32 *pTimerId, _UINT32 timerCallId)
{
    _UCHAR8 i;
    
    for(i=0; i<TIMER_SYS_MAX; i++)
    {
        if(timerList[i].status == 0)   //timer is empty
        {
            timerList[i].status = 1;
            
            *pTimerId = i+1;
            timerList[i].id = *pTimerId;
            timerList[i].timems = 0;
            timerList[i].startSec = 0;
            switch(timerCallId)
            {
                case 0: 
                {
                    SIMCOM_DBG("timerCallId = 0. wrong!\n");
                    break;
                }
                case EN_TIMER_CALLID_SETSIMTPYE: 
                {
                    timerList[i].timeHdl = (_INT32(*)(_INT32, _INT32))SimComSetSimTypeTimerCB;
                    break;
                }
                case EN_TIMER_CALLID_DETSIMIN: 
                {
                    timerList[i].timeHdl = (_INT32(*)(_INT32, _INT32))simcomDetectPollTimerCB;
                    break;
                }
                case EN_TIMER_CALLID_RST: 
                {
                    timerList[i].timeHdl = (_INT32(*)(_INT32, _INT32))simcomSetRstTimerCB;
                    break;
                }
                case EN_TIMER_CALLID_RSTRSP: 
                {
                    timerList[i].timeHdl = (_INT32(*)(_INT32, _INT32))simcomGetRstRspTimerCB;
                    break;
                }
                case EN_TIMER_CALLID_PPSRSP:
                {
                    timerList[i].timeHdl = (_INT32(*)(_INT32, _INT32))simcomGetPPSRspTimerCB;
                    break;
                }
                default:break;
            }
            break;
        }
    }
    if(i == TIMER_SYS_MAX)
    {

        SIMCOM_INFO("Timer create faild:tid-%d callId-%d \n", *pTimerId, timerCallId);
    }
    else
    {

        SIMCOM_INFO("Timer create success:tid-%d callId-%d \n", *pTimerId, timerCallId);
    }
    return EOS_OK;
}

int CommonTimerDelete(_UINT32 *pTimerId)
{
    _UCHAR8 i;
    
    for(i=0; i<TIMER_SYS_MAX; i++)
    {
        if(timerList[i].id == *pTimerId)
        {
            *pTimerId = 0;
            timerList[i].status = 0;
            timerList[i].id = 0;
            timerList[i].timems = 0;
            timerList[i].startSec = 0;
            break;
        }
    }
    if(i == TIMER_SYS_MAX)
    {

        SIMCOM_INFO("Timer delete faild:tid-%d \n", *pTimerId);
    }
    else
    {

        SIMCOM_INFO("Timer delete success:tid-%d \n", *pTimerId);
    }
    return EOS_OK;
}

int CommonTimerStart(_UINT32 timerId, _UINT32 len, _UINT32 mode)
{
    _UCHAR8 i;
    
    for(i=0; i<TIMER_SYS_MAX; i++)
    {
        if((timerList[i].status > 0) && (timerList[i].id == timerId))
        {
            timerList[i].timems = len;
            timerList[i].startSec = GetSysTimeSec();
            //SIMCOM_DBG("Timer start success:tid-%d ,len-%d, s-%x\n", timerId, timerList[i].timems, timerList[i].startSec);
            break;
        }
    }
    //SIMCOM_INFO("Timer start faild:tid-%d \n", timerId);
    
    return EOS_OK;
}

int CommonTimerStop(_UINT32 timerId)
{
    _UCHAR8 i;
    
    for(i=0; i<TIMER_SYS_MAX; i++)
    {
        if((timerList[i].status > 0) && (timerList[i].id == timerId))
        {
            timerList[i].timems = 0;
            timerList[i].startSec = 0;
            //SIMCOM_INFO("Timer stop success:tid-%d \n", timerId);
            break;
        }
    }

    //SIMCOM_INFO("Timer stop faild:tid-%d \n", timerId);
    return EOS_OK;
}

void CommonTimerMainHdl(void)
{
    _UCHAR8 i;
    
    for(i=0; i<TIMER_SYS_MAX; i++)
    {
        if((timerList[i].status > 0) && (timerList[i].timems >0))
        {
            if((GetSysTimeSec() - timerList[i].startSec) > timerList[i].timems)
            {
                //SIMCOM_DBG("Timer timeout:tid-%d %d,%x,%x\n", timerList[i].id, timerList[i].timems, timerList[i].startSec, GetSysTimeSec());
                timerList[i].status = 1;
                timerList[i].timems = 0;
                timerList[i].startSec = 0;
                
                timerList[i].timeHdl(0, 0);
            }
        }
    }
}

#else
void CommonTimerMainHdl(union sigval v)  
{  
    switch(v.sival_int)
    {
        case 0: 
        {
            SIMCOM_DBG("timerCallId = 0. wrong!\n");
            break;
        }
        case EN_TIMER_CALLID_SETSIMTPYE: 
        {
            SimComSetSimTypeTimerCB(0, 0);
            break;
        }
        case EN_TIMER_CALLID_DETSIMIN: 
        {
            simcomDetectPollTimerCB(0, 0);
            break;
        }
        case EN_TIMER_CALLID_RST: 
        {
            simcomSetRstTimerCB(0, 0);
            break;
        }
        case EN_TIMER_CALLID_RSTRSP: 
        {
            simcomGetRstRspTimerCB(0, 0);
            break;
        }
        case EN_TIMER_CALLID_PPSRSP:
        {
            simcomGetPPSRspTimerCB(0, 0);
            break;
        }
        default:break;
    }
    
    //SIMCOM_INFO("CommonTimerMainHdl - Call ID %d.\n", v.sival_int);  
    //SIMCOM_DBG("current tick %d\n", GetSysTickCount());
}

int CommonTimerCreate(_UINT32 *pTimerId, _UINT32 timerCallId)
{
    // int timer_create(clockid_t clockid, struct sigevent *evp, timer_t *timerid);  
    // clockid--ֵ��CLOCK_REALTIME,CLOCK_MONOTONIC��CLOCK_PROCESS_CPUTIME_ID,CLOCK_THREAD_CPUTIME_ID  
    // evp--��Ż���ֵ�ĵ�ַ,�ṹ��Ա˵���˶�ʱ�����ڵ�֪ͨ��ʽ�ʹ���ʽ��  
    // timerid--��ʱ����ʶ��  
    //timer_t timerid;  
    struct sigevent evp;  
    memset(&evp, 0, sizeof(struct sigevent));       //�����ʼ��  
  
    evp.sigev_value.sival_int = timerCallId;        //Ҳ�Ǳ�ʶ��ʱ���ģ����timerid��ʲô���𣿻ص��������Ի��  
    evp.sigev_notify = SIGEV_THREAD;                //�߳�֪ͨ�ķ�ʽ����פ���߳�  
    evp.sigev_notify_function = CommonTimerMainHdl;       //�̺߳�����ַ  
  
    if (timer_create(CLOCK_REALTIME, &evp, (timer_t*)pTimerId) == -1)  
    {  
        perror("fail to timer_create");
        return EOS_ERROR;
    }
    SIMCOM_INFO("Timer create success:tid-%d callId-%d \n", *pTimerId, timerCallId);
    return EOS_OK;
}

int CommonTimerStart(_UINT32 timerId, _UINT32 len, _UINT32 mode)
{
    // XXX int timer_settime(timer_t timerid, int flags, const struct itimerspec *new_value,struct itimerspec *old_value);  
    // timerid--��ʱ����ʶ  
    // flags--0��ʾ���ʱ�䣬1��ʾ����ʱ��  
    // new_value--��ʱ�����³�ʼֵ�ͼ�����������it  
    // old_value--ȡֵͨ��Ϊ0�������ĸ�������ΪNULL,����ΪNULL���򷵻ض�ʱ����ǰһ��ֵ  
      
    //��һ�μ��it.it_value��ô��,�Ժ�ÿ�ζ���it.it_interval��ô��,����˵it.it_value��0��ʱ���װ��it.it_interval��ֵ  
    struct itimerspec it;  
    
    it.it_value.tv_sec = len / 1000;  
    it.it_value.tv_nsec = (len % 1000) * 1000;  
    if(mode == 0)
    {
        it.it_interval.tv_sec = 0;  
        it.it_interval.tv_nsec = 0; 
    }
    else
    {
        it.it_interval.tv_sec = it.it_value.tv_sec; 
        it.it_interval.tv_nsec = it.it_value.tv_nsec; 
    }
  
    if (timer_settime(timerId, 0, &it, NULL) == -1)  
    {  
        perror("fail to start timer");  
        return EOS_ERROR;
    }  
    return EOS_OK;
}

int CommonTimerStop(_UINT32 timerId)
{
    struct itimerspec it;  
    
    it.it_value.tv_sec = 0;  
    it.it_value.tv_nsec = 0;  
    it.it_interval.tv_sec = 0;  
    it.it_interval.tv_nsec = 0; 
  
    if (timer_settime(timerId, 0, &it, NULL) == -1)  
    {  
        perror("fail to stop timer");  
        return EOS_ERROR;
    }  
    return EOS_OK;
}

#endif



_INT32 SimCom_Init(_VOID)
{
    PSIMCOMROOTST         pSimComRootSt;
    PSIMCOMCHNST          pChnStHandle = NULL;	
	_UINT32 uiChannelIdx = 0;
    
    pSimComRootSt = (PSIMCOMROOTST)&stSimComRootSt;
    pSimComRootSt->uiMaxChannelNum = SIMPOOL_MAX_CHANNEL;
    pSimComRootSt->pSimComChnSt = (PSIMCOMCHNST)malloc(sizeof(SIMCOMCHNST)*(pSimComRootSt->uiMaxChannelNum));
    if(NULL == pSimComRootSt->pSimComChnSt)
    {
        SIMCOM_INFO("SimCom malloc error\n");
        return EOS_ERROR;
    }
	
    memset(pSimComRootSt->pSimComChnSt, 0, sizeof(SIMCOMCHNST)*(pSimComRootSt->uiMaxChannelNum));
			
	for(uiChannelIdx = 0; uiChannelIdx < pSimComRootSt->uiMaxChannelNum; uiChannelIdx++)
	{
		pChnStHandle = &pSimComRootSt->pSimComChnSt[uiChannelIdx];
		//pChnStHandle->pEsccSessId = escc_get_sess(uiChannelIdx);
		
		pChnStHandle->bGetRstRspStatus = EOS_FALSE;
		pChnStHandle->bGetRstRspDone = EOS_FALSE;
		memset(pChnStHandle->RstRspBuff, 0, sizeof(pChnStHandle->RstRspBuff));
		pChnStHandle->RstRspBuffLen = 0;

		pChnStHandle->bSimOk = EOS_FALSE;
		pChnStHandle->bHighBaudrate = EOS_FALSE;
		pChnStHandle->uiSameCmd = 0;
		pChnStHandle->uiDiffCmd = 0;
		pChnStHandle->uiLessCmd = 0;
		pChnStHandle->uiTimeoutRsp = 0;
		
		pChnStHandle->uiPreReadCnt = 0;
		pChnStHandle->uiTotalSendCnt = 0;
		pChnStHandle->uiTotalRcvCnt = 0;

		pChnStHandle->PreRdFidSt = (_UCHAR8*)malloc(SP_MAX_PRERD_FILE_SISE);
		memset(pChnStHandle->PreRdFidSt, 0, SP_MAX_PRERD_FILE_SISE);
		pChnStHandle->PreRdRootSt = (_UCHAR8*)malloc(SP_MAX_PRERD_ROOT_SISE);		
		memset(pChnStHandle->PreRdRootSt, 0, SP_MAX_PRERD_ROOT_SISE);
		pChnStHandle->uiPreRdIdx = 0;
		pChnStHandle->uiPreRdExpLen = 0;

        CommonTimerCreate(&(pChnStHandle->SetSimTypeTimerId), EN_TIMER_CALLID_SETSIMTPYE);
        CommonTimerCreate(&(pSimComRootSt->SIMDetectTimerId), EN_TIMER_CALLID_DETSIMIN);
        CommonTimerCreate(&(pChnStHandle->SetRstTimerId), EN_TIMER_CALLID_RST);
        CommonTimerCreate(&(pChnStHandle->GetRstRspTimerId), EN_TIMER_CALLID_RSTRSP);
        CommonTimerCreate(&(pChnStHandle->GetPPSRspTimerId), EN_TIMER_CALLID_PPSRSP);
			
		pChnStHandle->bSupportUSIM = EOS_FALSE;
	}
	
	pSimComRootSt->CardDetect1 = 0;
	pSimComRootSt->CardDetect2 = 0;
	pSimComRootSt->CardDetect3 = 0;
	
	//weikk 20160428
	pSimComRootSt->fdSerialHdl = SimComSerialInit();
	SIMCOM_INFO("Init Serial Port.fd= %d\n", pSimComRootSt->fdSerialHdl);

    if(pChnStHandle->SetSimTypeTimerId > 0)
        CommonTimerStart((_UINT32)pChnStHandle->SetSimTypeTimerId, 2000, 0);

    ST_SIMCOM_APPEVT appEvtSendBuff;
    _UCHAR8 tmpData=0;
    
    appEvtSendBuff.chn = 0;
    appEvtSendBuff.evtIndex = EN_APPEVT_SETSIMTYPE;
    appEvtSendBuff.len = 0;
    appEvtSendBuff.pData = &tmpData;
    //SimComEvtDrv2App(&appEvtSendBuff);
    
    return EOS_OK;
}

_VOID SimComAppEvtHdl(ST_SIMCOM_APPEVT * evtMsg)
{
    PSIMCOMROOTST         pSimComRootSt;
    PSIMCOMCHNST          pChnStHandle = NULL;
    _UINT32 i = 0;
	
    pSimComRootSt = (PSIMCOMROOTST)&stSimComRootSt;
	pChnStHandle = &pSimComRootSt->pSimComChnSt[evtMsg->chn];

    switch(evtMsg->evtIndex)
    {
        case EN_APPEVT_SETSIMTYPE:
        {
            if(pChnStHandle->SetSimTypeTimerId > 0)
        	{
                CommonTimerStop((_UINT32)pChnStHandle->SetSimTypeTimerId);
        	}
            pChnStHandle->simCardType = *(evtMsg->pData);
            if((pChnStHandle->simCardType > 0) && (pChnStHandle->simCardType <= EN_SIMTYPE_CTCC))
            {
                SIMCOM_INFO("Channel %d Set sim type %d.\n", evtMsg->chn, pChnStHandle->simCardType);
            }
            else
            {
                pChnStHandle->simCardType = EN_SIMTYPE_USIM;
                SIMCOM_INFO("Channel %d Set sim type Wrong,set defaylt.\n", evtMsg->chn);
            }
            
            if(pSimComRootSt->SIMDetectTimerId > 0)
                CommonTimerStart((_UINT32)pSimComRootSt->SIMDetectTimerId, 100, 0);
            break;
        }
        case EN_APPEVT_CMD_SETRST:	
        {
			SIMCOM_INFO("Channel %d Recv Sim Enter Reset\n", evtMsg->chn);
			pChnStHandle->bGetRstRspStatus = EOS_TRUE;
            pChnStHandle->bNeedPreRead = EOS_TRUE;
			//simcomSetFPGAEtu(evtMsg->chn, 0);
			//simcomSetRspSignal(evtMsg->chn, 1); 		
			//SimComCardReset(pSimComRootSt->fdSerialHdl);
			
			if(pChnStHandle->SetRstTimerId > 0)
			{
                CommonTimerStart((_UINT32)(pChnStHandle->SetRstTimerId), 200, 0);
			}
            evtMsg->len = 0;
			//ESCC_SessAnswerCmd(escc_get_sess(evt->channel), (_CHAR8 *)&SimPoolMsgAnswer, sizeof(ST_SIMPOOL_MSG));
			pChnStHandle->SimPoolStatus = SIMPOOL_ST_RST;					
			pChnStHandle->bHasBakCmd = EOS_FALSE;
			pChnStHandle->CmdIdx = 0;
            break;
        }
        case EN_APPEVT_CMD_SIMCLR:				
		{
            SIMCOM_INFO("Channel %d Recv Sim Clear\n", evtMsg->chn);
            evtMsg->len = 0;
			pChnStHandle->SimPoolStatus = SIMPOOL_ST_IDLE;	
			pChnStHandle->bHasBakCmd = EOS_FALSE;
            pChnStHandle->CmdIdx = 0;
			
			//ESCC_SessAnswerCmd(escc_get_sess(evt->channel), (_CHAR8 *)&SimPoolMsgAnswer, sizeof(ST_SIMPOOL_MSG));
			break;
        }
        case EN_APPEVT_RSTRSP:
		{
            evtMsg->len = pChnStHandle->RstRspBuffLen;
			memcpy(evtMsg->pData, pChnStHandle->RstRspBuff, pChnStHandle->RstRspBuffLen);
			//pChnStHandle->SimPoolStatus = SIMPOOL_ST_RST;					
			//pChnStHandle->CmdIdx = 0;
            
			//ESCC_SessAnswerCmd(escc_get_sess(evt->channel), (_CHAR8 *)&SimPoolMsgAnswer, sizeof(ST_SIMPOOL_MSG));
			SIMCOM_INFO("Chanel %d Send RstRsp - %d\n", evtMsg->chn, evtMsg->len);
            break;
        }  
        case EN_APPEVT_PRDATA:
        {
            break;
        }
        case EN_APPEVT_SIMDATA:
        {
			PWRLESCCCMDST pWrlEsccCmd = (PWRLESCCCMDST)(pChnStHandle->ucCmdData);
			PWRLESCCCMDST pWrlEsccRcvCmd = (PWRLESCCCMDST)(evtMsg->pData);

			if(evtMsg->len > 4)
			{
				SIMCOM_INFO("Channel %d Rcv CmdIdx:%d, ExpIdx:%d\n", evtMsg->chn, ntohs(pWrlEsccRcvCmd->cmdIndex), (pChnStHandle->CmdIdx + 1));
				
				if(((_SHORT16)(ntohs(pWrlEsccRcvCmd->cmdIndex) - pChnStHandle->CmdIdx) >= 0)
					|| ((ntohs(pWrlEsccRcvCmd->cmdIndex) == 0) && (0xffff == pChnStHandle->CmdIdx)))
				{						
					if(SIMPOOL_ST_RST == pChnStHandle->SimPoolStatus)
					{
						memset(pWrlEsccCmd, 0, sizeof(pChnStHandle->ucCmdData));
						memcpy(pWrlEsccCmd, evtMsg->pData, evtMsg->len);

						SIMCOM_INFO("Channel %d Rcv CmdIdx:%d in SimRst Status(%d)\n", evtMsg->chn, ntohs(pWrlEsccRcvCmd->cmdIndex), pChnStHandle->bHasBakCmd);
						pChnStHandle->bHasBakCmd = EOS_TRUE;
					}
					else
					{
						if(SIMPOOL_ST_IDLE == pChnStHandle->SimPoolStatus)
						{
							ioctl_simpool_write_st stSimPoolWrite;
							
							memset(pWrlEsccCmd, 0, sizeof(pChnStHandle->ucCmdData));
							memcpy(pWrlEsccCmd, evtMsg->pData, evtMsg->len);

							memset(&stSimPoolWrite, 0, sizeof(ioctl_simpool_write_st));
                            
                            SIMCOM_DBG("test uiPrefixSelectIdx=%d, PrefixNum=%d, paramLen=%d.\n", pChnStHandle->uiPrefixSelectIdx , ntohs(pWrlEsccCmd->PrefixNum), pWrlEsccCmd->paramLen);
                            SIMCOM_DBG("test file id:%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x  \n",pWrlEsccCmd->PrefixFid[0][0],pWrlEsccCmd->PrefixFid[0][1],pWrlEsccCmd->PrefixFid[1][0],pWrlEsccCmd->PrefixFid[1][1]
                                ,pWrlEsccCmd->PrefixFid[2][0],pWrlEsccCmd->PrefixFid[2][1],pWrlEsccCmd->PrefixFid[3][0],pWrlEsccCmd->PrefixFid[3][1]);
                            #if 1
                            if(ntohs(pWrlEsccCmd->PrefixNum) == 0)
                            {
                                if(pWrlEsccCmd->PrefixFid[0][0] > 0)
                                {
                                    pWrlEsccCmd->PrefixNum = htons(1);
                                    if(pWrlEsccCmd->PrefixFid[1][0] > 0)
                                    {
                                        pWrlEsccCmd->PrefixNum = htons(2);
                                        if(pWrlEsccCmd->PrefixFid[2][0] > 0)
                                        {
                                            pWrlEsccCmd->PrefixNum = htons(3);
                                            if(pWrlEsccCmd->PrefixFid[3][0] > 0)
                                            {
                                                pWrlEsccCmd->PrefixNum = htons(4);
                                            }
                                        }
                                    }
                                }
                            }
                            SIMCOM_DBG("test PrefixNum=%d \n", ntohs(pWrlEsccCmd->PrefixNum));
                            #endif
							if(ntohs(pWrlEsccCmd->PrefixNum) > 0)
							{
								_UCHAR8 A4CmdData[5] = {0xa0, 0xa4, 0x0, 0x0, 0x02};
								if(0)//((NVM_GOIP_SIMTYPE_WCDMA == ASYS_NvmGetIntEx(NVM_PORT_SIM_TYPE, evt->channel)) && (pChnStHandle->bSupportUSIM))
								{
									A4CmdData[0] = 0x0;
									A4CmdData[3] = 0x04;

									if((pWrlEsccCmd->PrefixFid[0][0] == 0x7f) && (pWrlEsccCmd->PrefixFid[0][1] == 0xff))
									{
										A4CmdData[2] = 0x04;
										A4CmdData[4] = pChnStHandle->AIDLen;
									}
								}
                                //weikk 20161012,bluetooth
                                #if 0
								memcpy(stSimPoolWrite.buff, A4CmdData, sizeof(A4CmdData));
								stSimPoolWrite.size = sizeof(A4CmdData);
								stSimPoolWrite.channelid = evt->channel;
								//weikk_add_file
								iRetVal = SimComSerialWrite(pSimComRootSt->fdSerialHdl, stSimPoolWrite.buff, stSimPoolWrite.size);
                                if(iRetVal < 0){
                                    SIMCOM_INFO("Channel %d SimPool Write Data Error.\n", stSimPoolWrite.channelid);
                                }
								pChnStHandle->SimPoolStatus = SIMPOOL_ST_PREFIX_WAIT_INS;
                                pChnStHandle->uiPrefixSelectIdx = 0;
								pChnStHandle->expRspLen = 1;
                                #else
                                _UCHAR8 WriteDataEx[16] = {0xa0, 0xa4, 0x0, 0x0, 0x2,}; 

                                WriteDataEx[5] = pWrlEsccCmd->PrefixFid[0][0];
                                WriteDataEx[6] = pWrlEsccCmd->PrefixFid[0][1];
                                stSimPoolWrite.size = 7;
								stSimPoolWrite.channelid = evtMsg->chn;
                    			/* Send FileId*/
                    			SimComWriteData(evtMsg->chn, WriteDataEx, 7);
                											
                				pChnStHandle->SimPoolStatus = SIMPOOL_ST_PREFIX_WAIT_RSP;	
								pChnStHandle->uiPrefixSelectIdx = 1;
								pChnStHandle->expRspLen = 1;
                                #endif
#ifdef	SIMCOM_PRINT_DATA
								{
									_UCHAR8 PrintBuff[4096];
									_UINT32 uiPrintLen = 0;
									
									uiPrintLen = sprintf((PrintBuff + uiPrintLen), "Channel %d ###W(0x%02x) ", stSimPoolWrite.channelid, stSimPoolWrite.size);
									for(i = 0; i < stSimPoolWrite.size; i++)
									{
										uiPrintLen += sprintf((PrintBuff + uiPrintLen), "0x%02x ", stSimPoolWrite.buff[i]); 					
									}
									sprintf(PrintBuff+uiPrintLen,"\n");
								}				
#endif						
								//kinson test 2016.01.13
								pChnStHandle->CmdIdx = ntohs(pWrlEsccCmd->cmdIndex);
								SIMCOM_INFO("Channel %d Recv Prefix:%d\n", evtMsg->chn, ntohs(pWrlEsccCmd->PrefixNum)); 	
							}
							else
							{
								stSimPoolWrite.size = pWrlEsccCmd->cmdLen;
								stSimPoolWrite.channelid = evtMsg->chn;
								
								pChnStHandle->CmdIdx = ntohs(pWrlEsccCmd->cmdIndex);

								pChnStHandle->uiTotalRcvCnt +=	evtMsg->len;

#ifdef	SIMCOM_PRINT_DATA
								{
									_UCHAR8 PrintBuff[4096];
									_UINT32 uiPrintLen = 0;
									
									uiPrintLen = sprintf((PrintBuff + uiPrintLen), "Channel %d ###W(0x%02x) ", stSimPoolWrite.channelid, stSimPoolWrite.size);
									for(i = 0; i < stSimPoolWrite.size; i++)
									{
										uiPrintLen += sprintf((PrintBuff + uiPrintLen), "0x%02x ", stSimPoolWrite.buff[i]);						
									}
									sprintf(PrintBuff+uiPrintLen,"\n");
								}				
#endif						
                                #if 0
								//SIMCOM_INFO("Channel %d Recv Cmdidx %d, cmdLen:%d, expRspLen = %d\n", evt->channel, pChnStHandle->CmdIdx, pWrlEsccCmd->cmdLen, ntohs(pWrlEsccCmd->expRspLen));
								//weikk 20160428
								SimComWriteData(stSimPoolWrite.channelid, stSimPoolWrite.buff, stSimPoolWrite.size);

								if(pWrlEsccCmd->paramLen > 0)
								{
									pChnStHandle->SimPoolStatus = SIMPOOL_ST_WAIT_INS;				
								}
								else
								{
									pChnStHandle->SimPoolStatus = SIMPOOL_ST_WAIT_RSP;
									pChnStHandle->WaitRspTick = tickGet();
									pChnStHandle->LastReadTick = tickGet();								
								}
                                SIMCOM_DBG("test PrefixNum=%d, paramLen=%d.\n", pWrlEsccCmd->PrefixNum,pWrlEsccCmd->paramLen);
                                #else
                                if (pWrlEsccCmd->paramLen > 0) {
                                    stSimPoolWrite.size = pWrlEsccCmd->cmdLen + pWrlEsccCmd->paramLen;
                                    SIMCOM_DBG ("*************test ************** 222\n");
                                }
                                else
                                {
                                    stSimPoolWrite.size = pWrlEsccCmd->cmdLen;
                                }

                                memcpy(stSimPoolWrite.buff, pWrlEsccCmd->cmdData, stSimPoolWrite.size);
    							SimComWriteData(stSimPoolWrite.channelid, stSimPoolWrite.buff, stSimPoolWrite.size);

    							if(0)//(pWrlEsccCmd->paramLen > 0)
    							{
    								pChnStHandle->SimPoolStatus = SIMPOOL_ST_WAIT_INS;				
    							}
    							else
    							{
    								pChnStHandle->SimPoolStatus = SIMPOOL_ST_WAIT_RSP;
    								pChnStHandle->WaitRspTick = tickGet();
    								pChnStHandle->LastReadTick = tickGet();								
    							}
                                #endif
							}
						}
						else
						{	
							SIMCOM_INFO("Channel %d Cmd Idx:%d, But SimpoolStatus is %d\n", evtMsg->chn, ntohs(pWrlEsccRcvCmd->cmdIndex), pChnStHandle->SimPoolStatus);
#if 0								
							if((pWrlEsccCmd->cmdLen == pWrlEsccRcvCmd->cmdLen) 
								&& (pWrlEsccCmd->expRspLen == pWrlEsccRcvCmd->expRspLen) 
								&& (0 == memcmp(pWrlEsccCmd->cmdData, pWrlEsccRcvCmd->cmdData, (pWrlEsccCmd->cmdLen + pWrlEsccCmd->paramLen))))
							{
								SIMCOM_INFO("Channel %d Rcv Same Cmd\n", evt->channel);
								pChnStHandle->CmdIdx++;
								pChnStHandle->CmdIdx &= 0xffff;
								pChnStHandle->uiSameCmd++;
							}
							else
							{
								ioctl_simpool_write_st stSimPoolWrite;
								
								memset(pWrlEsccCmd, 0, sizeof(pChnStHandle->ucCmdData));
								memcpy(pWrlEsccCmd, evt->u.dat.data, evt->u.dat.len);

								memset(&stSimPoolWrite, 0, sizeof(ioctl_simpool_write_st));
								memcpy(stSimPoolWrite.buff, pWrlEsccCmd->cmdData, pWrlEsccCmd->cmdLen);
								stSimPoolWrite.size = pWrlEsccCmd->cmdLen;
								stSimPoolWrite.channelid = evt->channel;
								
								pChnStHandle->CmdIdx = ntohs(pWrlEsccCmd->cmdIndex);

								pChnStHandle->uiTotalRcvCnt +=	evt->u.dat.len;

#ifdef	SIMCOM_PRINT_DATA
								{
									_UCHAR8 PrintBuff[4096];
									_UINT32 uiPrintLen = 0;
									
									uiPrintLen = sprintf((PrintBuff + uiPrintLen), "Channel %d ###W(0x%02x) ", stSimPoolWrite.channelid, stSimPoolWrite.size);
									for(i = 0; i < stSimPoolWrite.size; i++)
									{
										uiPrintLen += sprintf((PrintBuff + uiPrintLen), "0x%02x ", stSimPoolWrite.buff[i]);						
									}
									sprintf(PrintBuff+uiPrintLen,"\n");
									SIMCOM_INFO(PrintBuff);
									
								}
#endif

								//SIMCOM_INFO("Channel %d Recv Cmdidx %d, cmdLen:%d, expRspLen = %d\n", evt->channel, pChnStHandle->CmdIdx, pWrlEsccCmd->cmdLen, ntohs(pWrlEsccCmd->expRspLen));
								//weikk_add_file
								iRetVal = SimComSerialWrite(pSimComRootSt->fdSerialHdl, stSimPoolWrite.buff, stSimPoolWrite.size);
                                if(iRetVal < 0){
                                    SIMCOM_INFO("Channel %d SimPool Write Data Error.\n", stSimPoolWrite.channelid);
                                }

								if(pWrlEsccCmd->paramLen > 0)
								{
									pChnStHandle->SimPoolStatus = SIMPOOL_ST_WAIT_INS;				
								}
								else
								{
									pChnStHandle->SimPoolStatus = SIMPOOL_ST_WAIT_RSP;
									pChnStHandle->WaitRspTick = tickGet();
									pChnStHandle->LastReadTick = tickGet();									
								}

								pChnStHandle->uiDiffCmd++;
								SIMCOM_INFO("Channel %d Rcv Diff Cmd\n", evt->channel);
														
							}
#endif								
						}
					}
				}
				else
				{
					pChnStHandle->uiLessCmd++;
					SIMCOM_INFO("Channel %d Rcv Less Cmd\n", evtMsg->chn);
				}
			}
			break; 
		}
        case EN_APPEVT_SIMINFO:
        {
            break;
        }
        default:
        {
            SIMCOM_INFO("not support event - %d.\n", evtMsg->evtIndex);
            break;
        }
    }    
}

_VOID SimComAppEvtSend(ST_SIMCOM_APPEVT * evtMsg)
{
    SimComEvtDrv2App(evtMsg);
}

_VOID SimComWriteData(_UINT32 uiChnIndex, _UCHAR8* pData, _UINT32 uiLen)
{
    PSIMCOMROOTST         pSimComRootSt;
    PSIMCOMCHNST          pChnStHandle = NULL;
	ioctl_simpool_write_st stSimPoolWrite;
	_UINT32 i = 0;
	
    pSimComRootSt = (PSIMCOMROOTST)&stSimComRootSt;
	pChnStHandle = &pSimComRootSt->pSimComChnSt[uiChnIndex];

	memset(&stSimPoolWrite, 0, sizeof(ioctl_simpool_write_st));
	memcpy(stSimPoolWrite.buff, pData, uiLen);
	stSimPoolWrite.channelid = uiChnIndex;	
	stSimPoolWrite.size = uiLen;

    if(stSimPoolWrite.buff[0] == 0xa0)
    {
        switch(stSimPoolWrite.buff[1])
        {
            case 0xC0:
                pChnStHandle->writeCmdType = 0xC0;
                break;
            case 0xB0:
                pChnStHandle->writeCmdType = 0xB0;
                break;
            case 0xB2:
                pChnStHandle->writeCmdType = 0xB2;
                break;
            case 0xF2:
                pChnStHandle->writeCmdType = 0xF2;
                break;
            case 0x12:
                pChnStHandle->writeCmdType = 0x12;
                break;
            default:
                pChnStHandle->writeCmdType = 0;
                break;
        }
    }
    
#ifdef	SIMCOM_PRINT_DATA
	{
		_UCHAR8 PrintBuff[4096];
		_UINT32 uiPrintLen = 0;
		
		uiPrintLen = sprintf((PrintBuff + uiPrintLen), "Channel %d ###W(0x%02x) ", stSimPoolWrite.channelid, stSimPoolWrite.size);
		for(i = 0; i < stSimPoolWrite.size; i++)
		{
			uiPrintLen += sprintf((PrintBuff + uiPrintLen), "0x%02x ", stSimPoolWrite.buff[i]);						
		}
		sprintf(PrintBuff+uiPrintLen,"\n");
		SIMCOM_INFO("%s", PrintBuff);
	}
#endif
	//weikk 20160428
	if(SimComSerialWrite(pSimComRootSt->fdSerialHdl, stSimPoolWrite.buff, stSimPoolWrite.size) < 0)
    {
        SIMCOM_INFO("Channel %d SimPool Write Data Error.\n", stSimPoolWrite.channelid);
    }
    //pChnStHandle->uiDiscardNum = stSimPoolWrite.size;
}

static _VOID SimComReadData(_VOID)
{
    PSIMCOMROOTST         pSimComRootSt;
    PSIMCOMCHNST          pChnStHandle = NULL;

	ioctl_simpool_read_st stSimPoolRead;
	_UINT32 uiBuffLeftLen = 0;
	
    _UINT32 uiChnIndex = 0;
	_UINT32 i = 0;
	ST_SIMCOM_APPEVT appEvtSendBuff;
    
	ST_PREREAD_ROOT* pPreRdRoot = NULL;
	ST_PREREAD_FILEID* pPreRdFileId = NULL;
	ST_PREREAD_CMDELEMENT* pPreRdCmdElmt = NULL;

    pSimComRootSt = (PSIMCOMROOTST)&stSimComRootSt;
    
    for(uiChnIndex = 0; uiChnIndex < pSimComRootSt->uiMaxChannelNum; uiChnIndex++)
    {
        pChnStHandle = &pSimComRootSt->pSimComChnSt[uiChnIndex];
		PWRLESCCCMDST pWrlEsccCmd = (PWRLESCCCMDST)(pChnStHandle->ucCmdData);

		pPreRdRoot = (ST_PREREAD_ROOT*)(pChnStHandle->PreRdRootSt);
		pPreRdCmdElmt = (ST_PREREAD_CMDELEMENT*)(pChnStHandle->PreRdCmdSt);
		pPreRdFileId = (ST_PREREAD_FILEID*)(pChnStHandle->PreRdFidSt);

		uiBuffLeftLen = 0;

		if(pChnStHandle->bGetRstRspStatus)
		{
			continue;
		}

		if(pChnStHandle->bNormalRead == EOS_FALSE)
		{
			continue;
		}

		memset(&stSimPoolRead, 0, sizeof(ioctl_simpool_read_st));

		stSimPoolRead.channelid = uiChnIndex;
		stSimPoolRead.size = SimComSerialRead(pSimComRootSt->fdSerialHdl, stSimPoolRead.buff);

		if(stSimPoolRead.size > 0)
		{		
			_UINT32 uiReadRawDataLen = 0;
			
			if(stSimPoolRead.size >= SIMPOOL_RSPREAD_MAX_SIZE)
			{
				SIMCOM_INFO("Channel %d sim pool read raw data(%d) overflow\n", uiChnIndex, stSimPoolRead.size);
				return ;
			}
			pChnStHandle->LastReadTick = tickGet();
			
			if(1) //normal
			{
                SIMCOM_DBG("test uiReadRawDataLen=%d, stSimPoolRead.size=%d,pChnStHandle->SimPoolStatus =%d\n", uiReadRawDataLen, stSimPoolRead.size,pChnStHandle->SimPoolStatus);
                SIMCOM_DBG("0uiReadOffset=%d ,uiWriteOffset=%d \n", pChnStHandle->uiReadOffset, pChnStHandle->uiWriteOffset);
                SIMCOM_DBG("pChnStHandle->SPPreRDStatus=%d\n", pChnStHandle->SPPreRDStatus);
                //special
                if(pChnStHandle->writeCmdType != 0) //data type c0/b0/b2/f2/12
                {
                    if(stSimPoolRead.size == 2) //no data
                    {
                        pChnStHandle->writeCmdType = 0;
                    }
                    else if(stSimPoolRead.size > 2)//data ...90 00
                    {
                        SIMCOM_INFO("Channel %d ###R(KeyWord)0x%02x ", uiChnIndex, pChnStHandle->writeCmdType);
                        pChnStHandle->RspBuff[pChnStHandle->uiReadOffset++] = pChnStHandle->writeCmdType;
                        pChnStHandle->uiReadOffset &= (SIMPOOL_RSPREAD_MAX_SIZE - 1);
                        pChnStHandle->writeCmdType = 0;
                    }
                }
                    
				while(uiReadRawDataLen < stSimPoolRead.size)
				{
					pChnStHandle->RspBuff[pChnStHandle->uiReadOffset++] = stSimPoolRead.buff[uiReadRawDataLen++];
					pChnStHandle->uiReadOffset &= (SIMPOOL_RSPREAD_MAX_SIZE - 1);
				}
                
				if(pChnStHandle->uiReadOffset >= pChnStHandle->uiWriteOffset)
				{
					uiBuffLeftLen = pChnStHandle->uiReadOffset - pChnStHandle->uiWriteOffset;	
				}
				else
				{
					uiBuffLeftLen = pChnStHandle->uiReadOffset + (SIMPOOL_RSPREAD_MAX_SIZE - pChnStHandle->uiWriteOffset);
				}

#ifdef	SIMCOM_PRINT_DATA						
				{
					_UCHAR8 PrintBuff[4096];
					_UINT32 uiPrintLen = 0;
					
					uiPrintLen = sprintf((PrintBuff + uiPrintLen), "Channel %d ###R(0x%02x) ", uiChnIndex, stSimPoolRead.size);
					for(i = 0; i < stSimPoolRead.size; i++)
					{
						uiPrintLen += sprintf((PrintBuff + uiPrintLen), "0x%02x ", stSimPoolRead.buff[i]);						
					}
					sprintf(PrintBuff+uiPrintLen,"\n");
                    SIMCOM_INFO("%s", PrintBuff);
				}				
#endif
                SIMCOM_DBG("1uiReadOffset=%d ,uiWriteOffset=%d ,uiBuffLeftLen=%d\n", pChnStHandle->uiReadOffset, pChnStHandle->uiWriteOffset, uiBuffLeftLen);
				if(SIMPOOL_ST_WAIT_INS == pChnStHandle->SimPoolStatus)
				{
					if((1 == uiBuffLeftLen) && (pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset] == pWrlEsccCmd->cmdData[1]))
					{
						SimComWriteData(uiChnIndex, &(pWrlEsccCmd->cmdData[5]), pWrlEsccCmd->paramLen);
						
						pChnStHandle->uiWriteOffset++;
						pChnStHandle->uiWriteOffset &= (SIMPOOL_RSPREAD_MAX_SIZE - 1);
						
						pChnStHandle->SimPoolStatus = SIMPOOL_ST_WAIT_RSP;
						pChnStHandle->WaitRspTick = tickGet();
						pChnStHandle->LastReadTick = tickGet();
                        }
					else if((uiBuffLeftLen > 1) && (pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset + uiBuffLeftLen - 1] == pWrlEsccCmd->cmdData[1]))
					{

						SimComWriteData(uiChnIndex, &(pWrlEsccCmd->cmdData[5]), pWrlEsccCmd->paramLen);
		
						pChnStHandle->uiWriteOffset += uiBuffLeftLen;
						pChnStHandle->uiWriteOffset &= (SIMPOOL_RSPREAD_MAX_SIZE - 1);
						
						pChnStHandle->SimPoolStatus = SIMPOOL_ST_WAIT_RSP;
						pChnStHandle->WaitRspTick = tickGet();		
						pChnStHandle->LastReadTick = tickGet();
						
						SIMCOM_INFO("Channel %d Get Ins(0x%x),but BuffLeftLen:%d\n", 
							uiChnIndex, pWrlEsccCmd->cmdData[1], uiBuffLeftLen);
					}
					else
					{
						if(2 == uiBuffLeftLen)
						{
							if((pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset] == 0x6b) || (pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset] == 0x69)
								|| (pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset] == 0x90))
							{
								_UCHAR8 RspBuff[1024];
								PWRLESCCRSPST pWrlEsccRsp = (PWRLESCCRSPST)(RspBuff);
								
								memset(&RspBuff, 0, sizeof(RspBuff));
								pWrlEsccRsp->rspIndex = htons(pChnStHandle->CmdIdx);
								pWrlEsccRsp->rsplen = htons(uiBuffLeftLen);
								
								for(i = 0; i < uiBuffLeftLen; i++)
								{
									pWrlEsccRsp->rspdata[i] = pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset++]; 						
									pChnStHandle->uiWriteOffset &= (SIMPOOL_RSPREAD_MAX_SIZE - 1);
								}
								
								pChnStHandle->uiTotalSendCnt += (uiBuffLeftLen + SP_ESCCRSP_HDRLEN);
								//ESCC_SessSendData(pChnStHandle->pEsccSessId, pWrlEsccRsp, (uiBuffLeftLen + SP_ESCCRSP_HDRLEN)); 
                                //weikk 20161221
                                appEvtSendBuff.chn = 0;
                                appEvtSendBuff.evtIndex = EN_APPEVT_SIMDATA;
                                appEvtSendBuff.len = uiBuffLeftLen + SP_ESCCRSP_HDRLEN;
                                appEvtSendBuff.pData = (_UCHAR8 *)pWrlEsccRsp;
                                SimComAppEvtSend(&appEvtSendBuff);
                                
								pChnStHandle->SimPoolStatus = SIMPOOL_ST_IDLE;					
								SIMCOM_INFO("Channel %d Send RspLen(Err):%d\n", uiChnIndex, uiBuffLeftLen);
							}
							else
							{
								_UCHAR8 RspBuff[1024];
								PWRLESCCRSPST pWrlEsccRsp = (PWRLESCCRSPST)(RspBuff);
								
								memset(&RspBuff, 0, sizeof(RspBuff));
								pWrlEsccRsp->rspIndex = htons(pChnStHandle->CmdIdx);
								pWrlEsccRsp->rsplen = htons(uiBuffLeftLen);
								
								for(i = 0; i < uiBuffLeftLen; i++)
								{
									pWrlEsccRsp->rspdata[i] = pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset++]; 						
									pChnStHandle->uiWriteOffset &= (SIMPOOL_RSPREAD_MAX_SIZE - 1);
								}
								
								pChnStHandle->uiTotalSendCnt += (uiBuffLeftLen + SP_ESCCRSP_HDRLEN);
								//ESCC_SessSendData(pChnStHandle->pEsccSessId, pWrlEsccRsp, (uiBuffLeftLen + SP_ESCCRSP_HDRLEN)); 
								//weikk 20161221
                                appEvtSendBuff.chn = 0;
                                appEvtSendBuff.evtIndex = EN_APPEVT_SIMDATA;
                                appEvtSendBuff.len = uiBuffLeftLen + SP_ESCCRSP_HDRLEN;
                                appEvtSendBuff.pData = (_UCHAR8 *)pWrlEsccRsp;
                                SimComAppEvtSend(&appEvtSendBuff);
                                
								pChnStHandle->SimPoolStatus = SIMPOOL_ST_IDLE;					
								
								SIMCOM_INFO("Channel %d Wait Ins,uiBuffLeftLen:%d,Wait:0x%x,Get:0x%x\n", 
									uiChnIndex, uiBuffLeftLen, pWrlEsccCmd->cmdData[1], pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset]);
								SIMCOM_INFO("Channel %d Data[0]=0x%x, Data[1]=0x%x, Data[2]=0x%x, Data[3]=0x%x, Data[4]=0x%x\n",
									uiChnIndex, pWrlEsccCmd->cmdData[0],pWrlEsccCmd->cmdData[1],pWrlEsccCmd->cmdData[2],
									pWrlEsccCmd->cmdData[3],pWrlEsccCmd->cmdData[4]);
								
								pChnStHandle->uiReadOffset = 0;
								pChnStHandle->uiWriteOffset = 0;
							}
						}
						else
						{
							_UCHAR8 RspBuff[1024];
							PWRLESCCRSPST pWrlEsccRsp = (PWRLESCCRSPST)(RspBuff);
							
							memset(&RspBuff, 0, sizeof(RspBuff));
							pWrlEsccRsp->rspIndex = htons(pChnStHandle->CmdIdx);
							pWrlEsccRsp->rsplen = htons(uiBuffLeftLen);
							
							for(i = 0; i < uiBuffLeftLen; i++)
							{
								pWrlEsccRsp->rspdata[i] = pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset++]; 						
								pChnStHandle->uiWriteOffset &= (SIMPOOL_RSPREAD_MAX_SIZE - 1); 
							}
							
							pChnStHandle->uiTotalSendCnt += (uiBuffLeftLen + SP_ESCCRSP_HDRLEN);
							//ESCC_SessSendData(pChnStHandle->pEsccSessId, pWrlEsccRsp, (uiBuffLeftLen + SP_ESCCRSP_HDRLEN)); 
							//weikk 20161221
                            appEvtSendBuff.chn = 0;
                            appEvtSendBuff.evtIndex = EN_APPEVT_SIMDATA;
                            appEvtSendBuff.len = uiBuffLeftLen + SP_ESCCRSP_HDRLEN;
                            appEvtSendBuff.pData = (_UCHAR8 *)pWrlEsccRsp;
                            SimComAppEvtSend(&appEvtSendBuff);
                                
							pChnStHandle->SimPoolStatus = SIMPOOL_ST_IDLE;					
							
							SIMCOM_INFO("Channel %d Wait Ins,uiBuffLeftLen:%d,Wait:0x%x,Get:0x%x\n", 
								uiChnIndex, uiBuffLeftLen, pWrlEsccCmd->cmdData[1], pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset]);
							SIMCOM_INFO("Channel %d Data[0]=0x%x, Data[1]=0x%x, Data[2]=0x%x, Data[3]=0x%x, Data[4]=0x%x\n",
								uiChnIndex, pWrlEsccCmd->cmdData[0],pWrlEsccCmd->cmdData[1],pWrlEsccCmd->cmdData[2],
								pWrlEsccCmd->cmdData[3],pWrlEsccCmd->cmdData[4]);

							pChnStHandle->uiReadOffset = 0;
							pChnStHandle->uiWriteOffset = 0;
						}
					}
				}
				else if(SIMPOOL_ST_WAIT_RSP == pChnStHandle->SimPoolStatus)
				{
					if((1 == uiBuffLeftLen) && (0x60 == pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset]))
					{
						SIMCOM_INFO("Channel %d Get Rsp:0x60,Delay\n", uiChnIndex);
						pChnStHandle->uiWriteOffset++;
					}
					else if(ntohs(pWrlEsccCmd->expRspLen) == uiBuffLeftLen)
					{
						_UCHAR8 RspBuff[1024];
						PWRLESCCRSPST pWrlEsccRsp = (PWRLESCCRSPST)(RspBuff);

						memset(RspBuff, 0, sizeof(RspBuff));
						pWrlEsccRsp->rspIndex = htons(pChnStHandle->CmdIdx);
						pWrlEsccRsp->rsplen = pWrlEsccCmd->expRspLen;

						for(i = 0; i < uiBuffLeftLen; i++)
						{
							pWrlEsccRsp->rspdata[i] = pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset++];							
							pChnStHandle->uiWriteOffset &= (SIMPOOL_RSPREAD_MAX_SIZE - 1);
						}

						pChnStHandle->uiTotalSendCnt += (uiBuffLeftLen + 4);

						if(0x88 == pWrlEsccCmd->cmdData[1])
						{
							_UCHAR8 C0CmdData[5] = {0xa0, 0xc0, 0x0, 0x0, 0x00};		
							if(0)//(NVM_GOIP_SIMTYPE_WCDMA == ASYS_NvmGetIntEx(NVM_PORT_SIM_TYPE, uiChnIndex))
							{
								C0CmdData[0] = 0;
							}

							ioctl_simpool_write_st stSimPoolWrite;
							memset(&stSimPoolWrite, 0, sizeof(ioctl_simpool_write_st));

							C0CmdData[4] = pWrlEsccRsp->rspdata[1];

							memcpy(stSimPoolWrite.buff, C0CmdData, sizeof(C0CmdData));
							stSimPoolWrite.size = sizeof(C0CmdData);
							stSimPoolWrite.channelid = uiChnIndex;
#ifdef	SIMCOM_PRINT_DATA
							{
								_UCHAR8 PrintBuff[4096];
								_UINT32 uiPrintLen = 0;
								
								uiPrintLen = sprintf((PrintBuff + uiPrintLen), "Channel %d ###W(0x%02x) ", stSimPoolWrite.channelid, stSimPoolWrite.size);
								for(i = 0; i < stSimPoolWrite.size; i++)
								{
									uiPrintLen += sprintf((PrintBuff + uiPrintLen), "0x%02x ", stSimPoolWrite.buff[i]); 					
								}
								sprintf(PrintBuff+uiPrintLen, "\n");
							}						
#endif

							memcpy(pWrlEsccRsp->nextcmd, C0CmdData, sizeof(C0CmdData));
							pWrlEsccRsp->nextlen = C0CmdData[4] + 3;

							SimComWriteData(uiChnIndex, stSimPoolWrite.buff, stSimPoolWrite.size);
                            pChnStHandle->SimPoolStatus = SIMPOOL_ST_NEXTCMD_WAIT_RSP;

							memset(pChnStHandle->RspForNextCmd, 0, sizeof(pChnStHandle->RspForNextCmd));
							pChnStHandle->uiRspForNextCmdLen = uiBuffLeftLen + SP_ESCCRSP_HDRLEN;
							memcpy(pChnStHandle->RspForNextCmd, pWrlEsccRsp, pChnStHandle->uiRspForNextCmdLen);
						}
						else
						{
							//ESCC_SessSendData(pChnStHandle->pEsccSessId, pWrlEsccRsp, (uiBuffLeftLen + SP_ESCCRSP_HDRLEN));	
							//weikk 20161221
                            appEvtSendBuff.chn = 0;
                            appEvtSendBuff.evtIndex = EN_APPEVT_SIMDATA;
                            appEvtSendBuff.len = uiBuffLeftLen + SP_ESCCRSP_HDRLEN;
                            appEvtSendBuff.pData = (_UCHAR8 *)pWrlEsccRsp;
                            SimComAppEvtSend(&appEvtSendBuff);
                            
							pChnStHandle->SimPoolStatus = SIMPOOL_ST_IDLE;					
							SIMCOM_INFO("Channel %d Send RspLen:%d, Index:%d\n", uiChnIndex, uiBuffLeftLen, pChnStHandle->CmdIdx);
						}
					}
					else if(ntohs(pWrlEsccCmd->expRspLen) < uiBuffLeftLen)
					{
						_UCHAR8 RspBuff[1024];
						PWRLESCCRSPST pWrlEsccRsp = (PWRLESCCRSPST)(RspBuff);
						_UINT32 j = 0;

						memset(&RspBuff, 0, sizeof(RspBuff));
						pWrlEsccRsp->rspIndex = htons(pChnStHandle->CmdIdx);
						//SIMCOM_INFO("send rsp index:%d\n", pChnStHandle->CmdIdx);
						pWrlEsccRsp->rsplen = pWrlEsccCmd->expRspLen;

						for(i = 0; i < uiBuffLeftLen; i++)
						{
							if(i >= (uiBuffLeftLen - ntohs(pWrlEsccCmd->expRspLen)))
							{
								pWrlEsccRsp->rspdata[j++] = pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset++];
							}
							else
							{
								pChnStHandle->uiWriteOffset++;
							}
							pChnStHandle->uiWriteOffset &= (SIMPOOL_RSPREAD_MAX_SIZE - 1);
						}
											
						pChnStHandle->uiTotalSendCnt += (ntohs(pWrlEsccCmd->expRspLen) + SP_ESCCRSP_HDRLEN);
						//ESCC_SessSendData(pChnStHandle->pEsccSessId, pWrlEsccRsp, (ntohs(pWrlEsccCmd->expRspLen) + SP_ESCCRSP_HDRLEN));	
						//weikk 20161221
                        appEvtSendBuff.chn = 0;
                        appEvtSendBuff.evtIndex = EN_APPEVT_SIMDATA;
                        appEvtSendBuff.len = ntohs(pWrlEsccCmd->expRspLen) + SP_ESCCRSP_HDRLEN;
                        appEvtSendBuff.pData = (_UCHAR8 *)pWrlEsccRsp;
                        SimComAppEvtSend(&appEvtSendBuff);
                        
						pChnStHandle->SimPoolStatus = SIMPOOL_ST_IDLE;					
						SIMCOM_INFO("Channel %d Send RspLen:%d, but BuffLeftLen:%d\n", uiChnIndex, ntohs(pWrlEsccCmd->expRspLen), uiBuffLeftLen);						
					}
					else
					{
						if(2 == uiBuffLeftLen)
						{
							if((pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset] == 0x94) || (pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset] == 0x6c)
								|| (pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset] == 0x69) || (pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset] == 0x6b)
								|| (pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset] == 0x6f) || (pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset] == 0x67)
								|| (pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset] == 0x98) || (pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset] == 0x61))
							{
								_UCHAR8 RspBuff[1024];
								PWRLESCCRSPST pWrlEsccRsp = (PWRLESCCRSPST)(RspBuff);
								
								memset(&RspBuff, 0, sizeof(RspBuff));
								pWrlEsccRsp->rspIndex = htons(pChnStHandle->CmdIdx);
								pWrlEsccRsp->rsplen = htons(uiBuffLeftLen);
								
								for(i = 0; i < uiBuffLeftLen; i++)
								{
									pWrlEsccRsp->rspdata[i] = pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset++]; 						
									pChnStHandle->uiWriteOffset &= (SIMPOOL_RSPREAD_MAX_SIZE - 1);
								}
								
								pChnStHandle->uiTotalSendCnt += (uiBuffLeftLen + SP_ESCCRSP_HDRLEN);
								//ESCC_SessSendData(pChnStHandle->pEsccSessId, pWrlEsccRsp, (uiBuffLeftLen + SP_ESCCRSP_HDRLEN)); 
								//weikk 20161221
								appEvtSendBuff.chn = 0;
                                appEvtSendBuff.evtIndex = EN_APPEVT_SIMDATA;
                                appEvtSendBuff.len = uiBuffLeftLen + SP_ESCCRSP_HDRLEN;
                                appEvtSendBuff.pData = (_UCHAR8 *)pWrlEsccRsp;
                                SimComAppEvtSend(&appEvtSendBuff);
                            
								pChnStHandle->SimPoolStatus = SIMPOOL_ST_IDLE;					
								SIMCOM_INFO("Channel %d Send RspLen(Err):%d\n", uiChnIndex, uiBuffLeftLen);
							}
							else
							{
								SIMCOM_INFO("Channel %d GetRspLen:%d,ExpRspLen:%d\n", uiChnIndex, uiBuffLeftLen, ntohs(pWrlEsccCmd->expRspLen));								
							}
						}						
						else
						{
							SIMCOM_INFO("Channel %d GetRspLen:%d,ExpRspLen:%d\n", uiChnIndex, uiBuffLeftLen, ntohs(pWrlEsccCmd->expRspLen));
						}
					}
				}
				else if(SIMPOOL_ST_NEXTCMD_WAIT_RSP == pChnStHandle->SimPoolStatus)
				{
					PWRLESCCRSPST pWrlEsccRspLast = (PWRLESCCRSPST)(pChnStHandle->RspForNextCmd);
					
					if(pWrlEsccRspLast->nextlen == uiBuffLeftLen)
					{
						_UCHAR8 RspBuff[1024];
						PWRLESCCRSPST pWrlEsccRsp = (PWRLESCCRSPST)(RspBuff);

						memset(RspBuff, 0, sizeof(RspBuff));

						memcpy(pWrlEsccRsp, pWrlEsccRspLast, pChnStHandle->uiRspForNextCmdLen);
						
						pWrlEsccRsp->rsplen = htons(ntohs(pWrlEsccRsp->rsplen) + uiBuffLeftLen);

						for(i = 0; i < uiBuffLeftLen; i++)
						{
							pWrlEsccRsp->rspdata[2 + i] = pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset++]; 						
							pChnStHandle->uiWriteOffset &= (SIMPOOL_RSPREAD_MAX_SIZE - 1);
						}

						pChnStHandle->uiTotalSendCnt += (uiBuffLeftLen);

						//ESCC_SessSendData(pChnStHandle->pEsccSessId, pWrlEsccRsp, (uiBuffLeftLen + pChnStHandle->uiRspForNextCmdLen)); 
						//weikk 20161221
						appEvtSendBuff.chn = 0;
                        appEvtSendBuff.evtIndex = EN_APPEVT_SIMDATA;
                        appEvtSendBuff.len = uiBuffLeftLen + pChnStHandle->uiRspForNextCmdLen;
                        appEvtSendBuff.pData = (_UCHAR8 *)pWrlEsccRsp;
                        SimComAppEvtSend(&appEvtSendBuff);
                        
						pChnStHandle->SimPoolStatus = SIMPOOL_ST_IDLE;					
						SIMCOM_INFO("Channel %d Send RspLen:%d, Index:%d\n", uiChnIndex, uiBuffLeftLen, pChnStHandle->CmdIdx);
					}
					else if(pWrlEsccRspLast->nextlen < uiBuffLeftLen)
					{
						_UCHAR8 RspBuff[1024];
						PWRLESCCRSPST pWrlEsccRsp = (PWRLESCCRSPST)(RspBuff);
						_UINT32 j = 0;

						memset(&RspBuff, 0, sizeof(RspBuff));
						pWrlEsccRsp->rspIndex = htons(pChnStHandle->CmdIdx);
						pWrlEsccRsp->rsplen = pWrlEsccCmd->expRspLen;

						for(i = 0; i < uiBuffLeftLen; i++)
						{
							if(i >= (uiBuffLeftLen - ntohs(pWrlEsccCmd->expRspLen)))
							{
								pWrlEsccRsp->rspdata[j++] = pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset++];
							}
							else
							{
								pChnStHandle->uiWriteOffset++;
							}
							pChnStHandle->uiWriteOffset &= (SIMPOOL_RSPREAD_MAX_SIZE - 1);
						}
											
						pChnStHandle->uiTotalSendCnt += (ntohs(pWrlEsccCmd->expRspLen) + SP_ESCCRSP_HDRLEN);
						//ESCC_SessSendData(pChnStHandle->pEsccSessId, pWrlEsccRsp, (ntohs(pWrlEsccCmd->expRspLen) + SP_ESCCRSP_HDRLEN)); 
						//weikk 20161221
						appEvtSendBuff.chn = 0;
                        appEvtSendBuff.evtIndex = EN_APPEVT_SIMDATA;
                        appEvtSendBuff.len = ntohs(pWrlEsccCmd->expRspLen) + SP_ESCCRSP_HDRLEN;
                        appEvtSendBuff.pData = (_UCHAR8 *)pWrlEsccRsp;
                        SimComAppEvtSend(&appEvtSendBuff);
                        
						pChnStHandle->SimPoolStatus = SIMPOOL_ST_IDLE;					
						SIMCOM_INFO("Channel %d Send RspLen:%d, but BuffLeftLen:%d\n", uiChnIndex, pWrlEsccRspLast->nextlen, uiBuffLeftLen); 					
					}
					else
					{
						if(2 == uiBuffLeftLen)
						{
							if((pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset] == 0x94) || (pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset] == 0x6c)
								|| (pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset] == 0x69) || (pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset] == 0x6b)
								|| (pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset] == 0x6f) || (pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset] == 0x67)
								|| (pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset] == 0x98))
							{
								_UCHAR8 RspBuff[1024];
								PWRLESCCRSPST pWrlEsccRsp = (PWRLESCCRSPST)(RspBuff);
								
								memset(&RspBuff, 0, sizeof(RspBuff));
								pWrlEsccRsp->rspIndex = htons(pChnStHandle->CmdIdx);
								pWrlEsccRsp->rsplen = htons(uiBuffLeftLen);
								
								for(i = 0; i < uiBuffLeftLen; i++)
								{
									pWrlEsccRsp->rspdata[i] = pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset++]; 						
									pChnStHandle->uiWriteOffset &= (SIMPOOL_RSPREAD_MAX_SIZE - 1);
								}
								
								pChnStHandle->uiTotalSendCnt += (uiBuffLeftLen + SP_ESCCRSP_HDRLEN);
								//ESCC_SessSendData(pChnStHandle->pEsccSessId, pWrlEsccRsp, (uiBuffLeftLen + SP_ESCCRSP_HDRLEN)); 
								//weikk 20161221
        						appEvtSendBuff.chn = 0;
                                appEvtSendBuff.evtIndex = EN_APPEVT_SIMDATA;
                                appEvtSendBuff.len = uiBuffLeftLen + SP_ESCCRSP_HDRLEN;
                                appEvtSendBuff.pData = (_UCHAR8 *)pWrlEsccRsp;
                                SimComAppEvtSend(&appEvtSendBuff);
                                
								pChnStHandle->SimPoolStatus = SIMPOOL_ST_IDLE;					
								SIMCOM_INFO("Channel %d Send RspLen(Err):%d\n", uiChnIndex, uiBuffLeftLen);
							}
							else
							{
								SIMCOM_INFO("Channel %d GetRspLen:%d,ExpRspLen:%d\n", uiChnIndex, uiBuffLeftLen, pWrlEsccRspLast->nextlen);								
							}
						}
						else
						{
							SIMCOM_INFO("Channel %d GetRspLen:%d,ExpRspLen:%d\n", uiChnIndex, uiBuffLeftLen, pWrlEsccRspLast->nextlen);
						}
					}
				}
				else if(SIMPOOL_ST_IDLE == pChnStHandle->SimPoolStatus)
				{
					if(uiBuffLeftLen > 0)
					{
						_UCHAR8 RspBuff[1024];
						PWRLESCCRSPST pWrlEsccRsp = (PWRLESCCRSPST)(RspBuff);

						memset(&RspBuff, 0, sizeof(RspBuff));
						pWrlEsccRsp->rspIndex = 0; // 0 is a special index
						pWrlEsccRsp->rsplen = htons(uiBuffLeftLen);

						for(i = 0; i < uiBuffLeftLen; i++)
						{
							pWrlEsccRsp->rspdata[i] = pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset++]; 						
							pChnStHandle->uiWriteOffset &= (SIMPOOL_RSPREAD_MAX_SIZE - 1);
						}
											
						pChnStHandle->uiTotalSendCnt += (uiBuffLeftLen + SP_ESCCRSP_HDRLEN);
						//ESCC_SessSendData(pChnStHandle->pEsccSessId, pWrlEsccRsp, (uiBuffLeftLen + SP_ESCCRSP_HDRLEN));	
						//weikk 20161221
						appEvtSendBuff.chn = 0;
                        appEvtSendBuff.evtIndex = EN_APPEVT_SIMDATA;
                        appEvtSendBuff.len = uiBuffLeftLen + SP_ESCCRSP_HDRLEN;
                        appEvtSendBuff.pData = (_UCHAR8 *)pWrlEsccRsp;
                        SimComAppEvtSend(&appEvtSendBuff);
                        
						pChnStHandle->SimPoolStatus = SIMPOOL_ST_IDLE;
						
						SIMCOM_INFO("Channel %d Send Len:%d In Idle\n", uiChnIndex, uiBuffLeftLen);
					}
				}
				else if(SIMPOOL_ST_PRERD == pChnStHandle->SimPoolStatus)
				{
					SPPreRd_Read_SIM(uiChnIndex, uiBuffLeftLen);
				}
				else if(SIMPOOL_ST_PREFIX_WAIT_INS == pChnStHandle->SimPoolStatus)
				{
					if(((1 == uiBuffLeftLen) && (pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset] == 0xA4))
						|| ((uiBuffLeftLen > 1) && (pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset + uiBuffLeftLen - 1] == 0xA4)))
					{
						ioctl_simpool_write_st stSimPoolWrite;
							
						memset(&stSimPoolWrite, 0, sizeof(ioctl_simpool_write_st));

						/*if((NVM_GOIP_SIMTYPE_WCDMA == ASYS_NvmGetIntEx(NVM_PORT_SIM_TYPE, uiChnIndex))
							&& (((pWrlEsccCmd->PrefixFid[pChnStHandle->uiPrefixSelectIdx][0] == 0xff) && (pWrlEsccCmd->PrefixFid[pChnStHandle->uiPrefixSelectIdx][1] == 0xee))
							|| ((pWrlEsccCmd->PrefixFid[pChnStHandle->uiPrefixSelectIdx][0] == 0x7f) && (pWrlEsccCmd->PrefixFid[pChnStHandle->uiPrefixSelectIdx][1] == 0xff))))
                        */
                        if(((pWrlEsccCmd->PrefixFid[pChnStHandle->uiPrefixSelectIdx][0] == 0xff) && (pWrlEsccCmd->PrefixFid[pChnStHandle->uiPrefixSelectIdx][1] == 0xee))
							|| ((pWrlEsccCmd->PrefixFid[pChnStHandle->uiPrefixSelectIdx][0] == 0x7f) && (pWrlEsccCmd->PrefixFid[pChnStHandle->uiPrefixSelectIdx][1] == 0xff)))
						{
							memcpy(stSimPoolWrite.buff, pChnStHandle->AIDBuff, pChnStHandle->AIDLen);
							stSimPoolWrite.size = pChnStHandle->AIDLen;
						}
						else
						{
							memcpy(stSimPoolWrite.buff, &(pWrlEsccCmd->PrefixFid[pChnStHandle->uiPrefixSelectIdx][0]), 2);
							stSimPoolWrite.size = 2;
						}
						stSimPoolWrite.channelid = uiChnIndex;
						pChnStHandle->uiPrefixSelectIdx++;

#ifdef	SIMCOM_PRINT_DATA
						{
							_UCHAR8 PrintBuff[4096];
							_UINT32 uiPrintLen = 0;
							
							uiPrintLen = sprintf((PrintBuff + uiPrintLen), "Channel %d ###W(0x%02x) ", stSimPoolWrite.channelid, stSimPoolWrite.size);
							for(i = 0; i < stSimPoolWrite.size; i++)
							{
								uiPrintLen += sprintf((PrintBuff + uiPrintLen), "0x%02x ", stSimPoolWrite.buff[i]);						
							}
							sprintf(PrintBuff+uiPrintLen, "\n");
							
						}						
#endif
						//weikk 20160428
						SimComWriteData(uiChnIndex, stSimPoolWrite.buff, stSimPoolWrite.size);
						
						pChnStHandle->uiWriteOffset += uiBuffLeftLen;
						pChnStHandle->uiWriteOffset &= (SIMPOOL_RSPREAD_MAX_SIZE - 1);
						
						pChnStHandle->SimPoolStatus = SIMPOOL_ST_PREFIX_WAIT_RSP;
						pChnStHandle->WaitRspTick = tickGet();
						pChnStHandle->LastReadTick = tickGet();
					}
				}
				else if(SIMPOOL_ST_PREFIX_WAIT_RSP == pChnStHandle->SimPoolStatus)
				{
					if((2 == uiBuffLeftLen))
					{
						ioctl_simpool_write_st stSimPoolWrite;

						pChnStHandle->uiWriteOffset += 2;
						pChnStHandle->uiWriteOffset &= (SIMPOOL_RSPREAD_MAX_SIZE - 1);

						memset(&stSimPoolWrite, 0, sizeof(ioctl_simpool_write_st));
						if(pChnStHandle->uiPrefixSelectIdx < ntohs(pWrlEsccCmd->PrefixNum))
						{
							_UCHAR8 A4CmdData[5] = {0xa0, 0xa4, 0x0, 0x0, 0x02};

							if(0)//((NVM_GOIP_SIMTYPE_WCDMA == ASYS_NvmGetIntEx(NVM_PORT_SIM_TYPE, uiChnIndex)) && (pChnStHandle->bSupportUSIM))
							{
								A4CmdData[0] = 0x0;
								A4CmdData[3] = 0x04;
								
								if(((pWrlEsccCmd->PrefixFid[pChnStHandle->uiPrefixSelectIdx][0] == 0xff) && (pWrlEsccCmd->PrefixFid[pChnStHandle->uiPrefixSelectIdx][1] == 0xee))
									|| ((pWrlEsccCmd->PrefixFid[pChnStHandle->uiPrefixSelectIdx][0] == 0x7f) && (pWrlEsccCmd->PrefixFid[pChnStHandle->uiPrefixSelectIdx][1] == 0xff)))
								{
									A4CmdData[2] = 0x4;
									A4CmdData[4] = pChnStHandle->AIDLen;
								}
							}

                            #if 0
							memcpy(stSimPoolWrite.buff, A4CmdData, sizeof(A4CmdData));
							stSimPoolWrite.size = sizeof(A4CmdData);
							stSimPoolWrite.channelid = uiChnIndex;
							//weikk_add_file
							iRetVal = SimComSerialWrite(pSimComRootSt->fdSerialHdl, stSimPoolWrite.buff, stSimPoolWrite.size);
                            if(iRetVal < 0){
                                SIMCOM_INFO("Channel %d SimPool Write Data Error.\n", stSimPoolWrite.channelid);
                            }
                            pChnStHandle->SimPoolStatus = SIMPOOL_ST_PREFIX_WAIT_INS;	
							pChnStHandle->expRspLen = 1;
                            #else
                            _UCHAR8 WriteDataEx[16] = {0xa0, 0xa4, 0x0, 0x0, 0x2,}; 

                            memcpy(WriteDataEx, A4CmdData, 5);
                            WriteDataEx[5] = pWrlEsccCmd->PrefixFid[pChnStHandle->uiPrefixSelectIdx][0];
                            WriteDataEx[6] = pWrlEsccCmd->PrefixFid[pChnStHandle->uiPrefixSelectIdx][1];
                            stSimPoolWrite.size = 7;
							stSimPoolWrite.channelid = uiChnIndex;
                			/* Send FileId*/
                			SimComWriteData(uiChnIndex, WriteDataEx, 7);
            											
            				pChnStHandle->SimPoolStatus = SIMPOOL_ST_PREFIX_WAIT_RSP;	
                            pChnStHandle->uiPrefixSelectIdx ++;
							pChnStHandle->expRspLen = 1;
                            #endif
#ifdef	SIMCOM_PRINT_DATA
							{
								_UCHAR8 PrintBuff[4096];
								_UINT32 uiPrintLen = 0;
								
								uiPrintLen = sprintf((PrintBuff + uiPrintLen), "Channel %d ###W(0x%02x) ", stSimPoolWrite.channelid, stSimPoolWrite.size);
								for(i = 0; i < stSimPoolWrite.size; i++)
								{
									uiPrintLen += sprintf((PrintBuff + uiPrintLen), "0x%02x ", stSimPoolWrite.buff[i]); 					
								}
								sprintf(PrintBuff+uiPrintLen, "\n");
							}						
#endif

						}
						else
						{
							stSimPoolWrite.size = pWrlEsccCmd->cmdLen;
							stSimPoolWrite.channelid = uiChnIndex;
							
							pChnStHandle->CmdIdx = ntohs(pWrlEsccCmd->cmdIndex);

							pChnStHandle->uiTotalRcvCnt +=	pWrlEsccCmd->cmdLen;

#ifdef	SIMCOM_PRINT_DATA
							{
								_UCHAR8 PrintBuff[4096];
								_UINT32 uiPrintLen = 0;
								
								uiPrintLen = sprintf((PrintBuff + uiPrintLen), "Channel %d ###W(0x%02x) ", stSimPoolWrite.channelid, stSimPoolWrite.size);
								for(i = 0; i < stSimPoolWrite.size; i++)
								{
									uiPrintLen += sprintf((PrintBuff + uiPrintLen), "0x%02x ", stSimPoolWrite.buff[i]);						
								}
								sprintf(PrintBuff+uiPrintLen,"\n");
							}				
#endif						

							//SIMCOM_INFO("Channel %d Recv Cmdidx %d, cmdLen:%d, expRspLen = %d\n", evt->channel, pChnStHandle->CmdIdx, pWrlEsccCmd->cmdLen, ntohs(pWrlEsccCmd->expRspLen));
							//weikk 20160428
							#if 1   //add key of file type
                            if (pWrlEsccCmd->paramLen > 0) {
                                stSimPoolWrite.size = pWrlEsccCmd->cmdLen + pWrlEsccCmd->paramLen;
                                SIMCOM_DBG ("*************test ************** 000\n");
                            }
                            else
                            {
                                stSimPoolWrite.size = pWrlEsccCmd->cmdLen;
                            }

                            memcpy(stSimPoolWrite.buff, pWrlEsccCmd->cmdData, stSimPoolWrite.size);
                            
                            //pWrlEsccCmd->paramLen = 0;
                            #endif
							SimComWriteData(uiChnIndex, stSimPoolWrite.buff, stSimPoolWrite.size);

							if(0)//(pWrlEsccCmd->paramLen > 0)
							{
								pChnStHandle->SimPoolStatus = SIMPOOL_ST_WAIT_INS;				
							}
							else
							{
								pChnStHandle->SimPoolStatus = SIMPOOL_ST_WAIT_RSP;
								pChnStHandle->WaitRspTick = tickGet();
								pChnStHandle->LastReadTick = tickGet();								
							}
						}
					}
				}
			}
			else
			{
				pChnStHandle->uiTotalSendCnt += stSimPoolRead.size;
				//ESCC_SessSendData(pChnStHandle->pEsccSessId, stSimPoolRead.buff, stSimPoolRead.size);
				//weikk 20161221
				appEvtSendBuff.chn = 0;
                appEvtSendBuff.evtIndex = EN_APPEVT_SIMDATA;
                appEvtSendBuff.len = stSimPoolRead.size;
                appEvtSendBuff.pData = (_UCHAR8 *)stSimPoolRead.buff;
                SimComAppEvtSend(&appEvtSendBuff);
                
                
#ifdef	SIMCOM_PRINT_DATA						
				{
					_UCHAR8 PrintBuff[4096];
					_UINT32 uiPrintLen = 0;
					
					uiPrintLen = sprintf((PrintBuff + uiPrintLen), "Channel %d ###R(0x%02x) ", uiChnIndex, stSimPoolRead.size);
					for(i = 0; i < stSimPoolRead.size; i++)
					{
						uiPrintLen += sprintf((PrintBuff + uiPrintLen), "0x%02x ", stSimPoolRead.buff[i]);						
					}
					sprintf(PrintBuff+uiPrintLen,"\n");
				}				
#endif
				
			}
		}
		else
		{
			if((uiBuffLeftLen > 0) 
				&& (SIMPOOL_ST_WAIT_RSP == pChnStHandle->SimPoolStatus)
				&& (tickGet() - pChnStHandle->LastReadTick) > 50)
			{
				_UCHAR8 RspBuff[1024];
				PWRLESCCRSPST pWrlEsccRsp = (PWRLESCCRSPST)(RspBuff);
				
				memset(&RspBuff, 0, sizeof(RspBuff));
				pWrlEsccRsp->rspIndex = htons(pChnStHandle->CmdIdx);
				SIMCOM_INFO("Channel %d send rsp timeout:%d,Send:%d,ExpLen:%d\n", uiChnIndex, pChnStHandle->CmdIdx, 
					uiBuffLeftLen, ntohs(pWrlEsccCmd->expRspLen));

				pChnStHandle->uiTimeoutRsp++;
				
				pWrlEsccRsp->rsplen = htons(uiBuffLeftLen);
				
				for(i = 0; i < uiBuffLeftLen; i++)
				{
					pWrlEsccRsp->rspdata[i] = pChnStHandle->RspBuff[pChnStHandle->uiWriteOffset++];
					pChnStHandle->uiWriteOffset &= (SIMPOOL_RSPREAD_MAX_SIZE - 1);
				}
													
				pChnStHandle->uiTotalSendCnt += (uiBuffLeftLen + SP_ESCCRSP_HDRLEN);
				//ESCC_SessSendData(pChnStHandle->pEsccSessId, pWrlEsccRsp, (uiBuffLeftLen + SP_ESCCRSP_HDRLEN)); 
				//weikk 20161221
				appEvtSendBuff.chn = 0;
                appEvtSendBuff.evtIndex = EN_APPEVT_SIMDATA;
                appEvtSendBuff.len = uiBuffLeftLen + SP_ESCCRSP_HDRLEN;
                appEvtSendBuff.pData = (_UCHAR8 *)pWrlEsccRsp;
                SimComAppEvtSend(&appEvtSendBuff);
                
				pChnStHandle->SimPoolStatus = SIMPOOL_ST_IDLE;
			}
		}
    }
}


static _INT32 simcomSetFPGAEtu(_UINT32 uiChannelId, _INT32 ETU)
{
    #if 0
	ioctl_simpool_etu_st   stSimPoolETU;
    PSIMCOMROOTST         pSimComRootSt;
    PSIMCOMCHNST          pChnStHandle = NULL;
	_INT32 iRetVal = -1;

    pSimComRootSt = (PSIMCOMROOTST)&stSimComRootSt;
	pChnStHandle = &pSimComRootSt->pSimComChnSt[uiChannelId];
	
	memset(&stSimPoolETU, 0, sizeof(ioctl_simpool_etu_st));
	stSimPoolETU.channelid = uiChannelId;
	stSimPoolETU.etu = ETU;
	//weikk 20160428
	//set ETU
	//iRetVal = ioctl(pSimComRootSt->fFpgaHandle, SIMPOOL_SET_FPGA_ETU, &stSimPoolETU);
	if(-1 == iRetVal)
	{
		//SIMCOM_INFO("Channel %d SimPool Set ETU Error\n", stSimPoolETU.channelid);
	}
    #endif
	return EOS_OK;
}

static _UINT32 simcomGetRstRspTimerCB(_UINT32 uiChannelId, _UINT32 bLightLed)
{
    PSIMCOMROOTST         pSimComRootSt;
    PSIMCOMCHNST          pChnStHandle = NULL;
	ioctl_simpool_read_st stSimPoolRead;
	ioctl_simpool_write_st stSimPoolWrite;
	_UCHAR8 PPSBuff[4] = {0xff, 0x10, 0x94, 0x7b};

    pSimComRootSt = (PSIMCOMROOTST)&stSimComRootSt;
	pChnStHandle = &pSimComRootSt->pSimComChnSt[uiChannelId];

	if(pChnStHandle->GetRstRspTimerId > 0)
	{
        CommonTimerStop((_UINT32)pChnStHandle->GetRstRspTimerId);
	}
	memset(&stSimPoolRead, 0, sizeof(ioctl_simpool_read_st));
	
	stSimPoolRead.channelid = uiChannelId;

	//weikk 20160428
	stSimPoolRead.size = SimComSerialRead(pSimComRootSt->fdSerialHdl, stSimPoolRead.buff);
	if(stSimPoolRead.size > 0)
	{		
		_UINT32 uiCnt = 0;
		
		SIMCOM_INFO("Channel %d Rst Rsp buff,len:%d\n", uiChannelId, stSimPoolRead.size);
		for(uiCnt = 0; uiCnt < stSimPoolRead.size; uiCnt++)
		{
			SIMCOM_INFO("[%d]:0x%x\n", uiCnt, stSimPoolRead.buff[uiCnt]);
		}
		
		if(stSimPoolRead.size <= sizeof(pChnStHandle->ucRstRsp))
		{
			memset(pChnStHandle->ucRstRsp, 0, sizeof(pChnStHandle->ucRstRsp));
			memcpy(pChnStHandle->ucRstRsp, stSimPoolRead.buff, stSimPoolRead.size);
		}

		if(stSimPoolRead.size > sizeof(pChnStHandle->RstRspBuff))
		{
			SIMCOM_INFO("Channel %d Rsp Data too Large(%d)\n", uiChannelId, stSimPoolRead.size);
			return EOS_OK;
		}

		pChnStHandle->bGetRstRspDone = EOS_TRUE;
		memcpy(pChnStHandle->RstRspBuff, stSimPoolRead.buff, stSimPoolRead.size);
		pChnStHandle->RstRspBuffLen = stSimPoolRead.size;
		SIMCOM_INFO("Channel %d Get Rsp Data(%d),Ok\n", uiChannelId, stSimPoolRead.size);
		
#if 1 //wkk//#ifdef USE_HIGH_BAUDRATE
		memset(&stSimPoolWrite, 0, sizeof(ioctl_simpool_write_st));
		memcpy(stSimPoolWrite.buff, PPSBuff, sizeof(PPSBuff));
		stSimPoolWrite.size = sizeof(PPSBuff);
		stSimPoolWrite.channelid = uiChannelId;
		//weikk 20160428
		//iRetVal = SimComSerialWrite(pSimComRootSt->fdSerialHdl, stSimPoolWrite.buff, stSimPoolWrite.size);
        if(0)//(iRetVal < 0)
        {
            SIMCOM_INFO("Channel %d SimPool Write Data Error.\n", stSimPoolWrite.channelid);
        }
		if(pChnStHandle->GetPPSRspTimerId > 0)
		{
            CommonTimerStop((_UINT32)pChnStHandle->GetPPSRspTimerId);
            CommonTimerStart((_UINT32)pChnStHandle->GetPPSRspTimerId, 150, 0);
		}
#else

		SIMCOM_INFO("Channel %d Get PPS OK\n", uiChannelId);				
		pChnStHandle->bGetRstRspStatus = EOS_FALSE; 
		simcomSetRspSignal(uiChannelId, 0); 

		//simcomWriteData(uiChannelId, WriteData, 5);

		//SIMCOM_INFO("Channel %d Set PreRead Step 0\n", uiChannelId);
		//pChnStHandle->SimPoolStatus = SIMPOOL_ST_IDLE;
		//pChnStHandle->CmdIdx = 0;

		pChnStHandle->uiReadOffset = 0;
		pChnStHandle->uiWriteOffset = 0;
		//pChnStHandle->PreReadStep = 0;
		pChnStHandle->bNormalRead = EOS_TRUE;
		pChnStHandle->bSimOk = EOS_TRUE;

#endif		
		
	}
	else
	{
		SIMCOM_INFO("Channel %d Get Rsp Data(%d),Error\n", uiChannelId, stSimPoolRead.size);
		simcomRstSim(uiChannelId);
	}
			
	return EOS_OK;
}

static _UINT32 simcomRstSim(_UINT32 uiChannelId)
{	
    PSIMCOMROOTST         pSimComRootSt;
    PSIMCOMCHNST          pChnStHandle = NULL;

    pSimComRootSt = (PSIMCOMROOTST)&stSimComRootSt;
	pChnStHandle = &pSimComRootSt->pSimComChnSt[uiChannelId];

    if(pChnStHandle->bSimExisted == EOS_FALSE)
    {
        SIMCOM_INFO("Channel %d Sim reset faild\n", uiChannelId);
        return EOS_OK;
    }
    //weikk 20160428
	SimComCardReset(pSimComRootSt->fdSerialHdl);
    SIMCOM_INFO("Channel %d Sim reset\n", uiChannelId);
	
	if(pChnStHandle->GetRstRspTimerId > 0)
	{
        CommonTimerStop((_UINT32)pChnStHandle->GetRstRspTimerId);
        CommonTimerStart((_UINT32)pChnStHandle->GetRstRspTimerId, SIMPOOL_GETPPS_TIME, 0);
	}
						
	return EOS_OK;
}

static _UINT32 simcomGetPPSRspTimerCB(_UINT32 uiChannelId, _UINT32 bLightLed)
{
    PSIMCOMROOTST         pSimComRootSt;
    PSIMCOMCHNST          pChnStHandle = NULL;
	ioctl_simpool_read_st stSimPoolRead;
	//_UCHAR8 PPSBuff[4] = {0xff, 0x10, 0x94, 0x7b};
	_INT32 iRetVal = -1;

    pSimComRootSt = (PSIMCOMROOTST)&stSimComRootSt;
	pChnStHandle = &pSimComRootSt->pSimComChnSt[uiChannelId];

	if(pChnStHandle->GetPPSRspTimerId > 0)
	{
        CommonTimerStop((_UINT32)pChnStHandle->GetPPSRspTimerId);
	}
	
	memset(&stSimPoolRead, 0, sizeof(ioctl_simpool_read_st));
	
	stSimPoolRead.channelid = uiChannelId;

	//weikk 20160428
	stSimPoolRead.size = SimComSerialRead(pSimComRootSt->fdSerialHdl, stSimPoolRead.buff);
	
	if(1)//(stSimPoolRead.size > 0)
	{				
		if(1)//if(0 == memcmp(stSimPoolRead.buff, PPSBuff, sizeof(PPSBuff)))
		{
			//ST_PREREAD_ROOT* pPreRdRoot = NULL;
			_UCHAR8 WriteData[5] = {0xa0, 0xa4, 0x0, 0x0, 0x2}; 															
			
			SIMCOM_INFO("Channel %d Get PPS OK\n", uiChannelId);				
			pChnStHandle->bGetRstRspStatus = EOS_FALSE;	
			simcomSetFPGAEtu(uiChannelId, 1);

			//simcomWriteData(uiChannelId, WriteData, 5);
			
			//SIMCOM_INFO("Channel %d Set PreRead Step 0\n", uiChannelId);
			//pChnStHandle->SimPoolStatus = SIMPOOL_ST_IDLE;
			//pChnStHandle->CmdIdx = 0;
			
			pChnStHandle->uiReadOffset = 0;
			pChnStHandle->uiWriteOffset = 0;

			pChnStHandle->bNormalRead = EOS_TRUE;
			pChnStHandle->bSimOk = EOS_TRUE;
			pChnStHandle->bHighBaudrate = EOS_TRUE;

			if(bLightLed)
			{
				//simcomLedOn(uiChannelId);
			}
			
			if(pChnStHandle->bNeedPreRead)
			{				
				_UCHAR8 WriteDataEx[16] = {0x0}; 
				_UINT32 uiSizeTemp = 0;

				ST_PREREAD_FID* PreReadFID = NULL;

                if(pChnStHandle->simCardType == EN_SIMTYPE_USIM)
				    PreReadFID = PreReadFID_UC15_SIM;	
                else if(pChnStHandle->simCardType == EN_SIMTYPE_CTCC)
				    PreReadFID = PreReadFID_MC323;

				if(0)//(NVM_GOIP_SIMTYPE_WCDMA == ASYS_NvmGetIntEx(NVM_PORT_SIM_TYPE, uiChannelId))
				{				
					WriteData[0] = 0x0;
					WriteData[3] = 0x4;	
					pChnStHandle->bSupportUSIM = EOS_TRUE;
				}

				/* Add FileId */
				uiSizeTemp = sizeof(WriteData);
				
				memcpy(WriteDataEx, WriteData, uiSizeTemp);

				memcpy(&WriteDataEx[uiSizeTemp], PreReadFID[pChnStHandle->uiPreRdIdx].fileid, sizeof(PreReadFID[pChnStHandle->uiPreRdIdx].fileid));
				
				uiSizeTemp += sizeof(PreReadFID[pChnStHandle->uiPreRdIdx].fileid);
					
				/* Send FileId*/
				SimComWriteData(uiChannelId, WriteDataEx, uiSizeTemp);
				
				pChnStHandle->SimPoolStatus = SIMPOOL_ST_PRERD;

				/* Send A0 A4 00 00 02 */
				pChnStHandle->SPPreRDStatus = SPPRERD_SUBST_A4RSPWAIT;

				pChnStHandle->uiPreRdIdx = 0;
				
				memset(pChnStHandle->PreRdFidSt, 0, SP_MAX_PRERD_FILE_SISE);
				
				memset(pChnStHandle->PreRdRootSt, 0, SP_MAX_PRERD_ROOT_SISE);
				
				pChnStHandle->bNeedPreRead = EOS_FALSE;
				
				pChnStHandle->uiB0CurrentIdx = 0;
				pChnStHandle->uiB2CurrentIdx = 0;
			}
			else
			{
				if(pChnStHandle->bHasBakCmd)
				{
					_UINT32 i = 0;
					
					ioctl_simpool_write_st stSimPoolWrite;
					PWRLESCCCMDST pWrlEsccCmd = (PWRLESCCCMDST)(pChnStHandle->ucCmdData);
					
					memset(&stSimPoolWrite, 0, sizeof(ioctl_simpool_write_st));
				
					if(ntohs(pWrlEsccCmd->PrefixNum) > 0)
					{
						_UCHAR8 A4CmdData[5] = {0xa0, 0xa4, 0x0, 0x0, 0x02};
						if(0)//((NVM_GOIP_SIMTYPE_WCDMA == ASYS_NvmGetIntEx(NVM_PORT_SIM_TYPE, uiChannelId)) && (pChnStHandle->bSupportUSIM))
						{
							A4CmdData[0] = 0;
							A4CmdData[3] = 0x04;
						}
						
						memcpy(stSimPoolWrite.buff, A4CmdData, sizeof(A4CmdData));
						stSimPoolWrite.size = sizeof(A4CmdData);
						stSimPoolWrite.channelid = uiChannelId;
#ifdef	SIMCOM_PRINT_DATA
						{
							_UCHAR8 PrintBuff[4096];
							_UINT32 uiPrintLen = 0;
							
							uiPrintLen = sprintf((PrintBuff + uiPrintLen), "Channel %d ###W(0x%02x) ", stSimPoolWrite.channelid, stSimPoolWrite.size);
							for(i = 0; i < stSimPoolWrite.size; i++)
							{
								uiPrintLen += sprintf((PrintBuff + uiPrintLen), "0x%02x ", stSimPoolWrite.buff[i]); 					
							}
							sprintf(PrintBuff+uiPrintLen,"\n");
						}				
#endif						
						//weikk 20160428
						SimComWriteData(stSimPoolWrite.channelid, stSimPoolWrite.buff, stSimPoolWrite.size);

						pChnStHandle->SimPoolStatus = SIMPOOL_ST_PREFIX_WAIT_INS;	
						pChnStHandle->uiPrefixSelectIdx = 0;
						pChnStHandle->expRspLen = 1;

						SIMCOM_INFO("Channel %d Recv Prefix:%d\n", uiChannelId, ntohs(pWrlEsccCmd->PrefixNum));	
					}
					else
					{
						memcpy(stSimPoolWrite.buff, pWrlEsccCmd->cmdData, pWrlEsccCmd->cmdLen);
						stSimPoolWrite.size = pWrlEsccCmd->cmdLen;
						stSimPoolWrite.channelid = uiChannelId;
						
						pChnStHandle->CmdIdx = ntohs(pWrlEsccCmd->cmdIndex);

						pChnStHandle->uiTotalRcvCnt +=	pWrlEsccCmd->cmdLen;

#ifdef	SIMCOM_PRINT_DATA
						{
							_UCHAR8 PrintBuff[4096];
							_UINT32 uiPrintLen = 0;
							
							uiPrintLen = sprintf((PrintBuff + uiPrintLen), "Channel %d ###W(0x%02x) ", stSimPoolWrite.channelid, stSimPoolWrite.size);
							for(i = 0; i < stSimPoolWrite.size; i++)
							{
								uiPrintLen += sprintf((PrintBuff + uiPrintLen), "0x%02x ", stSimPoolWrite.buff[i]); 					
							}
							sprintf(PrintBuff+uiPrintLen,"\n");
						}				
#endif						
						//SIMCOM_INFO("Channel %d Recv Cmdidx %d, cmdLen:%d, expRspLen = %d\n", evt->channel, pChnStHandle->CmdIdx, pWrlEsccCmd->cmdLen, ntohs(pWrlEsccCmd->expRspLen));
						//weikk 20160428
						SimComWriteData(stSimPoolWrite.channelid, stSimPoolWrite.buff, stSimPoolWrite.size);

						if(pWrlEsccCmd->paramLen > 0)
						{
							pChnStHandle->SimPoolStatus = SIMPOOL_ST_WAIT_INS;				
						}
						else
						{
							pChnStHandle->SimPoolStatus = SIMPOOL_ST_WAIT_RSP;
							pChnStHandle->WaitRspTick = tickGet();
							pChnStHandle->LastReadTick = tickGet(); 							
						}
					}
					pChnStHandle->bHasBakCmd = EOS_FALSE;
				}
				else
				{
					pChnStHandle->SimPoolStatus = SIMPOOL_ST_IDLE;		
				}
			}
		}
		else
		{
			
			_UINT32 uiCnt = 0;

			for(uiCnt = 0; uiCnt < stSimPoolRead.size; uiCnt++)
			{
				SIMCOM_INFO("Channel %d PPS Rsp buff[%d]:0x%x\n", uiChannelId, uiCnt, stSimPoolRead.buff[uiCnt]);
			}
			pChnStHandle->bHighBaudrate = EOS_FALSE;
			SIMCOM_INFO("Channel %d Get PPS Failed\n", uiChannelId);							

			simcomRstSim(uiChannelId);
		}
	}
	else
	{
		SIMCOM_INFO("Channel %d Get PPS Size 0\n", uiChannelId);	

		simcomRstSim(uiChannelId);
	}
	
	return EOS_OK;
}
	
static _UINT32 simcomSetRstTimerCB(_UINT32 uiChannelId, _UINT32 uiRsvd1)
{
    PSIMCOMROOTST         pSimComRootSt;
    PSIMCOMCHNST          pChnStHandle = NULL;

    pSimComRootSt = (PSIMCOMROOTST)&stSimComRootSt;
	pChnStHandle = &pSimComRootSt->pSimComChnSt[uiChannelId];

	if(pChnStHandle->SetRstTimerId > 0)
	{
        CommonTimerStop((_UINT32)pChnStHandle->SetRstTimerId);
	}
    if(pChnStHandle->bSimExisted == EOS_FALSE)
    {
        SIMCOM_INFO("Channel %d sim unexist,reset faild\n", uiChannelId);
        return EOS_OK;
    }
	pChnStHandle->bGetRstRspStatus = EOS_TRUE;
	//weikk add_file
	SimComCardReset(pSimComRootSt->fdSerialHdl);
	SIMCOM_INFO("Channel %d Set SimRst in TimerCB\n", uiChannelId);				

	if(pChnStHandle->GetRstRspTimerId > 0)
	{
        CommonTimerStart((_UINT32)pChnStHandle->GetRstRspTimerId, 100, 0);
	}

	return EOS_OK;
}

static _UINT32 SimComSetSimTypeTimerCB(_UINT32 uiChannelId, _UINT32 tmp)
{
    PSIMCOMROOTST         pSimComRootSt;
    PSIMCOMCHNST          pChnStHandle = NULL;

    pSimComRootSt = (PSIMCOMROOTST)&stSimComRootSt;
	pChnStHandle = &pSimComRootSt->pSimComChnSt[uiChannelId];

	if(pChnStHandle->SetSimTypeTimerId > 0)
	{
        CommonTimerStop((_UINT32)pChnStHandle->SetSimTypeTimerId);
	}
    pChnStHandle->simCardType = EN_SIMTYPE_USIM;
    SIMCOM_INFO("Channel %d Set sim type timeout,set default %d.\n", uiChannelId, pChnStHandle->simCardType);
    
    if(pSimComRootSt->SIMDetectTimerId > 0)
        CommonTimerStart((_UINT32)pSimComRootSt->SIMDetectTimerId, 100, 0);

    return EOS_OK;
}

static _UINT32 simcomDetectPollTimerCB(_UINT32 uiRsvd0, _UINT32 uiRsvd1)
{
    PSIMCOMROOTST         pSimComRootSt;
    PSIMCOMCHNST          pChnStHandle = NULL;
	_UINT32 i = 0;
	
    pSimComRootSt = (PSIMCOMROOTST)&stSimComRootSt;

    if(pSimComRootSt->cardStatus == 0) //init card detect io
    {
        pSimComRootSt->CardDetect1 = 0;
        pSimComRootSt->CardDetect2 = 0;
        pSimComRootSt->CardDetect3 = 0;
	    if(pSimComRootSt->SIMDetectTimerId > 0)
		{
            CommonTimerStart((_UINT32)pSimComRootSt->SIMDetectTimerId, 100, 1);
		}
	    pSimComRootSt->cardStatus = 1;
    }
    else if(pSimComRootSt->cardStatus == 1)    //first detect
    {
        #if SIMDATA_IO_UART
        if(SimComCardDetect(&(pSimComRootSt->CardDetect2)) == -1)
        {
            SIMCOM_INFO("SimPool sim detect error.1\n");
            return EOS_ERROR;
        }
        #else
	    pSimComRootSt->CardDetect2 = 1;
	    #endif
        for(i = 0; i < SIMPOOL_MAX_CHANNEL; i++)
		{
			if ((pSimComRootSt->CardDetect1) != (pSimComRootSt->CardDetect2))
			{
                pSimComRootSt->cardStatus = 2;
			}
            if(pSimComRootSt->SIMDetectTimerId > 0)
    		{
                CommonTimerStart((_UINT32)pSimComRootSt->SIMDetectTimerId, 1000, 1);
    		}
		}
    }
    else if(pSimComRootSt->cardStatus == 2)    //second detect,card status change
    {
        #if SIMDATA_IO_UART
        if(SimComCardDetect(&(pSimComRootSt->CardDetect3)) == -1)
        {
            SIMCOM_INFO("SimPool sim detect error.2\n");
            return EOS_ERROR;
        }
        #else
    	pSimComRootSt->CardDetect3 = 1;
        #endif

    	SIMCOM_INFO("sim card is in:pSimComRootSt->CardDetect n = (%d)(%d)(%d) \n",pSimComRootSt->CardDetect1,pSimComRootSt->CardDetect2,pSimComRootSt->CardDetect3);
    	for(i = 0; i < SIMPOOL_MAX_CHANNEL; i++)
    	{
     		if ((pSimComRootSt->CardDetect1 != pSimComRootSt->CardDetect2) 
                && (pSimComRootSt->CardDetect2 == pSimComRootSt->CardDetect3))
			{
				_UINT32 uiIndex = i;

				pChnStHandle = &pSimComRootSt->pSimComChnSt[uiIndex];

				if(0 == pSimComRootSt->CardDetect3)
				{
					SIMCOM_INFO("Channel %d Remove\n", uiIndex);
					pChnStHandle->bSimOk = EOS_FALSE;
					pChnStHandle->uiTotalSendCnt = 0;
					pChnStHandle->uiTotalRcvCnt = 0;
					pChnStHandle->SimPoolStatus = SIMPOOL_ST_RST;					
					pChnStHandle->bHasBakCmd = EOS_FALSE;
					pChnStHandle->CmdIdx = 0;
					pChnStHandle->bSimExisted = EOS_FALSE;
					pChnStHandle->uiPreReadCnt = 0;
				}
				else
				{
					if(pChnStHandle->bSimExisted == EOS_FALSE)
					{
						SIMCOM_INFO("Channel %d Insert\n", uiIndex);
						pChnStHandle->bSimExisted = EOS_TRUE;
						pChnStHandle->bNeedPreRead = EOS_TRUE;
						pChnStHandle->bNormalRead = EOS_FALSE;
						pChnStHandle->bGetRstRspStatus = EOS_TRUE;
						//simcomSetFPGAEtu(uiIndex, 0);
						//simcomSetRspSignal(uiIndex, 1); 		

						if(pChnStHandle->GetRstRspTimerId > 0)
						{
                            CommonTimerStop((_UINT32)pChnStHandle->GetRstRspTimerId);
                            CommonTimerStart((_UINT32)pChnStHandle->GetRstRspTimerId, SIMPOOL_GETPPS_TIME, 0);
						}
				
						pChnStHandle->bSimOk = EOS_FALSE;
						pChnStHandle->uiTotalSendCnt = 0;
						pChnStHandle->uiTotalRcvCnt = 0;
						
						pChnStHandle->SimPoolStatus = SIMPOOL_ST_RST;					
						pChnStHandle->bHasBakCmd = EOS_FALSE;
						pChnStHandle->CmdIdx = 0;
						
						pChnStHandle->uiPreReadCnt = 0;
						//weikk 20160428
						SimComCardReset(pSimComRootSt->fdSerialHdl);
						SIMCOM_INFO("Channel %d Set SimRst in SimDetect\n", uiIndex);		
					}
				}    				
				pSimComRootSt->CardDetect1 = pSimComRootSt->CardDetect2;
                pSimComRootSt->cardStatus = 1;
			}
    	}
    }

	return EOS_OK;
}

#if 0
static _INT32 simcomAppCMDProcess(_VOID)
{
    PSIMCOMROOTST         pSimComRootSt;
    PSIMCOMCHNST          pChnStHandle = NULL;
    _UINT32              uiChnIndex = 0;
    //PSIMCOMLISTNODE    pn = NULL;
    
    pSimComRootSt = (PSIMCOMROOTST)&stSimComRootSt;

    for(uiChnIndex = 0; uiChnIndex < pSimComRootSt->uiMaxChannelNum; uiChnIndex++)
    {
		pChnStHandle = &pSimComRootSt->pSimComChnSt[uiChnIndex];
                
        switch(pn->op_type)
        {
            case SIMCOM_NVM_PARAM_MODIFY:
            {
                SIMCOM_INFO("channel %d SIMCOM_NVM_PARAM_MODIFY, NvmIndex:%d\n", pn->channelid, pn->Value);
				switch(pn->Value)
				{
					case NVM_PORT_SIM_TYPE:
					{
						if(pChnStHandle->bSimExisted)
						{
							ioctl_simpool_reset_st	stSimCtrl;
							ESCC_SessNtfySimOut(pChnStHandle->pEsccSessId);
							
							stSimCtrl.channelid = uiChnIndex;
							stSimCtrl.simrst = 0;

							SIMCOM_INFO("Channel %d Change SimType to:%d\n", uiChnIndex, ASYS_NvmGetIntEx(NVM_PORT_SIM_TYPE, uiChnIndex));

							if(0)//(NVM_GOIP_SIMTYPE_WCDMA == ASYS_NvmGetIntEx(NVM_PORT_SIM_TYPE, uiChnIndex))
							{
								pChnStHandle->bSupportUSIM = EOS_TRUE;
							}
							else
							{
								pChnStHandle->bSupportUSIM = EOS_FALSE;
							}

							//weikk 20160428
						    SimComCardReset(pSimComRootSt->fdSerialHdl);
							SIMCOM_INFO("Channel %d Set SimRst %d in SimDetect\n", stSimCtrl.channelid, stSimCtrl.simrst);

							pChnStHandle->bNeedPreRead = EOS_TRUE;
							pChnStHandle->bNormalRead = EOS_FALSE;
							pChnStHandle->bGetRstRspStatus = EOS_TRUE;
							simcomSetFPGAEtu(uiChnIndex, 0);
							simcomSetRspSignal(uiChnIndex, 1); 		
						
							if(pChnStHandle->GetRstRspTimerID > 0)
							{
								ut_timer_stop(pSimComRootSt->SimComTimerID, (_UINT32)pChnStHandle->GetRstRspTimerID);
								pChnStHandle->GetRstRspTimerID = 0;
							}
							ut_timer_start(pSimComRootSt->SimComTimerID, SIMPOOL_GETPPS_TIME, EN_TIMER_ONESHOT,
								(TIMERFUNC)simcomGetRstRspTimerCB, uiChnIndex, EOS_TRUE, (_UINT32 *)&(pChnStHandle->GetRstRspTimerID));
						
							stSimCtrl.simrst = 1;
							//weikk 20160228
						    SimComCardReset(pSimComRootSt->fdSerialHdl);
							SIMCOM_INFO("Channel %d Set SimRst %d in SimDetect\n", stSimCtrl.channelid, stSimCtrl.simrst);
						
							pChnStHandle->bSimOk = EOS_FALSE;
							pChnStHandle->uiTotalSendCnt = 0;
							pChnStHandle->uiTotalRcvCnt = 0;
						
							pChnStHandle->SimPoolStatus = SIMPOOL_ST_RST;					
							pChnStHandle->bHasBakCmd = EOS_FALSE;
							pChnStHandle->CmdIdx = 0;
						
							pChnStHandle->uiPreReadCnt = 0;
						}
						break;
					}
					default:
					{
						SIMCOM_INFO("channel %d (%d)Not CallBack Operation\n", pn->channelid, pn->Value);				
						break;
					}
				}
                break;
            }
            default:
            {
                SIMCOM_ERROR(SIMCOM_ERRORNO, "SIMCOM param is out of range!\n");
                SIMCOM_INFO("channel %d op type = %d.\n", pn->channelid, pn->op_type);                
                break;
            }        
        }
        SIMCOM_FREE(pn);
    }

    return EOS_OK;
}
#endif


_VOID SimCom_Task(_VOID)
{
    PSIMCOMROOTST         pSimComRootSt;
	    
    pSimComRootSt = (PSIMCOMROOTST)&stSimComRootSt;

	while(1)
	{		
        #if (__SIMCOM_OS_TYPE__ == __SIMCOM_OS_IOS__)
        CommonTimerMainHdl();
        #endif
		SimComReadData();
		usleep(10000);
        
#if 0
        static _INT32 cntTime = 0;

        if(cntTime++ > 200) //2s
        {
            cntTime = 0;
            
            _UCHAR8 testData[64]={0x00,0x01,0x05,0x00,0x00,0x19,0x00,0x02,0x00,0x00,0x7f,0x20,0x00,0x00,0x00,0x00,0xa0,0xc0,0x00,0x00,0x16};
            ST_SIMCOM_APPEVT appEvtSendBuff;

            appEvtSendBuff.chn = 0;
            appEvtSendBuff.evtIndex = EN_APPEVT_SIMDATA;
            appEvtSendBuff.len = 22;
            appEvtSendBuff.pData = testData;
            SimComEvtApp2Drv(&appEvtSendBuff);
        }
#endif
#if 0
            static _INT32 cntTime = 0;
            static _INT32 bSetSimType = 0;

            if(bSetSimType == 0)
            {
                if(cntTime++ > 100) //1s
                {
                    cntTime = 0;
                    
                    _UCHAR8 testData[1]={2};
                    ST_SIMCOM_APPEVT appEvtSendBuff;
        
                    appEvtSendBuff.chn = 0;
                    appEvtSendBuff.evtIndex = EN_APPEVT_SETSIMTYPE;
                    appEvtSendBuff.len = 1;
                    appEvtSendBuff.pData = testData;
                    SimComEvtApp2Drv(&appEvtSendBuff);
                    bSetSimType = 1;
                }
            }
#endif

	}
}


