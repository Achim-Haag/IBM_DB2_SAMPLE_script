# IBM DB2 Database SAMPLE modification script
## Requirements
### Operating System and Database Level
I developed this script in 
 - RHEL 8.10 Ootpa    (see _/etc/redhat-release_)
 - bash 4.4.20(1)-release  (see _echo $BASH_VERSION_)
 - DB2 v11.5.9.0 Community Edition  (see _db2level_)

### Database Environment
The script runs in any instance user that created the SAMPLE database by the IBM deliviered program ___db2sampl___ (usually in _~/sqllib/bin/db2sampl_). The SAMPLE database must contain two tables DEPT (DEPARTMENT) and EMP (EMPLOYEE) and be accessible to the user that runs the script (which should be true for an DB2 instance user as SAMPLE creator).

>[!NOTE]
>The script may run in DB2 versions down to 9.7.2 because of the SQL options __RAND()__ and __LIMIT__, which should be available at least [since DB2 9.7.2](https://programmingzen.com/enabling-limit-and-offset-in-db2-9-7-2/ "Enabling LIMIT and OFFSET in DB2 9.7.2").
>
> _select empno from $dbtabempl order by __rand() limit__ 1_


## Script Usage
### Installation
Simply copy the script to the home directory of the instance user or to any directory this user can access.
Add the mod-bits for execution (_chmod u+x <scriptname>_) to execute it.
### Execution
Currently (Mar 2025) the script supports two parameters
- -h : show some help of usage and parameters
  -d : only delete formerly inserted records, do not insert new ones.

  
