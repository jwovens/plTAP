DROP USER example_tap CASCADE
/

CREATE USER example_tap IDENTIFIED BY hello
/

CREATE OR REPLACE PACKAGE example_tap.mytests
AS
    FUNCTION test_tap       RETURN VARCHAR2;
    FUNCTION test_tap_2     RETURN VARCHAR2;
    FUNCTION test_tap_3     RETURN VARCHAR2;
    FUNCTION test_tap_4     RETURN VARCHAR2;
    
END mytests;
/
CREATE OR REPLACE PACKAGE BODY example_tap.mytests
AS
    FUNCTION test_tap    RETURN VARCHAR2
    IS 
    BEGIN
        RETURN tap.ok(true, 'this is a test');
    END test_tap;
--------------------------------------------------------------------------------
    FUNCTION test_tap_2  RETURN VARCHAR2
    IS
    BEGIN
        RETURN tap.ok(false, 'this is another test');
    END test_tap_2;
--------------------------------------------------------------------------------
    FUNCTION test_tap_3  RETURN VARCHAR2
    IS
    BEGIN
        RETURN tap.ok('test'='world', 'test that hello=world');
    END;
--------------------------------------------------------------------------------
    FUNCTION test_tap_4  RETURN VARCHAR2
    IS
        l_res NUMBER;
    BEGIN
        l_res := 1/0;
        RETURN tap.ok(FALSE, 'Dont expect to reach this test');
    END;
--------------------------------------------------------------------------------
END mytests;
/