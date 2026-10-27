CREATE OR REPLACE PACKAGE ems_security AUTHID DEFINER AS
    PROCEDURE require_role(p_role_code IN VARCHAR2);
    PROCEDURE require_employee_access(p_employee_id IN NUMBER);
END ems_security;
/

CREATE OR REPLACE PACKAGE BODY ems_security AS
    PROCEDURE require_role(p_role_code IN VARCHAR2) IS
        v_count PLS_INTEGER;
    BEGIN
        SELECT COUNT(*)
          INTO v_count
          FROM app_user_roles
          WHERE UPPER(username) = UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER'))
            AND (role_code = UPPER(p_role_code) OR role_code = 'HR_ADMIN');

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Insufficient application role.');
        END IF;
    END require_role;

    PROCEDURE require_employee_access(p_employee_id IN NUMBER) IS
        v_count PLS_INTEGER;
    BEGIN
        SELECT COUNT(*)
          INTO v_count
          FROM app_user_roles
         WHERE UPPER(username) = UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER'))
           AND role_code IN ('HR_ADMIN', 'MANAGER');

        IF v_count = 0 THEN
            SELECT COUNT(*)
              INTO v_count
              FROM employees e
              JOIN app_user_roles r
                ON UPPER(r.username) = UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER'))
               AND r.role_code = 'EMPLOYEE'
             WHERE e.employee_id = p_employee_id
               AND UPPER(e.login_name) = UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER'));
        END IF;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Insufficient access to employee record.');
        END IF;
    END require_employee_access;
END ems_security;
/
