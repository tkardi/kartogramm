#!/bin/bash
echo "starting database and processor..."

set -m

/usr/local/bin/docker-entrypoint.sh postgres -c shared_buffers=256MB -c max_wal_size=4GB -c checkpoint_timeout=5min &

until psql -h localhost -U ${POSTGRES_USER:-postgres} -p 5432 -d postgres -c "select 1" > /dev/null 2>&1; do
  echo "Waiting for database to get ready..."
  sleep 1
done

/bin/bash -c "source /app/venv/bin/activate && cd /app/main &&  python3 /app/main/data/prepare.py && python3 /app/main/data/postprocessing/prepare.py && deactivate"

if [ "${SHUTDOWN_AT_END}" = "yes" ]; then
    echo "Shutting down database as SHUTDOWN_AT_END=${SHUTDOWN_AT_END}"
    x=$(which pg_ctl)
    su - "${POSTGRES_USER:-postgres}" -c "${x} -D \"${PGDATA}\" -w stop"
else
    echo "Keep database running as SHUTDOWN_AT_END=${SHUTDOWN_AT_END}"
    fg %1
fi
