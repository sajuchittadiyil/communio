-- Run after 202608290001_secure_legacy_demo_views.sql in a transaction-safe
-- validation session. The queries emit metadata/counts only, never row data.

-- Inventory definitions, invoker settings, grants and base-relation RLS.
select
  view_relation.relname as view_name,
  pg_get_viewdef(view_relation.oid, true) as view_definition,
  coalesce(view_relation.reloptions, array[]::text[]) as view_options,
  grantee.grantee,
  grantee.privilege_type,
  source_namespace.nspname as source_schema,
  source_relation.relname as source_relation,
  source_relation.relrowsecurity as source_rls_enabled,
  source_relation.relforcerowsecurity as source_rls_forced
from pg_class view_relation
join pg_namespace view_namespace
  on view_namespace.oid = view_relation.relnamespace
left join information_schema.role_table_grants grantee
  on grantee.table_schema = view_namespace.nspname
 and grantee.table_name = view_relation.relname
left join pg_rewrite rewrite on rewrite.ev_class = view_relation.oid
left join pg_depend dependency
  on dependency.classid = 'pg_rewrite'::regclass
 and dependency.objid = rewrite.oid
 and dependency.refclassid = 'pg_class'::regclass
left join pg_class source_relation
  on source_relation.oid = dependency.refobjid
 and source_relation.oid <> view_relation.oid
left join pg_namespace source_namespace
  on source_namespace.oid = source_relation.relnamespace
where view_namespace.nspname = 'public'
  and view_relation.relkind = 'v'
  and view_relation.relname like 'v_demo\_%' escape '\'
order by view_relation.relname, grantee.grantee, source_relation.relname;

-- Migration invariants. This block raises instead of returning private data.
do $$
declare
  insecure record;
begin
  for insecure in
    select relation.relname
    from pg_class relation
    join pg_namespace namespace on namespace.oid = relation.relnamespace
    where namespace.nspname = 'public'
      and relation.relkind = 'v'
      and relation.relname like 'v_demo\_%' escape '\'
      and (
        not coalesce(relation.reloptions, array[]::text[])
          @> array['security_invoker=true']
        or has_table_privilege(
          'anon', format('public.%I', relation.relname), 'select'
        )
      )
  loop
    raise exception 'Insecure legacy view remains: public.%', insecure.relname;
  end loop;
end;
$$;

-- Post-deployment API matrix (execute from the validation harness with the
-- corresponding JWT; request only count/head metadata):
-- anon: every public.v_demo_* request must be denied.
-- member: results must be limited by the existing member-safe base RLS.
-- community superior: results must be limited to self/managed-community RLS.
-- provincial: all eleven reporting paths must remain available.

