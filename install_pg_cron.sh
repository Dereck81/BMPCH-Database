sudo dnf install make gcc git postgresql-server-devel -y
sudo dnf group install -y "Development Tools"
git clone https://github.com/citusdata/pg_cron.git
cd pg_cron
# Ensure pg_config is in your path, e.g.
export PATH=/usr/pgsql-16/bin:$PATH
make && sudo PATH=$PATH make install

sudo echo "shared_preload_libraries = 'pg_cron'" >> /var/lib/pgsql/data/postgresql.conf
sudo echo "cron.database_name = 'db_biblioteca'" >> /var/lib/pgsql/data/postgresql.conf
sudo systemctl restart postgresql
