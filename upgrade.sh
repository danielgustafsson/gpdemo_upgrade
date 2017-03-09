#!/bin/bash

#EXTRA_OPTIONS='--debug'

OLD_BINDIR=/Users/danielgustafsson/dev/greenplum/obj_43/bin/
OLD_DATADIRS=/Users/danielgustafsson/dev/greenplum/archive/gpdb4/gpAux/gpdemo/datadirs
NEW_BINDIR=/Users/danielgustafsson/dev/greenplum/obj_merge/bin/
NEW_DATADIRS=/Users/danielgustafsson/dev/greenplum/gpdb/mergetest/gpAux/gpdemo/datadirs

tar -zcvf "pg_upgrade_bkup_$(date '+%y-%m-%d-%H-%M-%s').tar.gz" upgrade/
rm -rf upgrade/

# Master
mkdir -p upgrade/qd
pushd upgrade/qd
time ../../bin/pg_upgrade --old-bindir=${OLD_BINDIR} --old-datadir=${OLD_DATADIRS}/qddir/demoDataDir-1/ --new-bindir=${NEW_BINDIR} --new-datadir=${NEW_DATADIRS}/qddir/demoDataDir-1/ --logfile=pg_upgrade.log $EXTRA_OPTIONS
if (( $? )) ; then
	echo "ERROR: Failure encountered in upgrading QD"
	exit
fi
popd

# Segments
for i in 1 2 3
do
	mkdir -p "upgrade/dbfast$i"
	cp upgrade/qd/pg_upgrade_dump_oid_dispatch.sql "upgrade/dbfast$i/"
	pushd "upgrade/dbfast$i"
	j=$(($i-1))
	time ../../bin/pg_upgrade --old-bindir=${OLD_BINDIR} --old-datadir="${OLD_DATADIRS}/dbfast$i/demoDataDir$j/" --new-bindir=${NEW_BINDIR} --new-datadir="${NEW_DATADIRS}/dbfast$i/demoDataDir$j/" --logfile=pg_upgrade.log $EXTRA_OPTIONS
	if (( $? )) ; then
		echo "ERROR: Failure encountered in upgrading segment $i"
		exit
	fi
	popd
done

# Mirrors
for i in 1 2 3
do
	mkdir -p "upgrade/dbfast_mirror$i"
	cp upgrade/qd/pg_upgrade_dump_oid_dispatch.sql "upgrade/dbfast_mirror$i/"
	pushd "upgrade/dbfast_mirror$i"
	j=$(($i-1))
	time ../../bin/pg_upgrade --old-bindir=${OLD_BINDIR} --old-datadir="${OLD_DATADIRS}/dbfast_mirror$i/demoDataDir$j/" --new-bindir=${NEW_BINDIR} --new-datadir="${NEW_DATADIRS}/dbfast_mirror$i/demoDataDir$j/" --logfile=pg_upgrade.log $EXTRA_OPTIONS
	if (( $? )) ; then
		echo "ERROR: Failure encountered in upgrading mirror $i"
		exit
	fi
	popd
done

