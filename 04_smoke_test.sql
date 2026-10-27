DECLARE
    v_employee_id NUMBER;
    v_payroll_run_id NUMBER;
    v_department_id NUMBER;
    v_period_start DATE := TRUNC(ADD_MONTHS(SYSDATE, -1), 'MM');
    v_work_date DATE;
    v_cursor SYS_REFCURSOR;
    v_employee_number VARCHAR2(30);
    v_first_name VARCHAR2(80);
    v_last_name VARCHAR2(80);
    v_payslip_period_start DATE;
    v_eligible_days NUMBER;
    v_working_days NUMBER;
    v_base_pay NUMBER;
    v_overtime_pay NUMBER;
    v_bonus NUMBER;
    v_deductions NUMBER;
    v_net_pay NUMBER;
BEGIN
    SAVEPOINT ems_smoke_test;

    INSERT INTO departments (department_name)
    VALUES ('EMS Test Department');

    SELECT department_id
      INTO v_department_id
      FROM departments
     WHERE department_name = 'EMS Test Department';

    SELECT MIN(work_day)
      INTO v_work_date
      FROM (
          SELECT v_period_start + LEVEL - 1 AS work_day
            FROM dual
          CONNECT BY LEVEL <= LAST_DAY(v_period_start) - v_period_start + 1
      )
     WHERE TO_CHAR(work_day, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH') NOT IN ('SAT', 'SUN');

    ems_api.add_employee(
        p_employee_number => 'EMS-TEST-001',
        p_first_name => 'Test',
        p_last_name => 'Employee',
        p_email => 'ems-test-001@example.invalid',
        p_department_id => v_department_id,
        p_job_title => 'Analyst',
        p_monthly_salary => 3000,
        p_employee_id => v_employee_id,
        p_login_name => UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER')),
        p_hire_date => v_period_start
    );

    ems_api.clock_in(v_employee_id, v_work_date + 9 / 24);
    ems_api.clock_out(v_employee_id, v_work_date + 18 / 24);
    ems_api.add_payroll_adjustment(
        v_employee_id, v_period_start, 'BONUS', 100, 'Smoke test bonus'
    );
    ems_api.run_payroll(v_period_start, v_payroll_run_id);
    ems_api.generate_payslip(v_employee_id, v_period_start, v_cursor);

    FETCH v_cursor INTO v_employee_number, v_first_name, v_last_name,
        v_payslip_period_start, v_eligible_days, v_working_days, v_base_pay,
        v_overtime_pay, v_bonus, v_deductions, v_net_pay;

    IF v_employee_number <> 'EMS-TEST-001' OR v_bonus <> 100 OR v_net_pay <= 0 THEN
        RAISE_APPLICATION_ERROR(-20100, 'Payroll smoke test failed.');
    END IF;

    CLOSE v_cursor;
    ROLLBACK TO ems_smoke_test;
    DBMS_OUTPUT.PUT_LINE('EMS smoke test passed.');
EXCEPTION
    WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
        END IF;
        ROLLBACK TO ems_smoke_test;
        RAISE;
END;
/
