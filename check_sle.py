import os
import sys
import time
import datetime
import shutil

Sle_Name=sys.argv[1]

HOME='/data/dw_oncall/Sle_Batch'
Check_Folder=HOME+'/'+Sle_Name
Cfg_Folder=HOME+'/Cfgs'
Log_Folder=HOME+'/Logs'
Email_Folder=HOME+'/Email_List'
history_file=Check_Folder+'/Completed_History.txt'

today=time.strftime('%Y%m%d')
yesterday=(datetime.datetime.now()+datetime.timedelta(days=-1)).strftime('%Y%m%d')
tomorrow=(datetime.datetime.now()+datetime.timedelta(days=+1)).strftime('%Y%m%d')

date_dict={
    'T':today,
    'M':tomorrow,
    'Y':yesterday
}


cfg_file=Cfg_Folder+'/'+Sle_Name+'.cfg'
email_list_file=Email_Folder+'/'+Sle_Name+'.emaillist'
email_subject_file=Email_Folder+'/'+Sle_Name+'.subject'
cfg_tmp_file=Log_Folder+'/'+Sle_Name+'.cfg'+'.'+today
log_tmp_file=Log_Folder+'/'+Sle_Name+'.'+today+'.tmp'
log_file=Log_Folder+'/'+Sle_Name+'.'+today+'.tmplog'

count=len(open(cfg_file,'r').readlines())
watch='/dw/etl/home/prod/watch'
shutil.copyfile(cfg_file,cfg_tmp_file)



if os.path.exists(log_file):
   os.remove(log_file)


def get_th_file_name():




def checkThFile():
    with open(cfg_tmp_file,'r') as f:
        with open(log_tmp_file,'w') as w:
            for rows in f.readlines():
                (num,th_file,env,uow_value) = rows.split()
                logwrite=open(log_file,'a+')

                TH_file = '/'.join(watch,env,date_dict[uow_value],th_file)
                TH_file += '.'+date_dict[uow_value]+'000000'
                th_file += '.'+date_dict[uow_value]+'000000'

                if os.path.exists(TH_file):
                    fileinfo=os.stat(TH_file)
                    create_date=time.strftime("%Y-%m-%d %H:%M:%S",time.localtime(fileinfo.st_ctime))
                    logwrite.write(' '.join(num,th_file))
                    logwrite.write(num+' '+th_file+' '+create_date+'\n')
                else:
                    w.write(rows)
                logwrite.close()
    shutil.move(log_tmp_file,cfg_tmp_file)

def getMaxDate():
    timedate=[]
    with open (log_file,'r') as log:
        for rows in log.readlines():
            timedate.append(rows.split()[2]+' '+rows.split()[3])

    timedate.sort()
    return timedate[-1]

if __name__ == '__main__':
    while True:
        checkThFile()
        num=len(open(log_file,'r').readlines())
        
        if(count==num):
            if(time.strftime('%Y%m%d') <= today):
                cmd_lt = ['python /data/dw_oncall/Python/SendMailHtml.py',log_file,getMaxDate(),email_list_file,email_subject_file,today]
                cmd = ' '.join(cmd_lt)
                os.system(cmd)
                with open(history_file,'a+') as w:
                    w.write(getMaxDate()[:-3])
            else:
                sys.exit(1)
        else:
            time.sleep(300)