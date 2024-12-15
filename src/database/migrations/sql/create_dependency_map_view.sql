CREATE OR REPLACE VIEW public.tr1884_dbdepends_vw_dependency_map
 AS
 WITH RECURSIVE ctedepends AS (
         SELECT DISTINCT 1 AS depth,
            source_ns.nspname AS source_schema,
            source_table.relname AS source_rel,
            source_ns.nspname AS inter_schema,
            source_table.relname AS inter_rel,
            dependent_ns.nspname AS dependent_schema,
            dependent_view.relname AS dependent_rel
           FROM pg_depend
             JOIN pg_rewrite ON pg_depend.objid = pg_rewrite.oid
             JOIN pg_class dependent_view ON dependent_view.oid = pg_rewrite.ev_class
             JOIN pg_class source_table ON source_table.oid = pg_depend.refobjid
             JOIN pg_namespace dependent_ns ON dependent_ns.oid = dependent_view.relnamespace
             JOIN pg_namespace source_ns ON source_ns.oid = source_table.relnamespace
          WHERE NOT (dependent_ns.nspname = source_ns.nspname AND dependent_view.relname = source_table.relname)
        UNION
         SELECT DISTINCT cd.depth + 1 AS depth,
            cd.source_schema,
            cd.source_rel,
            source_ns.nspname AS inter_schema,
            source_table.relname AS inter_rel,
            dependent_ns.nspname AS dependent_schema,
            dependent_view.relname AS dependent_rel
           FROM pg_depend
             JOIN pg_rewrite ON pg_depend.objid = pg_rewrite.oid
             JOIN pg_class dependent_view ON pg_rewrite.ev_class = dependent_view.oid
             JOIN pg_class source_table ON pg_depend.refobjid = source_table.oid
             JOIN pg_namespace dependent_ns ON dependent_ns.oid = dependent_view.relnamespace
             JOIN pg_namespace source_ns ON source_ns.oid = source_table.relnamespace
             JOIN ctedepends cd ON cd.dependent_schema = source_ns.nspname AND cd.dependent_rel = source_table.relname AND NOT (dependent_ns.nspname = cd.dependent_schema AND dependent_view.relname = cd.dependent_rel)
        ), ctedependents AS (
         SELECT x.source,
            string_agg(x.dependent, ' | '::text) AS dependents,
            count(*) AS deps
           FROM ( SELECT DISTINCT (ctedepends.source_schema::text || '.'::text) || ctedepends.source_rel::text AS source,
                    (ctedepends.dependent_schema::text || '.'::text) || ctedepends.dependent_rel::text AS dependent
                   FROM ctedepends
                  WHERE 1 = ctedepends.depth) x
          GROUP BY x.source
          ORDER BY x.source
        ), cteadddependents AS (
         SELECT x.source,
            string_agg(DISTINCT x.dependent, ' | '::text) AS dependents,
            count(*) AS deps
           FROM ( SELECT DISTINCT (dep_1.source_schema::text || '.'::text) || dep_1.source_rel::text AS source,
                    (dep_1.dependent_schema::text || '.'::text) || dep_1.dependent_rel::text AS dependent
                   FROM ctedepends dep_1
                     JOIN ctedependents deps ON deps.source = ((dep_1.source_schema::text || '.'::text) || dep_1.source_rel::text)
                  WHERE 1 < dep_1.depth AND 0 = POSITION((((dep_1.dependent_schema::text || '.'::text) || dep_1.dependent_rel::text) || ' |'::text) IN (deps.dependents || ' |'::text))) x
          GROUP BY x.source
          ORDER BY x.source
        ), cterequires AS (
         SELECT DISTINCT ns_r.nspname AS basensp,
            cl_r.relname AS basename,
            ns_r.nspname AS relnsp,
            cl_r.relname,
            ns_d.nspname AS reqnsp,
            cl_d.relname AS reqname,
            1 AS depth
           FROM pg_rewrite r
             JOIN pg_class cl_r ON cl_r.oid = r.ev_class
             JOIN pg_namespace ns_r ON ns_r.oid = cl_r.relnamespace
             JOIN pg_depend d ON d.objid = r.oid
             JOIN pg_class cl_d ON cl_d.oid = d.refobjid
             JOIN pg_namespace ns_d ON ns_d.oid = cl_d.relnamespace
          WHERE (cl_d.relkind = ANY (ARRAY['r'::"char", 'm'::"char", 'v'::"char"])) AND (ns_r.nspname <> ALL (ARRAY['information_schema'::name, 'pg_catalog'::name])) AND ns_r.nspname !~~ 'pg_toast%'::text AND ((ns_r.nspname::text || '.'::text) || cl_r.relname::text) <> ((ns_d.nspname::text || '.'::text) || cl_d.relname::text)
        UNION
         SELECT cterequires.basensp,
            cterequires.basename,
            ns_r.nspname AS relnsp,
            cl_r.relname,
            ns_d.nspname AS reqnsp,
            cl_d.relname AS reqname,
            cterequires.depth + 1 AS depth
           FROM pg_rewrite r
             JOIN pg_class cl_r ON cl_r.oid = r.ev_class
             JOIN pg_namespace ns_r ON ns_r.oid = cl_r.relnamespace
             JOIN pg_depend d ON d.objid = r.oid
             JOIN pg_class cl_d ON cl_d.oid = d.refobjid
             JOIN pg_namespace ns_d ON ns_d.oid = cl_d.relnamespace
             JOIN cterequires ON cterequires.reqnsp = ns_r.nspname AND cterequires.reqname = cl_r.relname AND NOT (cterequires.reqnsp = ns_d.nspname AND cterequires.reqname = cl_d.relname)
          WHERE ((ns_r.nspname::text || '.'::text) || cl_r.relname::text) <> ((ns_d.nspname::text || '.'::text) || cl_d.relname::text) AND (cl_d.relkind = ANY (ARRAY['r'::"char", 'm'::"char", 'v'::"char"])) AND ns_r.nspname !~~ 'pg_toast%'::text AND (ns_r.nspname <> ALL (ARRAY['information_schema'::name, 'pg_catalog'::name]))
        ), cterequirements AS (
         SELECT DISTINCT (cterequires.basensp::text || '.'::text) || cterequires.basename::text AS rel,
            count(*) AS reqs,
            string_agg((cterequires.reqnsp::text || '.'::text) || cterequires.reqname::text, ' | '::text) AS reqlist
           FROM cterequires
          WHERE 1 = cterequires.depth
          GROUP BY ((cterequires.basensp::text || '.'::text) || cterequires.basename::text)
        ), cteaddrequirements AS (
         SELECT DISTINCT (cterequires.basensp::text || '.'::text) || cterequires.basename::text AS rel,
            count(*) AS addreqs,
            string_agg(DISTINCT (cterequires.reqnsp::text || '.'::text) || cterequires.reqname::text, ' | '::text) AS addreqlist
           FROM cterequires
             JOIN cterequirements ON cterequirements.rel = ((cterequires.basensp::text || '.'::text) || cterequires.basename::text)
          WHERE 1 < cterequires.depth AND 0 = POSITION((((cterequires.reqnsp::text || '.'::text) || cterequires.reqname::text) || ' |'::text) IN (cterequirements.reqlist || ' |'::text))
          GROUP BY ((cterequires.basensp::text || '.'::text) || cterequires.basename::text)
        )
