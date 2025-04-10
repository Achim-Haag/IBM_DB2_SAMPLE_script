#!/bin/bash
#
# Testing script working on IBM DB2 sample database SAMPLE
# Database SAMPLE with initial contents is created by IBM program db2sampl
# This script removes, then inserts records into Tables  DEPT and EMPLOYEE
#
# Parameters:
# -h		only help, no further execution
# -d		only remove formerly inserted records, no new insert
#
# Hints:
# - If something goes wrong, the database SAMPLE could be dropped and recreated easily.
# - Inserted DEPT Records have DEPTNO beginning with X,Y,Z
# - Inserted EMPLOYEE Records have JOB beginning with "@" character
# 
# Developed under
# - RHEL 8.10
# - bash 4.4.20(1)-release
# - DB2 v11.5.9.0 (Community Edition)
# 
# 07.04.25/AH - Script created
# 08.04.25/AH - Calling options (getopts) instead of read while executing
# 10.05.25/AH - Versioning; error handling for DB2 CLI commands

###########################################
# Init
###########################################
clear
version="1.1 of 04.10.25,10:49"
db2systab="SYSIBM.SYSTABLES"	# DB2 system catalog table
dbname="SAMPLE"			# Database created by db2sampl program
dbtabdept="DEPT"		# DEPARTMENT table (DEPT is alias)
dbtabempl="EMP"			# EMPLOYEE table (EMP is alias)
#
reftime="$(date +"%T")"		# Use actual time as reference through whole script
refdate="$(date -Idate)"	# Use actual time as reference through whole script
#
insertdate="$refdate $reftime"	# Insert-Date (sortable), the same for all records
bonusdate="${refdate:5:2}${reftime:8:2}"	# Table EMPLOYEE, field COMM : insert reference date
commtime="${reftime:0:2}${reftime:3:2}"	# Table EMPLOYEE, field COMM : insert reference time
#
stepctr=0			# Just for display

###########################################
#  Process parameter
###########################################
let stepctr=stepctr+1
echo -e "\n### Step ${stepctr} - Process user parameter if specified"
#
NOINSERTFLAG=false
#
while getopts "hd" optchar; do
  case $optchar in
  h) echo "$(basename $0) Version $version"
     echo " "
     echo "Add records to IBM database SAMPLE (created by IBM program 'db2sampl')"
     echo "This script processes tables DEPT (DEPARTMENT) and EMP (EMPLOYEE)"
     echo "This script removes formerly added records, then inserts new records in these tables"
     echo "As of DB2 11.5, no records created by 'db2sampl' should be touched"
     echo " "
     echo "Parameters:"
     echo -e "  -h\t\tonly this help text, no processing"
     echo -e "  -d\t\tonly delete, no insert"
     echo " "
     echo "Developed under"
     echo "- RHEL 8.10"
     echo "- bash 4.4.20(1)-release"
     echo "- DB2 v11.5.9.0 (Community Edition)"
     echo " "
     exit 1
  ;;
  d) NOINSERTFLAG=true
  ;;
  *) echo "Parameter [$optchar] not implemented, please try -h"
     exit 8
  ;;
  esac
done
#
if [[ $NOINSERTFLAG = true ]] ; then		# driven by option
  echo "Only deletion, no insert as specified by user parameter"
else
  echo "Deletion of formerly added records, then insert again"
fi
sleep 3		# just to read above message
###########################################
#  Init DB Connection
###########################################
let stepctr=stepctr+1
echo -e "\n### Step ${stepctr} - Initialize DB connection at $refdate $reftime"
db2 "connect to $dbname"
dbcorc=$?
if [[ $dbcorc -ne 0 ]] ; then
  echo "Error $dbcorc from [db2 connect to $dbname]"
  exit 8
fi 

