DROP USER pltap CASCADE
/

CREATE USER pltap IDENTIFIED BY hello
/

CREATE OR REPLACE TYPE pltap.tapstream_tab_type AS TABLE OF VARCHAR2(8000)
/

CREATE OR REPLACE PACKAGE pltap.tap
AUTHID CURRENT_USER
AS
    FUNCTION ok(bool BOOLEAN, msg  VARCHAR2)    
        RETURN VARCHAR2;
    
    FUNCTION run_tests(ut_schema  VARCHAR2, ut_package VARCHAR2)
        RETURN tapstream_tab_type PIPELINED;
        
END tap;
/

CREATE OR REPLACE PACKAGE body pltap.tap
AS
    pl_field_separate  char(1) := chr(30);
    
--------------------------------------------------------------------------------    
    PROCEDURE get_tests(p_schema  VARCHAR2,
                        p_package VARCHAR2, 
                        p_candidates OUT tapstream_tab_type)
    AS
    BEGIN
        -- get all unit tests that are candidates for running
        SELECT a.owner||'.'||a.object_name||'.'|| a.procedure_name 
        BULK COLLECT INTO p_candidates
        FROM   all_procedures a
        WHERE  upper(owner)       = upper(p_schema)
        AND    upper(object_name) = upper(p_package)
        AND    object_type        = 'PACKAGE'
        AND    procedure_name    IS NOT NULL
        ORDER BY a.subprogram_id;
        
    END get_tests;
--------------------------------------------------------------------------------    
    FUNCTION run_tests(ut_schema  VARCHAR2, ut_package VARCHAR2)
    RETURN tapstream_tab_type PIPELINED
    IS
        rec   tapstream_tab_type;
        l_res VARCHAR2(8000);
    BEGIN
        get_tests(ut_schema,ut_package,rec);
        --  For each candidate test to run, pipe the TAP output (okay/not okay)
        --  to a result set.  Prefix the result set with the expected number as per
        --  TAP specification.  Put test number in to each result.
        PIPE ROW ('1..'||rec.count);
        FOR i IN rec.first .. rec.last
        LOOP
            BEGIN
                l_res := NULL;
                EXECUTE IMMEDIATE 'begin :res := '||rec(i)||'; end;' USING OUT l_res;
                PIPE ROW (regexp_replace (l_res, pl_field_separate, ' '||i||' - ' ) );
            EXCEPTION
                WHEN OTHERS THEN
                    PIPE ROW ('not okay '||i||' - '||rec(i)||':'||sqlerrm);
            END;
        END LOOP;
    END run_tests;
--------------------------------------------------------------------------------
    FUNCTION ok(bool BOOLEAN, msg  VARCHAR2)
    RETURN VARCHAR2
    AS
    BEGIN
        RETURN CASE(bool) WHEN true THEN  'okay'
                          WHEN false THEN 'not okay'
               END || pl_field_separate || msg;
    END ok;
--------------------------------------------------------------------------------
END tap;
/

GRANT EXECUTE ON pltap.tap TO PUBLIC
/
CREATE OR REPLACE PUBLIC SYNONYM tap FOR pltap.tap
/