SELECT (nsp.nspname::text || '.'::text) || cls.relname::text AS relation,
        CASE cls.relkind
            WHEN 'r'::"char" THEN 'TABLE'::text
            WHEN 'v'::"char" THEN 'VIEW'::text
            WHEN 'm'::"char" THEN 'MATV'::text
            WHEN 'i'::"char" THEN 'INDEX'::text
            WHEN 'S'::"char" THEN 'SEQUENCE'::text
            WHEN 'c'::"char" THEN 'TYPE'::text
            ELSE cls.relkind::text
            END AS object_type,
       rol.rolname AS owner,
       COALESCE(dep.deps, 0::bigint) AS deps,
       CASE
           WHEN ''::text <> depadd.dependents THEN 1 + (length(depadd.dependents) - length(replace(depadd.dependents, '|'::text, ''::text)))
           ELSE 0
           END AS add_deps,
       COALESCE(req.reqs, 0::bigint) AS reqs,
       CASE
           WHEN ''::text <> addreq.addreqlist THEN 1 + (length(addreq.addreqlist) - length(replace(addreq.addreqlist, '|'::text, ''::text)))
           ELSE 0
           END AS add_reqs,
       COALESCE(dep.dependents, ''::text) AS dependents,
       COALESCE(depadd.dependents, ''::text) AS add_dependents,
       COALESCE(req.reqlist, ''::text) AS requirements,
       COALESCE(addreq.addreqlist, ''::text) AS add_requirements
FROM pg_class cls
         JOIN pg_namespace nsp ON nsp.oid = cls.relnamespace
         JOIN pg_roles rol ON rol.oid = cls.relowner
         LEFT JOIN ctedependents dep ON dep.source = ((nsp.nspname::text || '.'::text) || cls.relname::text)
     LEFT JOIN cteadddependents depadd ON depadd.source = ((nsp.nspname::text || '.'::text) || cls.relname::text)
    LEFT JOIN cterequirements req ON req.rel = ((nsp.nspname::text || '.'::text) || cls.relname::text)
    LEFT JOIN cteaddrequirements addreq ON addreq.rel = ((nsp.nspname::text || '.'::text) || cls.relname::text)
WHERE (cls.relkind = ANY (ARRAY['r'::"char", 'v'::"char", 'm'::"char"])) AND nsp.nspname !~~ 'pg_toast%'::text AND (nsp.nspname <> ALL (ARRAY['information_schema'::name, 'pg_catalog'::name]))
ORDER BY nsp.nspname, cls.relname;