#################################################
#  Show used aliases and tabnames (just for fun) 
#################################################
echo "--- Databases we need (from $db2systab) ---"
db2  "SELECT SUBSTR(CREATOR,1,15) as Creator, SUBSTR(NAME,1,10) as Alias, SUBSTR(BASE_NAME,1,20) as Table FROM ${db2systab} \
	where TYPE='A' AND NAME IN ('${dbtabdept}', '${dbtabempl}')"
if [[ $dbclirc -ne 0 ]] ; then
  echo "Error $dbclirc from [db2 SELECT ... FROM ${db2systab}  where TYPE='A' AND NAME IN ('${dbtabdept}', '${dbtabempl}'"
  exit 8
fi 

#################################################
#  Remove previously inserted records if existing
#################################################
let stepctr=stepctr+1
echo -e "\n### Step ${stepctr} - Remove previously inserted records"
#
echo "--- Remove departments X, Y, Z from table $dbtabdept ---"
#
numrecs=$(db2 -x "select count(*) from ${dbtabdept} where DEPTNO like 'Z%'")
let numrecs=numrecs+0				# Left align
echo "delete from $dbtabdept where DEPTNO like 'Z%' ($numrecs recs)"
db2  "delete from $dbtabdept where DEPTNO like 'Z%'"
#
numrecs=$(db2 -x "select count(*) from ${dbtabdept} where DEPTNO like 'Y%'")
let numrecs=numrecs+0				# Left align
echo "delete from $dbtabdept where DEPTNO like 'Y%' ($numrecs recs)"
db2  "delete from $dbtabdept where DEPTNO like 'Y%'"
#
numrecs=$(db2 -x "select count(*) from ${dbtabdept} where DEPTNO like 'X%'")
let numrecs=numrecs+0				# Left align
echo "delete from $dbtabdept where DEPTNO like 'X%' ($numrecs recs)"
db2  "delete from $dbtabdept where DEPTNO like 'X%'"
#
echo "--- Remove employes with job "@..." from table $dbtabempl ---"
numrecs=$(db2 -x "select count(*) from ${dbtabempl} where JOB like '@%'")
let numrecs=numrecs+0				# Left align
echo "delete from $dbtabempl where JOB like '@%' ($numrecs recs)"
db2  "delete from $dbtabempl where JOB like '@%'"
#
echo "--- Commiting deletions ---"
db2 "commit work"
dbclirc=$?
if [[ $dbclirc -ne 0 ]] ; then
  echo "Error $dbclirc from [db2 commit work]"
  db2 "rollback"
  exit 8
fi 

### read -p "Continue with inserts into tab $dbtabdept [y/n] ? " answer
### if [[ $answer = "n" || $answer = "N" ]] ; then
###  echo "So I stop after step ${stepctr}..."
if [[ $NOINSERTFLAG = true ]] ; then		# driven by option
  echo "--- Stop by user option after step ${stepctr}, no inserts ---"
  db2 terminate
  exit 0
fi
###########################################
#  Insert departments X, Y, Z, 01...99 
###########################################
let stepctr=stepctr+1
echo -e "\n### Step ${stepctr} - Insert departments X, Y, Z in table $dbtabdept"
#
# Departments inserted with double digit counter appended
# Leading zeroes created by printf
# Backlinked department Z... -> Y..., Y... -> X..., X... -> A0 because of DB2 constraint on field ADMRDEPT
#
#
# Insert-Loop records X00...X99, Y00...Y99, Z00...Z99
#
deptctr=0				# Counter of all inserted department records
upperdept="A"				# backlink for X... is A00
for deptprefix in "X" "Y" "Z" ; do
  echo "--- Inserting departments $deptprefix ---"
  let deptnr=-1
###  while [[ $deptnr -lt 2 ]] ; do		# insert records from 00...02 for debugging purposes
  while [[ $deptnr -lt 99 ]] ; do		# insert records from 00...99
    let deptnr=deptnr+1
    let lvl1ctr=lvl1ctr+1
    deptnrlz="${deptprefix}$(printf '%02d\n' "$deptnr")"
