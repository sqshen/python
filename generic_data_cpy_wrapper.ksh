. /dw/etl/mstr_cfg/etlenv.setup

this=`basename $0`
scriptName=${this%".ksh"}
LOGDT=`date '+20%y%m%d'`
dt=`date '+%Y%m%d%H%M%S'`

export START_DATE=$1
export END_DATE=$2
export SUB_APPL=$3
export SRC_TBL=$4

export SUBJECT_AREA=$SUBJECT_AREA
export TABLE_ID=$TABLE_ID
export JOB_ENV=$JOB_ENV

echo SUBJECT_AREA : $SUBJECT_AREA
echo TABLE_ID : $TABLE_ID
echo SRC_TBL  : $SRC_TBL

export CONFIG_FILE=$DW_CFG/${SUBJECT_AREA}.${SUB_APPL}.data_cpy.cfg
export EMAIL_ID=`cat $DW_DAT/$JOB_ENV/${SUBJECT_AREA}/${SUBJECT_AREA}.${SUB_APPL}.generic_data_copy_mailid.dat`
export DELETE_DONE_FILE=$DW_DAT/$JOB_ENV/${SUBJECT_AREA}/${SUBJECT_AREA}.${SUB_APPL}.generic_data_copy_remove_done.dat


#####Input Parm Validation####################

