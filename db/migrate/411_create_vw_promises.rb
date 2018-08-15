class CreateVwPromises < ActiveRecord::Migration[5.1]
  def up
    execute <<SQL
drop view if exists marty_vw_promises;
create or replace view marty_vw_promises
as
select
id,
title,
user_id,
cformat,
parent_id,
job_id,
status,
start_dt,
end_dt
from marty_promises;

grant select on marty_vw_promises to public;

SQL
  end
  def down
    execute "drop view if exists marty_vw_promises;"
  end
end