# About 20% of new departments get a manager (EMPNO from EMPLOYEE table)
# Hint on arithm.expr.: ((...)) returns true/false, $((...)) returns value of operation
    randmanager="default"
    if (($RANDOM % 20 == 0)) ; then
      randmanager="'$(db2 -x "select empno from $dbtabempl order by rand() limit 1")'"
      dbclirc=$?
      if [[ $dbclirc -ne 0 ]] ; then
        echo "Error $dbclirc from [db2 select empno from $dbtabempl order by rand() limit 1]"	# only show error, no exit
        randmanager="default"
      fi 
    fi
#
    let deptctr=deptctr+1
    deptctrlz="$(printf '%03d\n' "$deptctr")"
    if [[ $randmanager != "default" ]] ; then	# print all departments with non-default manager (just to have a little output)
      echo "Insert Record ${deptctrlz} [$deptnrlz] with upper [${upperdept}00] and manager [$randmanager]"
    fi
#
    db2 "insert into $dbtabdept (DEPTNO, DEPTNAME, ADMRDEPT, MGRNO) \
	VALUES('${deptnrlz}','AH-${deptctrlz} ${insertdate} ${deptnrlz}->${upperdept}00','${upperdept}00',$randmanager)"
    dbclirc=$?
    if [[ $dbclirc -ne 0 ]] ; then
      echo "Error $dbclirc from [db2 insert into $dbtabdept (DEPTNO, DEPTNAME, ADMRDEPT, MGRNO) VALUES( ...]"	# only show error, no exit
    fi 
#
  done
  upperdept=$deptprefix			# backlink for Y... is previous X (00), for Z... is previous Y (00)
done
echo "--- Commiting work ---"
db2 "commit work"				# commit inserted department records
dbclirc=$?
if [[ $dbclirc -ne 0 ]] ; then
  echo "Error $dbclirc from [db2 commit work ]"
  db2 rollback			# Rollback work
  exit 8
fi 
echo "= = = = = = = = = Table $dbtabdept = = = = = = = = = ="
db2 "select * from $dbtabdept order by DEPTNO"		# show the results
dbclirc=$?
if [[ $dbclirc -ne 0 ]] ; then
  echo "Error $dbclirc from [db2 select * from $dbtabdept order by DEPTNO]"	# only show error, no exit
fi 
echo "= = = = = = = = = = = = = = = = = = = = = = = = = = ="


#################################################
#  Add employees
#################################################
let stepctr=stepctr+1
echo -e "\n### Step ${stepctr} - Add employees to table $dbtabempl"
#

# For random name selection
frstxstr="M   M    M       M     F     F    F         M    M    F       M      M     F   F     F    M    F   M    M      M  "
frstnstr="JIM JACK JOHNNIE HEINZ HELGA EMMA SUE-ELLEN DICK RUDY EUSEBIA DONALD DUMBO AMY BARBE ELLA PAUL SUE TOBY ZOLTAN LEE"
frstnct=$(wc -w <<< "$frstnstr")	# Count words in frstnarr (first names)
frstnarr=($frstnstr)			# Convert string to array
frstxarr=($frstxstr)			# Convert string to array (corresponding gender)
#
lastnstr="BEAM DANIELS WALKER KRAFT MEYER MAYOR WALTON TRACY GIULIANI MUELLER DUCK BIGEAR STAKE DWYER VADER BEARER FLAY LERONE PEPPER KING"
lastnct=$(wc -w <<< "$lastnstr")	# Count words in lastnarr (last names)
lastnarr=($lastnstr)			# Convert string to array
#
jobnmstr="FUZZY JANITOR DUMBO SCUM FLUNKY WEENIE GOON JERK DUMBASS"	# max. 7 chars as preceeding "@" will be added
jobnmct=$(wc -w <<< "$jobnmstr")	# Count words in lastnarr (job titles)
jobnmarr=($jobnmstr)			# Convert string to array
#
midinit="A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"	# middle initials, only for 50%, others with space
midilen=$(wc -c <<< "$midinit")		# Count chars including linefeed 
let midilen=midilen-1			# omit linefeed (e.g. 52 incl linefeed -> 51 chars)
#
roldfnme=0				# Init first "old/previous" random number for firstname
roldlnme=0				# Init first "old/previous" random number for lastname
emplno=990000				# Added employees have EMPNO > 990000
emplmx=992000				# Last EMPNO (in 10 steps)
while [[ $emplno -lt $emplmx ]] ; do
  let emplno=emplno+10			# EMPNO stepped by 10
