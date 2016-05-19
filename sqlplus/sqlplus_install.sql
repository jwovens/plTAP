def pltap_schema=&1
DECLARE
    user_not_exists EXCEPTION;
    PRAGMA EXCEPTION_INIT (user_not_exists, -01918);
BEGIN
    EXECUTE IMMEDIATE 'DROP USER &pltap_schema CASCADE';
EXCEPTION
    WHEN user_not_exists THEN NULL;
END;
/
CREATE USER &pltap_schema IDENTIFIED BY hello
/

CREATE OR REPLACE TYPE &pltap_schema..tapstream_tab_type AS TABLE OF VARCHAR2(8000)
/

CREATE OR REPLACE TYPE &pltap_schema..string_tab_type AS TABLE OF VARCHAR2(8000)
/

CREATE OR REPLACE PACKAGE &pltap_schema..tap
AUTHID CURRENT_USER
AS
    FUNCTION ok(bool BOOLEAN, msg  VARCHAR2)    
        RETURN VARCHAR2;
    
    FUNCTION run_tests(ut_schema  VARCHAR2, ut_package VARCHAR2)
        RETURN tapstream_tab_type PIPELINED;
    
    -- Test that strings match
    FUNCTION thisisthat(have VARCHAR2, want VARCHAR2, msg VARCHAR2)
    RETURN VARCHAR2;
    
    -- Test that numbers match
    FUNCTION thisisthat(have NUMBER, want NUMBER, msg VARCHAR2)
    RETURN VARCHAR2;
    
    -- Test that strings do not match
    FUNCTION thisisntthat(have VARCHAR2, want VARCHAR2, msg VARCHAR2)
    RETURN VARCHAR2;
    
    -- Test that numbers do not match 
    FUNCTION thisisntthat(have NUMBER, want NUMBER, msg VARCHAR2)
    RETURN VARCHAR2;

    -- Test that 'this' matches wildcard pattern 'alike'
    FUNCTION alike(this VARCHAR2, alike VARCHAR2, msg VARCHAR2)
    RETURN VARCHAR2;

    -- Test that 'this' matches wildcard pattern 'alike' case insensitive
    FUNCTION ialike(this VARCHAR2, alike VARCHAR2, msg VARCHAR2)
    RETURN VARCHAR2;

    -- Test that 'this' and 'that' parameters resolve to true given by operator, 'op'
    FUNCTION cmp_ok(this VARCHAR2, op VARCHAR2, that VARCHAR2, msg VARCHAR2)
    RETURN VARCHAR2;

    -- Test that 'this' and 'that' parameters resolve to true given by operator, 'op'
    FUNCTION cmp_ok(this NUMBER, op VARCHAR2, that NUMBER, msg VARCHAR2)
    RETURN VARCHAR2;

    -- Test that expected nested table of strings is contained within single-column
    -- results set given by sqlstring
    FUNCTION is_subset_of_sql(expected string_tab_type, sqlstring VARCHAR2, msg VARCHAR2)
    RETURN VARCHAR2;
        
END tap;
/

CREATE OR REPLACE PACKAGE body &pltap_schema..tap
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
    FUNCTION thisisthat(have VARCHAR2, want VARCHAR2, msg VARCHAR2)
    RETURN VARCHAR2
    AS
    BEGIN
        RETURN ok(have=want, msg);
    END thisisthat;
--------------------------------------------------------------------------------
    FUNCTION thisisthat(have NUMBER, want NUMBER, msg VARCHAR2)
    RETURN VARCHAR2
    AS
    BEGIN
        RETURN ok(have=want, msg);
    END thisisthat;   
--------------------------------------------------------------------------------
    FUNCTION thisisntthat(have VARCHAR2, want VARCHAR2, msg VARCHAR2)
    RETURN VARCHAR2
    AS
    BEGIN
        RETURN ok(have!=want, msg);
    END thisisntthat;
--------------------------------------------------------------------------------
    FUNCTION thisisntthat(have NUMBER, want NUMBER, msg VARCHAR2)
    RETURN VARCHAR2
    AS
    BEGIN
        RETURN ok(have!=want, msg);
    END thisisntthat; 
--------------------------------------------------------------------------------
    FUNCTION alike(this VARCHAR2, alike VARCHAR2, msg VARCHAR2)
    RETURN VARCHAR2
    AS
    BEGIN
        RETURN ok(this LIKE alike, msg);
    END alike; 
--------------------------------------------------------------------------------
    FUNCTION ialike(this VARCHAR2, alike VARCHAR2, msg VARCHAR2)
    RETURN VARCHAR2
    AS
    BEGIN
        RETURN ok(lower(this) LIKE lower(alike), msg);
    END ialike; 
--------------------------------------------------------------------------------
    FUNCTION cmp_ok(this VARCHAR2, op VARCHAR2, that VARCHAR2, msg VARCHAR2)
    RETURN VARCHAR2
    AS
        l_res number;
    BEGIN
        EXECUTE IMMEDIATE 
            'begin if '''||this||''''||op||''''||that||''' then :l_res := 1; else :l_res := 0; end if; end;'
        USING OUT l_res;
        RETURN ok(l_res=1, msg);
    END cmp_ok; 
--------------------------------------------------------------------------------
    FUNCTION cmp_ok(this NUMBER, op VARCHAR2, that NUMBER, msg VARCHAR2)
    RETURN VARCHAR2
    AS
        l_res number;
    BEGIN
        EXECUTE IMMEDIATE 
            'begin if '||this||''||op||''||that||' then :l_res := 1; else :l_res := 0; end if; end;'
        USING OUT l_res;
        RETURN ok(l_res=1, msg);
    END cmp_ok; 
--------------------------------------------------------------------------------
    FUNCTION is_subset_of_sql(expected string_tab_type, sqlstring VARCHAR2, msg VARCHAR2)
    RETURN VARCHAR2
    AS
        l_csr    sys_refcursor;
        l_actual string_tab_type;
    BEGIN
        OPEN  l_csr FOR sqlstring;
        FETCH l_csr BULK COLLECT INTO l_actual;
        
        RETURN ok(expected SUBMULTISET OF l_actual, msg);
    END;
--------------------------------------------------------------------------------
END tap;
/

GRANT EXECUTE ON &pltap_schema..tap TO PUBLIC
/
CREATE OR REPLACE PUBLIC SYNONYM tap FOR &pltap_schema..tap
/

GRANT EXECUTE ON &pltap_schema..string_tab_type TO PUBLIC
/
CREATE OR REPLACE PUBLIC SYNONYM string_tab_type FOR &pltap_schema..string_tab_type
/

