# Employee Management System (Oracle PL/SQL)

Database-only starter for Oracle FreeSQL / Oracle Database 26ai. It implements
employee records, attendance, leave approvals, monthly payroll and payslips,
salary advances, performance reviews, and role checks in PL/SQL packages.

## Run in FreeSQL

Create a new SQL worksheet in your Oracle schema and run these scripts in order:

1. `01_schema.sql`
2. `02_security.sql`
3. `03_ems_api.sql`
4. `04_sample_data.sql`
5. `05_smoke_test.sql` (optional; rolls back its test records)

The schema owner needs permission to create tables, views, indexes, and PL/SQL
packages. Run each file as a script so the `/` package terminators are handled.
If rerunning a script, drop its existing objects first; the setup is not an
automatic migration.

## Security model

Oracle database authentication remains the authentication mechanism; this
project does not store passwords. `app_user_roles` maps the authenticated
Oracle session username to application roles: `HR_ADMIN`, `EMPLOYEE`,
`MANAGER`, or `PAYROLL`. The sample data grants the current schema user the
three administrative roles so the smoke test can run.

For a real deployment, create separate Oracle users and have a DBA provision
their `app_user_roles` rows. Grant application users `EXECUTE` on the packages,
not direct DML on protected tables; protect role mapping changes as DBA-only
administration. The package checks roles on each operation, and employee
self-service operations additionally check the employee's `login_name`.
`MANAGER` currently grants manager-wide report and approval access; add
department/manager hierarchy checks before using it in production.
Keep encryption at rest enabled through Oracle Transparent Data Encryption (TDE)
or the deployment's equivalent; this starter does not configure encryption
keys. Package operations use static SQL and bind parameters rather than
constructing SQL from user input.

## Business rules

- Attendance permits one daily clock-in/clock-out record per employee.
- Payroll counts Monday-Friday workdays (no holiday calendar), prorates monthly
  salary by eligible workdays (attended days plus approved paid-leave days),
  excluding weekdays before the employee's hire date. It adds overtime above
  eight hours per recorded day at 1.5 times the salary-derived hourly rate and
  applies period bonuses, deductions, and approved advances.
- Payroll rejects a run if deductions exceed gross pay. An employee must have
  attendance or approved paid leave for a day to receive prorated base pay.
- Payroll runs are restricted to closed months; schedule a run after month-end.
- Employee removal is a soft termination so historical records remain intact.

## API overview

Call procedures using named arguments in the `ems_api` package. For example:

```sql
DECLARE
    v_employee_id NUMBER;
BEGIN
    ems_api.add_employee(
        p_employee_number => 'E-1001',
        p_first_name => 'Ari',
        p_last_name => 'Patel',
        p_email => 'ari.patel@example.com',
        p_department_id => 2,
        p_job_title => 'Developer',
        p_monthly_salary => 6500,
        p_employee_id => v_employee_id,
        p_login_name => 'ARI.PATEL'
    );
    DBMS_OUTPUT.PUT_LINE('Created employee ' || v_employee_id);
END;
/
```

Search, payslip, and performance report procedures return `SYS_REFCURSOR`
results for the client to fetch. `attendance_summary` provides monthly recorded
hours and overtime; `employee_directory` provides employee search fields.

Use the bundled smoke test to verify package compilation and a basic
employee-to-payroll flow. The scripts have not been connected to a web
application; invoke the package through an Oracle client or a separately
configured REST/API layer.