#
  randlnme=$(($RANDOM % $lastnct))	# e.g. namecount = 20, random mod namecount between 0...19, fits index in array between 0...19
  [[ $randlnme -eq $roldlnme ]] && randlnme=$(($RANDOM % $lastnct))	# same as before ? then try another time
  roldlnme=$randlnme			# and remember this random number for next loop cycle
  empllnme="${lastnarr[$randlnme]}"
#
  randfnme=$(($RANDOM % $frstnct))	# e.g. namecount = 20, random mod namecount between 0...19, fits index in array between 0...19
  [[ $randfnme -eq $roldfnme ]] && randfnme=$(($RANDOM % $frstnct))	# same as before ? then try another time
  roldfnme=$randfnme			# and remember this random number for next loop cycle
  emplfnme="${frstnarr[$randfnme]}"
  emplfgen="${frstxarr[$randfnme]}"
#
# while lastname + firstname not already in db - or all firstnames checked
#
  let frstnmax=frstnct-1		# Word count from 1...20 but array elements from 0...19
  let nextfnme=randfnme			# Set next firstname to actual firstname element in array
  let namesequal=1			# Init condition to enter while-loop
#
  while [[ $namesequal -gt 0 ]] ; do	# while lastname + unused firstname found
# Check DB for lastname + actual firstname already in table
    namesequal=$(db2 -x "select count(*) from $dbtabempl where lastname = '${empllnme}' and firstnme = '${emplfnme}'")
    dbclirc=$?
    if [[ $dbclirc -ne 0 ]] ; then
      echo "Error $dbclirc from [db2 select count(*) from $dbtabempl where lastname = '${empllnme}' and firstnme = '${emplfnme}']"	# only show error, no exit
      let namesequal=0		# Assume no records found, so try insert
    fi 
#
    if [[ $namesequal -lt 1 ]] ; then	# if lastname + firstname combination are not in DB
      break				# then we've found unique combo: no further action required, end loop
    fi
# Wrap index to firstname array if higher than last element
    if [[ $nextfnme -lt $frstnmax ]] ; then	# if we are below the highest element in firstname array
      let nextfnme=nextfnme+1		# address next element in firstname array
    else
      nextfnme=0			# address first element in firstname array
    fi
# Have we checked all other firstname elements in array ? Then we have to exit loop
    if [[ $nextfnme -eq $randfnme ]] ; then	# we reached the firstname element where we started
      emplfnme="${frstnarr[$randfnme]}"	# use firstname element of while-loop entry
      emplfgen="${frstxarr[$randfnme]}" # use gender element of while-loop entry
      echo "- Employee $emplno name in db:  ${empllnme} ${emplfnme} ($emplfgen) but no other firstname possible"
      break				# then we've no more firstname elements to compare: no further action, end loop
    fi
#
    echo "- Employee $emplno name exists: ${empllnme} ${emplfnme} ($emplfgen), trying next firstname ${frstnarr[$nextfnme]}"
    emplfnme="${frstnarr[$nextfnme]}"	# get next firstname element
    emplfgen="${frstxarr[$nextfnme]}"	# get next gender element
  done 
#
  randmidi=$(($RANDOM % $midilen))	# e.g. 26 chars + 25 spaces = 51 chars; random mod 51 = 0...50 = A...Z and spaces between
  midichar="${midinit:$randmidi:1}"	# Pick character or space for midname initial
