INSERT INTO departments (department_name) VALUES ('Human Resources');
INSERT INTO departments (department_name) VALUES ('Engineering');
INSERT INTO departments (department_name) VALUES ('Finance');

INSERT INTO app_user_roles (username, role_code)
VALUES (UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER')), 'HR_ADMIN');

INSERT INTO app_user_roles (username, role_code)
VALUES (UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER')), 'PAYROLL');

INSERT INTO app_user_roles (username, role_code)
VALUES (UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER')), 'MANAGER');

COMMIT;
