#!/usr/bin/env bash

MYSQL="mysql -u root"
MYSQLDUMP="mysqldump -u root \
    --add-drop-table \
    --complete-insert \
    --skip-extended-insert \
    --routines "
DB="prisoners"
REPODIR=".."

DBUSER='koldrayn'
DBUSERPASS='qwerty'

RETVAL=0

db_reset(){
    echo -n "Re-creating ${DB}.. "
    echo "DROP DATABASE IF EXISTS \`$DB\`; CREATE DATABASE \`$DB\`;" | $MYSQL
}

db_grant() {
    [ -z "$1" ] || DBUSER=$1
    [ -z "$2" ] || DBUSERPASS=$2
    echo -n "Grant privileges on $DB to ${DBUSER}/${DBUSERPASS} .. " # DBUSERPASS is not so secret in this case, but there is sense to see it here
    echo "GRANT ALL PRIVILEGES ON \`$DB\`.* to '$DBUSER'@'%' IDENTIFIED BY '$DBUSERPASS';" | mysql -u root $DB
}

db_store(){
    SQLDUMP=$1
    [ -z "$SQLDUMP" ] && SQLDUMP="${REPODIR}/etc/${DB}.sql"
    echo "Storing DB $DB to file $SQLDUMP ..."
    $MYSQLDUMP $DB >$SQLDUMP
    RETVAL=$?
    echo
}

db_restore(){
    SQLDUMP=$1
    [ -z "$SQLDUMP" ] && SQLDUMP="${REPODIR}/etc/${DB}.sql"
    echo "Restoring DB $DB from file $SQLDUMP ..."
    $MYSQL $DB <$SQLDUMP
    RETVAL=$?
    echo
}

case "$1" in
    store)
        db_store $2
        [ $RETVAL -eq 0 ] || echo "store failed!!"
        ;;
    restore)
        db_restore $2
        [ $RETVAL -eq 0 ] || echo "restore failed!!"
        ;;
    db-reset)
        db_reset && echo "done." || echo "failed!!"
        ;;
    db-grant)
        db_grant $2 $3 && echo "done." || echo "failed!!"
        ;;
    *)
    cat << EOD
Usage: `basename $0` {store [sqldumpfile]|restore [sqldumpfile]|db-reset|db-grant [DBUSER] [DBUSERPASS]}
    store [sqldumpfile]
        - dump the current db structure into file
    restore [sqldumpfile]
        - import the file dump into the db (db structures not altered by dump are preserved)
    clean
        - revert/clean temporary data produced by running the test cases
    db-reset
        - create new empty db ready for complete restore
    db-grant [DBUSER] [DBUSERPASS]
        - restore GRANTed permissions for given user
EOD
    RETVAL=1
esac

exit $RETVAL
