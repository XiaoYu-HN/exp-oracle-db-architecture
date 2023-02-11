create table big_table
as
select rownum id, a.*
  from all_objects a
 where 1=0
/
alter table big_table nologging;

declare
    l_cnt number;
    l_rows number := &1;
begin
    insert /*+ append */
    into big_table
    select rownum, a.*
      from all_objects a
	 where rownum <= &1;

    l_cnt := sql%rowcount;

    commit;

    while (l_cnt < l_rows)
    loop
        insert /*+ APPEND */ into big_table
        select rownum+l_cnt, 
               owner,
                object_name,
                subobject_name,
                object_id,
                data_object_id,
                object_type,
                created,
                last_ddl_time,
                timestamp,
                status,
                temporary,
                generated,
                secondary,
                namespace,
                edition_name,
                sharing,
                editionable,
                oracle_maintained,
                application,
                default_collation,
                duplicated,
                sharded,
                imported_object,
                created_appid,
                created_vsnid,
                modified_appid,
                modified_vsnid
          from big_table
         where rownum <= l_rows-l_cnt;
        l_cnt := l_cnt + sql%rowcount;
        commit;
    end loop;
end;
/
alter table big_table add constraint
big_table_pk primary key(id);

exec dbms_stats.gather_table_stats( user, 'BIG_TABLE', estimate_percent=> 1);
