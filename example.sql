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
    FUNCTION test_tap_5     RETURN VARCHAR2;
    FUNCTION test_tap_6     RETURN VARCHAR2;
    FUNCTION test_tap_7     RETURN VARCHAR2;
    FUNCTION test_tap_8     RETURN VARCHAR2;
    FUNCTION test_tap_9     RETURN VARCHAR2;
    FUNCTION test_tap_10    RETURN VARCHAR2;
    FUNCTION test_tap_11    RETURN VARCHAR2;
    FUNCTION test_tap_12    RETURN VARCHAR2;
    FUNCTION test_tap_13    RETURN VARCHAR2;
    
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
    END test_tap_3;
--------------------------------------------------------------------------------
    FUNCTION test_tap_4  RETURN VARCHAR2
    IS
        l_res NUMBER;
    BEGIN
        l_res := 1/0;
        RETURN tap.ok(FALSE, 'Dont expect to reach this test');
    END test_tap_4;
--------------------------------------------------------------------------------
    FUNCTION test_tap_5 RETURN VARCHAR2
    IS
    BEGIN
        RETURN tap.thisisthat('hello world','hello'||' world','test strings are equivalent');
    END test_tap_5;
--------------------------------------------------------------------------------
    FUNCTION test_tap_6 RETURN VARCHAR2
    IS
    BEGIN
        RETURN tap.thisisthat(10/2, 25/5, 'test numbers are equivalent');
    END test_tap_6;
--------------------------------------------------------------------------------
    FUNCTION test_tap_7 RETURN VARCHAR2
    IS
    BEGIN
        RETURN tap.thisisntthat('hello world','hello peeps','test strings do not match');
    END test_tap_7;
--------------------------------------------------------------------------------
    FUNCTION test_tap_8 RETURN VARCHAR2
    IS
    BEGIN
        RETURN tap.thisisntthat(42, 2001, 'test numbers do not match');
    END test_tap_8;
--------------------------------------------------------------------------------
    FUNCTION test_tap_9 RETURN VARCHAR2
    IS
    BEGIN
        RETURN tap.alike('ello worl','%ello worl%','test string matches LIKE pattern');
    END test_tap_9;
--------------------------------------------------------------------------------
    FUNCTION test_tap_10 RETURN VARCHAR2
    IS
    BEGIN
        RETURN tap.ialike('eLLo wOrl','%Ello%','test string matches LIKE pattern case insensitive');
    END test_tap_10;
--------------------------------------------------------------------------------
    FUNCTION test_tap_11 RETURN VARCHAR2
    IS
    BEGIN
        RETURN tap.cmp_ok('Hello','!=','world','test that strings are unequal');
    END test_tap_11;
--------------------------------------------------------------------------------
    FUNCTION test_tap_12 RETURN VARCHAR2
    IS
    BEGIN
        RETURN tap.cmp_ok('a','<','b','test that a is less than b');
    END test_tap_12;
--------------------------------------------------------------------------------
    FUNCTION test_tap_13 RETURN VARCHAR2
    IS
    BEGIN
        RETURN tap.cmp_ok(sqrt(2),'>=',1.4,'test that root2 is >= 1.4');
    END test_tap_13;    
--------------------------------------------------------------------------------
    
END mytests;
/