if [ -z $SRC_TBL ]
then
  if [[ $# -ne 3 ]];then
        echo 'Usage:$0 <START_DATE> <END_DATE> <SUB_APPL>' 
        exit 1
  fi
else
   if [[ $# -ne 4 ]];then
        echo 'Usage:$0 <START_DATE> <END_DATE> <SUB_APPL> <SRC_TBL>'
        exit 1
   fi
fi

rc1=`echo $START_DATE|grep '^[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$' >/dev/null;echo $?`
rc2=`echo $END_DATE|grep '^[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$' >/dev/null;echo $?`

if [[ $rc1 -ne 0 ]] || [[ $rc2 -ne 0 ]]
then
echo "Invalid format : <START_DATE> or <END_DATE>"
exit 1
fi

if [ $START_DATE -gt $END_DATE ]
then
echo "<START_DATE> parm value is greater than <END_DATE>"
exit 1
fi

#######Required config file(s) validation######

if [ ! -f $CONFIG_FILE ]
then
echo "Config file does not exist : $CONFIG_FILE"
exit 1
fi

if [ ! -f $DW_DAT/$JOB_ENV/${SUBJECT_AREA}/${SUBJECT_AREA}.${SUB_APPL}.generic_data_copy_mailid.dat ]
then
echo "MailId file does not exist"
exit 1
fi

###############Evaluating table details###############

if [ -z $SRC_TBL ]
then
export TBL_CFG=`cat $CONFIG_FILE`
MAIL_LOG_FILE=$DW_LOG/$JOB_ENV/${SUBJECT_AREA}/$TABLE_ID/${SUBJECT_AREA}.${SUB_APPL}.generic_data_copy_${TABLE_ID}.maillog
cat /dev/null > $MAIL_LOG_FILE
echo "<TABLE border=2 cellspacing=1 cellpadding=3>" >> $MAIL_LOG_FILE
echo "<TR><TD><B>TABLE_NAME</B></TD><TD><B>STATUS</B></TD><TD><B>INSERTED</B></TD><TD><B>UPDATED</B></TD><TD><B>REJECTED</B></TD><TD><B>REPROCESS_INSERTED</B></TD><TD><B>REPROCESS_UPDATED</B></TD><TD><B>REPROCESS_REJECTED</B></TD><TD><B>START DATE</B></TD><TD><B>END DATE</B></TD></TR>" >>  $MAIL_LOG_FILE
flg=0
else
export TBL_CFG=`grep -i -w $SRC_TBL $CONFIG_FILE`
MAIL_LOG_FILE=$DW_LOG/$JOB_ENV/$SUBJECT_AREA/$TABLE_ID/${SUBJECT_AREA}.${SUB_APPL}.generic_data_copy_${SRC_TBL}.maillog
cat /dev/null > $MAIL_LOG_FILE
echo "<TABLE border=2 cellspacing=1 cellpadding=3>" >> $MAIL_LOG_FILE
echo "<TR><TD><B>TABLE_NAME</B></TD><TD><B>STATUS</B></TD><TD><B>INSERTED</B></TD><TD><B>UPDATED</B></TD><TD><B>REJECTED</B></TD><TD><B>REPROCESS_INSERTED</B></TD><TD><B>REPROCESS_UPDATED</B></TD><TD><B>REPROCESS_REJECTED</B></TD><TD><B>START DATE</B></TD><TD><B>END DATE</B></TD></TR>" >>  $MAIL_LOG_FILE
cnt=`grep -i -w -n $SRC_TBL $CONFIG_FILE|awk -F":" '{print $1}'`
flg=1
  if [ -z $TBL_CFG ]
   then
    echo "<TR><TD><CODE>$SRC_TBL</CODE></TD><TD><CODE>NOT IN CONFIG - FAILED</CODE></TD><TD><CODE>0</CODE></TD><TD><CODE>0</CODE></TD><TD><CODE>0</CODE></TD><TD><CODE>0</CODE></TD><TD><CODE>0</CODE></TD><TD><CODE>0</CODE></TD><TD><B>$START_DATE</B></TD><TD><B>$END_DATE</B></TD></TR>" >> $MAIL_LOG_FILE
  fi
fi

#LOOP Determination

if [ $flg -eq 0 ]
then
  tot_rec=`wc -l $CONFIG_FILE|awk '{print $1}'`
 a=0
  while [ $a -lt $tot_rec ]
   do
    a=`expr $a + 1`
    r=`echo $r $a`
   done
  loop_cond=`echo $r`
 else
 loop_cond=`echo $cnt`
fi
################

##########Executing graph for table Extract & Load###########

for i in `echo $loop_cond`
do
line=`sed -n "${i}p" $CONFIG_FILE`
echo "Table value" : $line
SRC_TBL=`echo $line|awk -F"," '{print $1"."$2}'| tr '[:upper:]' '[:lower:]'`
TRGT_TBL=`echo $line|awk -F"," '{print $4"."$5}'|tr '[:upper:]' '[:lower:]'`
TRGT_TBL_UPPER=`echo $line|awk -F"," '{print $4"."$5}'|tr '[:lower:]' '[:upper:]'`
TRGT_TBL_UP=`echo $line|awk -F"," '{print $5}'`
TRGT_DBC=`echo $line|awk -F"," '{print $6}'|tr '[:upper:]' '[:lower:]'`
TRGT_DBC_UPPER=`echo $line|awk -F"," '{print $6}'`
DONE_FILE=`echo $SRC_TBL.$TRGT_TBL.$TRGT_DBC.$START_DATE.$END_DATE.$LOGDT.DONE |tr '[:upper:]' '[:lower:]'`

echo "Done File Name" : $DONE_FILE
cnt=$(($i - 1))
LOOP=$cnt
echo "LOOP :" $LOOP

  if [ ! -e $DW_LOG/$JOB_ENV/$SUBJECT_AREA/$TABLE_ID/$DONE_FILE ]
   then
    ksh $DW_EXE/dw_cs_orp.generic_data_copy.ksh -LOOP_NUM $LOOP -START_DATE $START_DATE -END_DATE $END_DATE -SRC_TBL_NM $SRC_TBL -JOB_ENV $JOB_ENV -SA $SUBJECT_AREA -TABLE_ID $TABLE_ID -SUB_APPL $SUB_APPL

    rc=$?
      if [ $rc -eq 0 ];then
        ins=`grep -i "inserts" $DW_LOG/$JOB_ENV/$SUBJECT_AREA/$TABLE_ID/generic_data_copy_${TRGT_DBC_UPPER}_${TRGT_TBL_UP}.cnt |awk -F":" '{print $2}'`
        upd=`grep -i "updates" $DW_LOG/$JOB_ENV/$SUBJECT_AREA/$TABLE_ID/generic_data_copy_${TRGT_DBC_UPPER}_${TRGT_TBL_UP}.cnt |awk -F":" '{print $2}'`
        del=`grep -i "rejects" $DW_LOG/$JOB_ENV/$SUBJECT_AREA/$TABLE_ID/generic_data_copy_${TRGT_DBC_UPPER}_${TRGT_TBL_UP}.cnt |awk -F":" '{print $2}'`
        rej_ins=`sed  's/[[:cntrl:]]//g' $DW_LOG/$JOB_ENV/$SUBJECT_AREA/$TABLE_ID/generic_data_copy_${TRGT_DBC_UPPER}_${TRGT_TBL_UP}_reject_process.cnt|grep -i "inserts" |awk -F":" '{print $2}'`
        rej_upd=`sed  's/[[:cntrl:]]//g' $DW_LOG/$JOB_ENV/$SUBJECT_AREA/$TABLE_ID/generic_data_copy_${TRGT_DBC_UPPER}_${TRGT_TBL_UP}_reject_process.cnt|grep -i "updates" |awk -F":" '{print $2}'`
        rej_del=`sed  's/[[:cntrl:]]//g' $DW_LOG/$JOB_ENV/$SUBJECT_AREA/$TABLE_ID/generic_data_copy_${TRGT_DBC_UPPER}_${TRGT_TBL_UP}_reject_process.cnt|grep -i "rejects" |awk -F":" '{print $2}'`

        if [ -z $ins ];then
         ins=0
        fi
         if [ -z $upd ];then
           upd=0
         fi
          if [ -z $del ];then
           del=0
          fi

        if [ -z $rej_ins ];then
         rej_ins=0
        fi
         if [ -z $rej_upd ];then
           rej_upd=0
         fi
          if [ -z $rej_del ];then
           rej_del=0
          fi

       echo "<TR><TD><font color="green"><CODE>$TRGT_TBL_UPPER</CODE></font></TD><TD><font color="green"><CODE>LOAD COMPLETED</CODE></font></TD><TD><CODE>$ins</CODE></TD><TD><CODE>$upd</CODE></TD><TD><CODE>$del</CODE></TD><TD><CODE>$rej_ins</CODE></TD><TD><CODE>$rej_upd</CODE></TD><TD><CODE>$rej_del</CODE></TD><TD><CODE>$START_DATE</CODE></TD><TD><CODE>$END_DATE</CODE></TD></TR>" >> $MAIL_LOG_FILE
       rm -f $DW_LOG/$JOB_ENV/$SUBJECT_AREA/$TABLE_ID/generic_data_copy_${TRGT_DBC_UPPER}_${TRGT_TBL_UP}.cnt  $DW_LOG/$JOB_ENV/$SUBJECT_AREA/$TABLE_ID/generic_data_copy_${TRGT_DBC_UPPER}_${TRGT_TBL_UP}_reject_process.cnt

      else
        ins=`grep -i "inserts" $DW_LOG/$JOB_ENV/$SUBJECT_AREA/$TABLE_ID/generic_data_copy_${TRGT_DBC_UPPER}_${TRGT_TBL_UP}.cnt |awk -F":" '{print $2}'`
        upd=`grep -i "updates" $DW_LOG/$JOB_ENV/$SUBJECT_AREA/$TABLE_ID/generic_data_copy_${TRGT_DBC_UPPER}_${TRGT_TBL_UP}.cnt |awk -F":" '{print $2}'`
        del=`grep -i "rejects" $DW_LOG/$JOB_ENV/$SUBJECT_AREA/$TABLE_ID/generic_data_copy_${TRGT_DBC_UPPER}_${TRGT_TBL_UP}.cnt |awk -F":" '{print $2}'`
        rej_ins=`sed  's/[[:cntrl:]]//g' $DW_LOG/$JOB_ENV/$SUBJECT_AREA/$TABLE_ID/generic_data_copy_${TRGT_DBC_UPPER}_${TRGT_TBL_UP}_reject_process.cnt|grep -i "inserts" |awk -F":" '{print $2}'`
        rej_upd=`sed  's/[[:cntrl:]]//g' $DW_LOG/$JOB_ENV/$SUBJECT_AREA/$TABLE_ID/generic_data_copy_${TRGT_DBC_UPPER}_${TRGT_TBL_UP}_reject_process.cnt|grep -i "updates" |awk -F":" '{print $2}'`
        rej_del=`sed  's/[[:cntrl:]]//g' $DW_LOG/$JOB_ENV/$SUBJECT_AREA/$TABLE_ID/generic_data_copy_${TRGT_DBC_UPPER}_${TRGT_TBL_UP}_reject_process.cnt|grep -i "rejects" |awk -F":" '{print $2}'`

        if [ -z $ins ];then
         ins=0
        fi
         if [ -z $upd ];then
           upd=0
         fi
          if [ -z $del ];then
           del=0
          fi
        
        if [ -z $rej_ins ];then
         rej_ins=0
        fi
         if [ -z $rej_upd ];then
           rej_upd=0
         fi
          if [ -z $rej_del ];then
           rej_del=0
          fi

      echo "<TR><TD><font color="red"><CODE>$TRGT_TBL_UPPER</CODE></font></TD><TD><font color="red"><CODE>LOAD FAILED</CODE></font></TD><TD><CODE>$ins</CODE></TD><TD><CODE>$upd</CODE></TD><TD><CODE>$del</CODE></TD><TD><CODE>$rej_ins</CODE></TD><TD><CODE>$rej_upd</CODE></TD><TD><CODE>$rej_del</CODE></TD><TD><CODE>$START_DATE</CODE></TD><TD><CODE>$END_DATE</CODE></TD></TR>" >> $MAIL_LOG_FILE
      rm -f $DW_LOG/$JOB_ENV/$SUBJECT_AREA/$TABLE_ID/generic_data_copy_${TRGT_DBC_UPPER}_${TRGT_TBL_UP}.cnt $DW_LOG/$JOB_ENV/$SUBJECT_AREA/$TABLE_ID/generic_data_copy_${TRGT_DBC_UPPER}_${TRGT_TBL_UP}_reject_process.cnt
   fi
else
     echo "----------Skipping $TRGT_TBL Load as it is already completed-------------"
      echo "<TR><TD><font color="blue"><CODE> $TRGT_TBL_UPPER</CODE></font></TD><TD><font color="blue"><CODE>LOAD SKIPPED - ALREADY COMPLETED </CODE></font></TD><TD><CODE>0</CODE></TD><TD><CODE>0</CODE></TD><TD><CODE>0</CODE></TD><TD><CODE>0</CODE></TD><TD><CODE>0</CODE></TD><TD><CODE>0</CODE></TD><TD><CODE>$START_DATE</CODE></TD><TD><CODE>$END_DATE</CODE></TD></TR>" >> $MAIL_LOG_FILE
      rm -f $DW_LOG/$JOB_ENV/$SUBJECT_AREA/$TABLE_ID/generic_data_copy_${TRGT_DBC_UPPER}_${TRGT_TBL_UP}.cnt $DW_LOG/$JOB_ENV/$SUBJECT_AREA/$TABLE_ID/generic_data_copy_${TRGT_DBC_UPPER}_${TRGT_TBL_UP}_reject_process.cnt
  fi

done

echo "</TABLE>" >> $MAIL_LOG_FILE

####Send Mail#####
if [ -s $MAIL_LOG_FILE ]
then
cat - $MAIL_LOG_FILE <<EOF | /usr/sbin/sendmail -oi -t
From: generic_data_copy@ebay.com
To: $EMAIL_ID
Subject: Generic Extract Load - Table Loading Stats [ PROCESSING DATE : $LOGDT ]
Content-Type: text/html; charset=us-ascii
Content-Transfer-Encoding: 7bit
MIME-Version: 1.0
EOF
fi

#UC4 job return code determination

UC4_RC=`grep 'FAILED' $MAIL_LOG_FILE >/dev/null ;echo $?`
if [ $UC4_RC -eq 0 ]
then
exit 1
else
   
for i in `cat ${DELETE_DONE_FILE}`
 do 
  DONE_PATTERN=`echo $i|awk -F"," '{print "*"$1"."$2"."$3}'|tr [:upper:] [:lower:]`
  RUN_FREQ=`echo $i|awk -F"," '{print $4}'`

  echo  RUN_FREQ IN A DAY: $RUN_FREQ
  EXIST_DONE=`ls $DW_LOG/$JOB_ENV/$SUBJECT_AREA/$TABLE_ID/*.${DONE_PATTERN}.$START_DATE.$END_DATE.$LOGDT.done`

  run_cnt=`ls -ltr ${EXIST_DONE}.*.run  |tail -1|awk '{print $9}'|awk -F"." '{print $11}'`

   if [ -z $run_cnt ]
    then          
     run_cnt=1    
     else    
      run_cnt=$(($run_cnt + 1))
   fi

   echo SEQUENCE RUNNING :  ${run_cnt}
    DELETE_DONE=${EXIST_DONE}.${run_cnt}.run   
    if [ -e $EXIST_DONE ]    
     then  
       if [ ${run_cnt} -le ${RUN_FREQ} ]  
       then
         touch ${DELETE_DONE}
       fi 
    fi

    if [ ${run_cnt} -lt ${RUN_FREQ} ]    
     then      
      rm -f ${EXIST_DONE}    
     fi    
  done
fi

rm -f $MAIL_LOG_FILE