#
  empldept="$(db2 -x "select DEPTNO from $dbtabdept where DEPTNO like 'X%' or DEPTNO like 'Y%' or DEPTNO like 'Z%' order by RAND() limit 1")"
  dbclirc=$?
  if [[ $dbclirc -ne 0 ]] ; then
    echo "Error $dbclirc from [db2 select DEPTNO from $dbtabdept where DEPTNO like 'X%' or DEPTNO like 'Y%' or DEPTNO like 'Z%' order by RAND() limit 1']"	# only show error, no exit
    empldept="X00"		# Use default department
  fi 
  [[ $midichar != " " ]] && echotext=",mid init:${midichar}" || echotext=""
  echo "* Employee $emplno created with ${empllnme} ${emplfnme} (gender:${emplfgen}${echotext})"
#
  emplphon=$(($RANDOM % 1000))		# last three numbers of phone are random,
  emplphon="9$(printf '%03d\n' "$emplphon")"	# with leading zeroes and preceeded by "9"
#
  hiredate=$((($RANDOM % 10) + 10))		# (0...9) + 10 = 10...19
  hiredate="20${hiredate}-01-01"	# 2010...2019 new year ;-)
#
  randjobn=$(($RANDOM % $jobnmct))	# e.g. namecount = 9, random mod namecount between 0...8, fits index in array between 0...8
  jobname="@${jobnmarr[$randjobn]}"	# Jobname preceeded by "@" to filter out these new records
#
  edlevel=$((RANDOM % 100))
  let edlevel=edlevel+100
#
  birthdate=$((($RANDOM % 10) + 90))	# (0...9) + 90 = 90...99
  birthmd="${refdate:4:6}"		# derive month + day from script reference date including preceding minus sign
  birthdate="19${birthdate}${birthmd}"	# yyyy-mm-dd, yyyy = 1990...1999, mm+dd = script execution day
#
  let salary=50000+emplphon		# depends on phone number :-D
  let bonus=emplphon/10 		# depends on phone number :-D
  commission=$commtime			# Use field COMM for reference time of script
#
# echo for debugging, db2 for database insert
#
###  echo "$emplno Name: $emplfnme $midichar $empllnme Dept: $empldept Phone: $emplphon Job: $jobname Gender: $emplfgen Hiredate: $hiredate Birthdate: $birthdate Salary: $salary Bonus: $bonus Commission: $commission"
  db2 "insert into $dbtabempl (EMPNO, FIRSTNME, MIDINIT, LASTNAME, WORKDEPT, PHONENO, HIREDATE, \
	JOB, EDLEVEL, SEX, BIRTHDATE, SALARY, BONUS, COMM) \
	VALUES('${emplno}','${emplfnme}','${midichar}','${empllnme}','${empldept}',$emplphon,'${hiredate}', \
	'${jobname}',$edlevel,'${emplfgen}','${birthdate}',$salary,$bonus,$commission)"
  dbclirc=$?
  if [[ $dbclirc -ne 0 ]] ; then
    echo "Error $dbclirc from [db2 insert into $dbtabempl (EMPNO, FIRSTNME, MIDINIT, LASTNAME, WORKDEPT, ...']"	# only show error, no exit
  fi 
done
echo "--- Commiting work ---"
db2 commit work				# commit inserted employee records
dbclirc=$?
if [[ $dbclirc -ne 0 ]] ; then
  echo "Error $dbclirc from [db2 commit work ]"
  db2 rollback			# Rollback work
  exit 8
fi 
echo "= = = = = = = = = Table $dbtabempl= = = = = = = = = ="
db2 "select * from $dbtabempl order by EMPNO"		# show the results
echo "= = = = = = = = = = = = = = = = = = = = = = = = = = ="
echo "Only added records: ref date ${refdate:5:5} (month/day) in BIRTHDATE, ref time $commtime in COMM !"
#
# Exit program
#
echo -e "\n### Step ${stepctr} - All done, exit script"
db2 terminate
exit 0


