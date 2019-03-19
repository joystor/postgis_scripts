-- Function to search tables can export from MultiPoint to Point
--
-- Use: SELECT * FROM MultiPoint2Point() AS ( tablename text, msg text );

CREATE OR REPLACE FUNCTION MultiPoint2Point()
 RETURNS SETOF RECORD AS $BODY$
DECLARE
 _recgeoms RECORD;
 _rcount RECORD;
 _result RECORD;
 _sql TEXT;
 _msg TEXT;
BEGIN
 FOR _recgeoms IN
    select '"'||f_table_schema||'"."'||f_table_name||'"' tablename, f_geometry_column geomcolumn, srid from geometry_columns where type='MULTIPOINT'
 LOOP
   _sql := 'SELECT COUNT(CASE WHEN ST_NumGeometries('||_recgeoms.geomcolumn||') > 1 THEN 1 END) AS multi_geom FROM ' || _recgeoms.tablename;
   raise notice '%', _sql;
   EXECUTE _sql INTO _rcount;
   IF _rcount.multi_geom = 0 THEN
     --_msg = 'Table can export to POINT';
     _msg = 'ALTER TABLE ' || _recgeoms.tablename || ' ALTER COLUMN '||_recgeoms.geomcolumn||' TYPE geometry(Point,'||_recgeoms.srid||') USING ST_GeometryN('||_recgeoms.geomcolumn||', 1);';
   ELSE
     _msg = 'Table can not export to POINT';
   END IF;
   SELECT INTO _result _recgeoms.tablename,_msg;
   RETURN NEXT _result;
 END LOOP;
END
$BODY$ LANGUAGE plpgsql;
