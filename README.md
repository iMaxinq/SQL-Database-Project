# SQL Database Project

A Java Swing desktop application backed by MySQL for managing a recruitment and job-application database. The project combines a relational schema, triggers, stored procedures, and a simple GUI with separate flows for administrators and employee users.

## Overview

This project models a hiring platform where:

- **admins** manage the database through a GUI
- **employees/candidates** browse jobs and manage their applications
- **evaluators** are assigned to job postings and participate in applicant grading
- the database tracks:
  - users and roles
  - companies
  - jobs
  - applicants
  - qualifications
  - applications
  - completed application history
  - audit logs

The repository contains both:

- a large **MySQL schema/script** with tables, constraints, triggers, indexes, and stored procedures
- a **Java Swing client** that connects to the database and exposes the main workflows

## Repository Structure

```text
SQL-Database-Project/
├── database.sql
├── report.pdf
└── src/
    ├── Main.java
    ├── login.java
    ├── DBHandler.java
    ├── Insert.java
    ├── Update.java
    ├── userHandler.java
    ├── *.form
    ├── admin.png
    ├── user.png
    └── login.png
