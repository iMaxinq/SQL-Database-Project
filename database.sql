########################################    CREATE    ########################################
DROP DATABASE IF EXISTS Project1;

CREATE DATABASE IF NOT EXISTS Project1;

USE Project1;

CREATE TABLE user 
(
  username VARCHAR(30) NOT NULL,
  password VARCHAR(20) NOT NULL,
  name VARCHAR(25) NOT NULL,
  lastname VARCHAR(35) NOT NULL,
  reg_date DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
  email VARCHAR(30) NOT NULL,
  CONSTRAINT user_pk PRIMARY KEY (username)
);

CREATE TABLE admins
(
    username VARCHAR(30) NOT NULL,
    start_date DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    end_date DATE,
    CONSTRAINT admin_pk PRIMARY KEY (username),
    CONSTRAINT admin_user_fk FOREIGN KEY (username) REFERENCES user(username)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE log
(
    id INT AUTO_INCREMENT,
    user VARCHAR(30) NOT NULL,
    action VARCHAR(10) NOT NULL,
    changes VARCHAR(255) NOT NULL,
    stamp DATETIME NOT NULL,
    CONSTRAINT log_pk PRIMARY KEY (id)
);

CREATE TABLE etairia
(
    AFM CHAR(9) NOT NULL,
    DOY VARCHAR(30) NOT NULL,
    name VARCHAR(35) NOT NULL,
    tel VARCHAR(10) NOT NULL,
    street VARCHAR(15) NOT NULL,
    num INT(11) NOT NULL,
    city VARCHAR(45) NOT NULL,
    country VARCHAR(15) NOT NULL,
    CONSTRAINT etairia_pk PRIMARY KEY (AFM)
);

CREATE TABLE evaluator
(
	username VARCHAR(30) NOT NULL,
    exp_years TINYINT(4) NOT NULL DEFAULT '0',
    firm CHAR(9) NOT NULL,
    CONSTRAINT  eval_pk PRIMARY KEY (username),
    CONSTRAINT  eval_user_fk FOREIGN KEY (username) REFERENCES user(username)
    ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT  eval_firm_fk FOREIGN KEY (firm) REFERENCES etairia(AFM)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE employee
(
	username VARCHAR(30) NOT NULL,
	bio TEXT,
	sistatikes VARCHAR(35) DEFAULT 'unknown',
	certificates VARCHAR(35) DEFAULT 'unknown',
    CONSTRAINT  employee_pk PRIMARY KEY (username),
    CONSTRAINT  employee_user_fk FOREIGN KEY (username) REFERENCES user(username)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE languages
(
	candid VARCHAR(30) NOT NULL,
    lang SET('EN','FR','SP','GE','CH','GR') NOT NULL,
    CONSTRAINT lang_pk PRIMARY KEY (candid,lang),
    CONSTRAINT lang_fk FOREIGN KEY (candid) REFERENCES employee(username)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE project
(
	candid VARCHAR(30) NOT NULL,
    num TINYINT(4) NOT NULL,
    descr TEXT NOT NULL,
	url VARCHAR(60) DEFAULT 'unknown',
    CONSTRAINT project_pk PRIMARY KEY (candid,num),
    CONSTRAINT project_fk FOREIGN KEY (candid) REFERENCES employee(username)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE job
(
	id INT(11) NOT NULL AUTO_INCREMENT, 
    start_date DATE NOT NULL,
    salary FLOAT NOT NULL,
    position VARCHAR(60) NOT NULL,
    edra VARCHAR(60) NOT NULL,
    evaluator VARCHAR(30) NOT NULL,
    grader1 VARCHAR(30),
    grader2 VARCHAR(30),
    announce_date DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    submission_date DATE AS (DATE_SUB(start_date,INTERVAL 15 DAY)) NOT NULL,
    cancellation_deadline DATE AS (DATE_SUB(start_date,INTERVAL 10 DAY)) NOT NULL,
    CONSTRAINT job_pk PRIMARY KEY (id),
    CONSTRAINT job_eval_fk FOREIGN KEY (evaluator) REFERENCES evaluator(username)
    ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT job_grader1_fk FOREIGN KEY (grader1) REFERENCES evaluator(username)
    ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT job_grader2_fk FOREIGN KEY (grader2) REFERENCES evaluator(username)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE subject
(
	title VARCHAR(36) NOT NULL,
    descr TINYTEXT,
    belongs_to VARCHAR(36) DEFAULT 'none',
    CONSTRAINT subject_pk PRIMARY KEY (title),
    CONSTRAINT req_self_fk FOREIGN KEY (belongs_to) REFERENCES subject(title)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE requires
(
	job_id INT(11) NOT NULL,
    subject_title VARCHAR(36) NOT NULL,
    CONSTRAINT req_pk PRIMARY KEY(job_id,subject_title),
    CONSTRAINT req_job_fk FOREIGN KEY (job_id) REFERENCES job(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT req_subj_fk FOREIGN KEY (subject_title) REFERENCES subject(title)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE applies
(
	cand_usrname VARCHAR(30) NOT NULL,
    job_id INT(11) NOT NULL,
    appl_state ENUM('Active','Cancelled') DEFAULT 'Active' NOT NULL,
    appl_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    grade1 TINYINT(4),
    grade2 TINYINT(4),
    CONSTRAINT chk_grade1 CHECK (grade1 between 1 and 20),
    CONSTRAINT chk_grade2 CHECK (grade2 between 1 and 20),
    CONSTRAINT appl_pk PRIMARY KEY (cand_usrname,job_id),
    CONSTRAINT appl_employee_fk FOREIGN KEY (cand_usrname) REFERENCES employee(username)
    ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT appl_job_fk FOREIGN KEY (job_id) REFERENCES job(id)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE application_history
(
    grader1 VARCHAR(30) NOT NULL,
    grader2 VARCHAR(30) NOT NULL,
    cand_usrname VARCHAR(30) NOT NULL,
    job_id INT(11) NOT NULL,
    appl_state VARCHAR(20) DEFAULT 'Completed' NOT NULL,
    final_grade FLOAT NOT NULL,
    CONSTRAINT appl_history_pk PRIMARY KEY (cand_usrname,job_id),
    CONSTRAINT chk_grade CHECK (final_grade between 0 and 20)
);    

CREATE TABLE degree
(
	titlos VARCHAR(150) NOT NULL,
    idryma VARCHAR(150) NOT NULL,
    bathmida ENUM('BSc','MSc','PhD') NOT NULL,
    CONSTRAINT deg_pk PRIMARY KEY (titlos,idryma)
);

CREATE TABLE has_degree
(
	degr_title VARCHAR(150) NOT NULL,
    degr_idryma VARCHAR(140) NOT NULL,
    cand_usrname VARCHAR(30) NOT NULL,
    etos YEAR(4) NOT NULL,
    grade FLOAT NOT NULL,
    CONSTRAINT has_deg_pk PRIMARY KEY (degr_title,degr_idryma,cand_usrname),
    CONSTRAINT has_deg_deg_fk FOREIGN KEY (degr_title,degr_idryma) REFERENCES degree(titlos,idryma)
    ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT has_deg_employee_fk FOREIGN KEY (cand_usrname) REFERENCES employee(username)
    ON DELETE CASCADE ON UPDATE CASCADE
);

########################################    TRIGGERS    ########################################
DROP TRIGGER IF EXISTS degrees_trig;

DELIMITER $
CREATE TRIGGER IF NOT EXISTS degrees_trig  BEFORE INSERT ON has_degree
FOR EACH ROW
BEGIN
    
    IF NOT EXISTS (SELECT 1 FROM degree WHERE titlos = NEW.degr_title AND idryma = NEW.degr_idryma) THEN
        
        INSERT INTO degree(titlos,idryma,bathmida)
        VALUES(NEW.degr_title,NEW.degr_idryma,'BSc');
    END IF;

END$

DELIMITER ;


DROP TRIGGER IF EXISTS projectNumAutoIncrement;


DELIMITER $$
CREATE TRIGGER IF NOT EXISTS projectNumAutoIncrement BEFORE INSERT ON project
FOR EACH ROW
BEGIN
    DECLARE maxNum TINYINT(4);
    SELECT MAX(num) FROM project WHERE candid = NEW.candid INTO maxNum;
    SET NEW.num = IF(ISNULL(maxNum), 1, maxNum + 1);
END$$

DELIMITER ;

#################     JOB INSERT       ##########################
DROP TRIGGER IF EXISTS log_job_in_trig;
DELIMITER $
CREATE TRIGGER IF NOT EXISTS log_job_in_trig  AFTER INSERT ON job
FOR EACH ROW
BEGIN
    DECLARE changes VARCHAR(255);
    SET changes = CONCAT(NEW.id,', ',
                         NEW.start_date,', ',
                         NEW.salary,', ',
                         NEW.position,', ',
                         NEW.edra,', ',
                         NEW.evaluator); 

    INSERT INTO log(user,action,changes,stamp)
    VALUES(CURRENT_USER(),'INSERT',changes,CURRENT_TIMESTAMP);
END$

DELIMITER ;

#################     JOB UPDATE       ##########################
DROP TRIGGER IF EXISTS log_job_up_trig;

DELIMITER $
CREATE TRIGGER IF NOT EXISTS log_job_up_trig  AFTER UPDATE ON job
FOR EACH ROW
BEGIN
    DECLARE changes VARCHAR(255);
    SET changes = CONCAT('Old: ',
                         OLD.id,', ',
                         OLD.start_date,', ',
                         OLD.salary,', ',
                         OLD.position,', ',
                         OLD.edra,', ',
                         OLD.evaluator); 

    INSERT INTO log(user,action,changes,stamp)
    VALUES(CURRENT_USER(),'UPDATE',changes,CURRENT_TIMESTAMP);

    SET changes = CONCAT('New: ',
                         NEW.id,', ',
                         NEW.start_date,', ',
                         NEW.salary,', ',
                         NEW.position,', ',
                         NEW.edra,', ',
                         NEW.evaluator); 

    INSERT INTO log(user,action,changes,stamp)
    VALUES(CURRENT_USER(),'UPDATE',changes,CURRENT_TIMESTAMP);
END$

DELIMITER ;

#################     JOB DELETE       ##########################
DROP TRIGGER IF EXISTS log_job_del_trig;

DELIMITER $
CREATE TRIGGER IF NOT EXISTS log_job_del_trig  AFTER DELETE ON job
FOR EACH ROW
BEGIN
    DECLARE changes VARCHAR(255);
    SET changes = CONCAT(OLD.id,', ',
                         OLD.start_date,', ',
                         OLD.salary,', ',
                         OLD.position,', ',
                         OLD.edra,', ',
                         OLD.evaluator); 

    INSERT INTO log(user,action,changes,stamp)
    VALUES(CURRENT_USER(),'DELETE',changes,CURRENT_TIMESTAMP);
END$

DELIMITER ;
#################     USER INSERT       ##########################
DROP TRIGGER IF EXISTS log_user_in_trig;

DELIMITER $
CREATE TRIGGER IF NOT EXISTS log_user_in_trig  AFTER INSERT ON user
FOR EACH ROW
BEGIN
    DECLARE changes VARCHAR(255);
    SET changes = CONCAT(NEW.username,', ',
                         NEW.password,', ',
                         NEW.name,', ',
                         NEW.lastname,', ',
                         NEW.email); 

    INSERT INTO log(user,action,changes,stamp)
    VALUES(CURRENT_USER(),'INSERT',changes,CURRENT_TIMESTAMP);
END$

DELIMITER ;

#################     USER UPDATE       ##########################
DROP TRIGGER IF EXISTS log_user_up_trig;

DELIMITER $
CREATE TRIGGER IF NOT EXISTS log_user_up_trig  AFTER UPDATE ON user
FOR EACH ROW
BEGIN
    DECLARE changes VARCHAR(255);
    SET changes = CONCAT('Old: ',
                         OLD.username,', ',
                         OLD.password,', ',
                         OLD.name,', ',
                         OLD.lastname,', ',
                         OLD.email); 

    INSERT INTO log(user,action,changes,stamp)
    VALUES(CURRENT_USER(),'UPDATE',changes,CURRENT_TIMESTAMP);

    SET changes = CONCAT('New: ',
                         NEW.username,', ',
                         NEW.password,', ',
                         NEW.name,', ',
                         NEW.lastname,', ',
                         NEW.email);

    INSERT INTO log(user,action,changes,stamp)
    VALUES(CURRENT_USER(),'UPDATE',changes,CURRENT_TIMESTAMP);
END$

DELIMITER ;

#################     USER DELETE       ##########################
DROP TRIGGER IF EXISTS log_user_del_trig;

DELIMITER $
CREATE TRIGGER IF NOT EXISTS log_user_del_trig  AFTER DELETE ON user
FOR EACH ROW
BEGIN
    DECLARE changes VARCHAR(255);
    SET changes = CONCAT(OLD.username,', ',
                         OLD.password,', ',
                         OLD.name,', ',
                         OLD.lastname,', ',
                         OLD.email); 

    INSERT INTO log(user,action,changes,stamp)
    VALUES(CURRENT_USER(),'DELETE',changes,CURRENT_TIMESTAMP);
END$

DELIMITER ;

#################     DEGREE INSERT       ##########################
DROP TRIGGER IF EXISTS log_degree_in_trig;

DELIMITER $
CREATE TRIGGER IF NOT EXISTS log_degree_in_trig  AFTER INSERT ON degree
FOR EACH ROW
BEGIN
    DECLARE changes VARCHAR(255);
    SET changes = CONCAT(NEW.titlos,', ',
                         NEW.idryma,', ',
                         NEW.bathmida); 

    INSERT INTO log(user,action,changes,stamp)
    VALUES(CURRENT_USER(),'INSERT',changes,CURRENT_TIMESTAMP);
END$

DELIMITER ;

#################     DEGREE UPDATE       ##########################
DROP TRIGGER IF EXISTS log_degree_up_trig;

DELIMITER $
CREATE TRIGGER IF NOT EXISTS log_degree_up_trig  AFTER UPDATE ON degree
FOR EACH ROW
BEGIN
    DECLARE changes VARCHAR(255);
    SET changes = CONCAT('Old: ',
                         OLD.titlos,', ',
                         OLD.idryma,', ',
                         OLD.bathmida); 

    INSERT INTO log(user,action,changes,stamp)
    VALUES(CURRENT_USER(),'UPDATE',changes,CURRENT_TIMESTAMP);

    SET changes = CONCAT('New: ',
                         NEW.titlos,', ',
                         NEW.idryma,', ',
                         NEW.bathmida);

    INSERT INTO log(user,action,changes,stamp)
    VALUES(CURRENT_USER(),'UPDATE',changes,CURRENT_TIMESTAMP);
END$

DELIMITER ;

#################     DEGREE DELETE       ##########################
DROP TRIGGER IF EXISTS log_degree_del_trig;

DELIMITER $
CREATE TRIGGER IF NOT EXISTS log_degree_del_trig  AFTER DELETE ON degree
FOR EACH ROW
BEGIN
    DECLARE changes VARCHAR(255);
    SET changes = CONCAT(OLD.titlos,', ',
                         OLD.idryma,', ',
                         OLD.bathmida); 

    INSERT INTO log(user,action,changes,stamp)
    VALUES(CURRENT_USER(),'DELETE',changes,CURRENT_TIMESTAMP);
END$

DELIMITER ;


DROP TRIGGER IF EXISTS applies_in_trig;

DELIMITER $
CREATE TRIGGER IF NOT EXISTS applies_in_trig  BEFORE INSERT ON applies
FOR EACH ROW
BEGIN
    DECLARE submission_date DATE;
    DECLARE active_applications TINYINT(1);
    
    ########    sub_date    ########
    SELECT job.submission_date INTO submission_date
    FROM job
    WHERE job.id = NEW.job_id;

    IF CURRENT_DATE > submission_date THEN # CURRENT_DATE is the date an applicant attempts to apply
        SIGNAL SQLSTATE VALUE '45000'
        SET MESSAGE_TEXT = 'Application date too close to job start date.';
    END IF;

    ########    cand active applications    ########
    SELECT count(appl_state) INTO active_applications 
    FROM applies
    WHERE appl_state = 'Active' AND cand_usrname = NEW.cand_usrname;

    IF active_applications = 3 THEN 
        SIGNAL SQLSTATE VALUE '45000'
        SET MESSAGE_TEXT = 'Applicant already has three active applications.';
    END IF;
END$

DELIMITER ;

DROP TRIGGER IF EXISTS applies_cancel_trig;

DELIMITER $
CREATE TRIGGER IF NOT EXISTS applies_cancel_trig  BEFORE UPDATE ON applies
FOR EACH ROW
BEGIN

    DECLARE cancellation_deadline DATE;
    DECLARE active_applications TINYINT(1);

    IF NEW.appl_state = 'Cancelled' THEN

        ########    cancel_date    ########
        SELECT job.cancellation_deadline INTO cancellation_deadline
        FROM job
        WHERE job.id = NEW.job_id;

        IF CURRENT_DATE > cancellation_deadline THEN # CURRENT_DATE is the date an applicant attempts to cancel
            SIGNAL SQLSTATE VALUE '45000'
            SET MESSAGE_TEXT = 'Cancelation date too close to job start date.';
        END IF;
    END IF;

    IF NEW.appl_state = 'Active' AND OLD.appl_state = 'Cancelled' THEN

        ########    cand active applications    ########
        SELECT count(appl_state) INTO active_applications 
        FROM applies
        WHERE appl_state = 'Active' AND cand_usrname = NEW.cand_usrname;

        IF active_applications = 3 THEN 
            SIGNAL SQLSTATE VALUE '45000'
            SET MESSAGE_TEXT = 'Applicant already has three active applications.';
        END IF;
    END IF;
END$

DELIMITER ;
########################################    PROCEDURES    ########################################
DROP PROCEDURE IF EXISTS calcGrade;
DELIMITER $$
CREATE PROCEDURE calcGrade(IN eval_username_par VARCHAR(30), IN empl_username_par VARCHAR(30), IN job_parameter  INT, OUT grade_parameter INT)
BEGIN
    DECLARE known_languages VARCHAR(30);
    DECLARE project_count TINYINT;
    DECLARE bsc_count TINYINT(4);
    DECLARE msc_count TINYINT(4);
    DECLARE phd_count TINYINT(4);

    SELECT MAX(num) INTO project_count
    FROM job INNER JOIN applies ON job.id=applies.job_id INNER JOIN employee ON applies.cand_usrname=employee.username INNER JOIN
    project ON employee.username=project.candid 
    WHERE job_parameter=applies.job_id AND (eval_username_par=job.grader1 OR eval_username_par=job.grader2) AND empl_username_par=applies.cand_usrname;

    SELECT lang INTO known_languages
    FROM job INNER JOIN applies ON job.id=applies.job_id INNER JOIN employee ON applies.cand_usrname=employee.username INNER JOIN
    languages ON employee.username=languages.candid 
    WHERE job_parameter=applies.job_id AND (eval_username_par=job.grader1 OR eval_username_par=job.grader2) AND empl_username_par=applies.cand_usrname;

    SELECT COUNT(bathmida) INTO bsc_count
    FROM job INNER JOIN applies ON job.id=applies.job_id INNER JOIN employee ON applies.cand_usrname=employee.username
    INNER JOIN has_degree ON employee.username=has_degree.cand_usrname INNER JOIN degree ON has_degree.degr_title=degree.titlos AND has_degree.degr_idryma=degree.idryma
    WHERE job_parameter=applies.job_id AND (eval_username_par=job.grader1 OR eval_username_par=job.grader2) AND 
    empl_username_par=applies.cand_usrname AND degree.bathmida='BSc'
    GROUP BY bathmida;

    SELECT COUNT(bathmida) INTO msc_count
    FROM job INNER JOIN applies ON job.id=applies.job_id INNER JOIN employee ON applies.cand_usrname=employee.username
    INNER JOIN has_degree ON employee.username=has_degree.cand_usrname INNER JOIN degree ON has_degree.degr_title=degree.titlos AND has_degree.degr_idryma=degree.idryma
    WHERE job_parameter=applies.job_id AND (eval_username_par=job.grader1 OR eval_username_par=job.grader2) AND 
    empl_username_par=applies.cand_usrname AND degree.bathmida='MSc'
    GROUP BY bathmida;  

    SELECT COUNT(bathmida) INTO phd_count
    FROM job INNER JOIN applies ON job.id=applies.job_id INNER JOIN employee ON applies.cand_usrname=employee.username
    INNER JOIN has_degree ON employee.username=has_degree.cand_usrname INNER JOIN degree ON has_degree.degr_title=degree.titlos AND has_degree.degr_idryma=degree.idryma
    WHERE job_parameter=applies.job_id AND (eval_username_par=job.grader1 OR eval_username_par=job.grader2) AND 
    empl_username_par=applies.cand_usrname AND degree.bathmida='PhD'
    GROUP BY bathmida;

    IF (INSTR(known_languages,',')>0) THEN
        SET grade_parameter=IFNULL(project_count,0)+IFNULL(bsc_count,0)+2*IFNULL(msc_count,0)+3*IFNULL(phd_count,0)+1;
    ELSE 
        SET grade_parameter=IFNULL(project_count,0)+IFNULL(bsc_count,0)+2*IFNULL(msc_count,0)+3*IFNULL(phd_count,0);   
    END IF;    
END $$
DELIMITER ;

######################################################################################################################################################################

DROP PROCEDURE IF EXISTS grading;
DELIMITER $$
CREATE PROCEDURE grading(IN eval_username VARCHAR(30), IN empl_username VARCHAR(30), IN job_param  INT, OUT grade_param INT)
BEGIN
    DECLARE vathmologitis1 VARCHAR(30);
    DECLARE vathmologitis2 VARCHAR(30);
    DECLARE vathmos1 TINYINT(4);
    DECLARE vathmos2 TINYINT(4);

    SELECT grader1,grader2,grade1,grade2 INTO vathmologitis1,vathmologitis2,vathmos1,vathmos2
    FROM job INNER JOIN applies ON job.id=applies.job_id
    WHERE  job_param=applies.job_id AND (eval_username=job.grader1 OR eval_username=job.grader2) AND empl_username=applies.cand_usrname;

    IF (vathmologitis1=eval_username) THEN
        IF (vathmos1 IS NOT NULL) THEN
            SET grade_param=vathmos1;
        ELSE 
            CALL calcGrade(eval_username,empl_username,job_param,grade_param);
        END IF;    

    ELSEIF (vathmologitis2=eval_username) THEN
        IF (vathmos2 IS NOT NULL) THEN
            SET grade_param=vathmos2;
        ELSE 
            CALL calcGrade(eval_username,empl_username,job_param,grade_param);
        END IF;  
    
    ELSE 
        SET grade_param=0;    
    END IF;
END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS applyProcedure;
DELIMITER $
CREATE PROCEDURE applyProcedure(IN p_username VARCHAR(30), IN p_jobID INT, IN charX ENUM('i','c','a'))
BEGIN
	DECLARE temp_grader1 VARCHAR(30);
	DECLARE temp_grader2 VARCHAR(30);
    DECLARE temp_firm VARCHAR(9);
    DECLARE temp_candUsrname VARCHAR(30);
    DECLARE temp_jobID INT;
    DECLARE temp_state VARCHAR(12);
    
    
    CASE charX
        WHEN 'i' THEN
            SELECT grader1,grader2 INTO temp_grader1,temp_grader2
			from employee INNER JOIN applies on employee.username = applies.cand_usrname
            INNER JOIN job ON applies.job_id = job.id
            WHERE p_username = employee.username AND p_jobID = job.id;
            
			IF temp_grader1 IS NULL THEN
				IF temp_grader2 IS NULL THEN
					UPDATE job SET grader1 = 'GiovanniGeorgio' ,grader2 = 'Lenio666' WHERE id=p_jobID;
				ELSE
					SELECT firm into temp_firm
                    FROM evaluator
                    WHERE evaluator.username = temp_grader2;
                    
                    SELECT username INTO temp_grader1
                    FROM evaluator
                    WHERE evaluator.firm = temp_firm AND evaluator.username != temp_grader2
                    LIMIT 1;
                    
                    UPDATE job SET grader1 = temp_grader1 WHERE id=p_jobID;
                END IF;
                
			ELSE
				IF temp_grader2 IS NULL THEN
					SELECT firm into temp_firm
                    FROM evaluator
                    WHERE evaluator.username = temp_grader1;
                    
                    SELECT username INTO temp_grader2
                    FROM evaluator
                    WHERE evaluator.firm = temp_firm AND evaluator.username != temp_grader1
                    LIMIT 1;
                    
                    UPDATE job SET grader2 = temp_grader2 WHERE id=p_jobID;
				END IF;					
            END IF;
		
			INSERT INTO applies(cand_usrname,job_id,appl_state)
            VALUES (p_username,p_jobID,'Active');
            
        WHEN 'c' THEN
			SELECT cand_usrname,job_id INTO temp_candUsrname,temp_jobID
            FROM applies
            WHERE cand_usrname = p_username AND applies.job_id = p_jobID AND appl_state != 'Cancelled';
            
            IF temp_jobID IS NULL THEN
				SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Application doesnt exist or has been cancelled';
			END IF;
            
			UPDATE applies SET appl_state = 'Cancelled' WHERE cand_usrname = temp_candUsrname AND job_id = temp_jobID;
				
            
		WHEN 'a' THEN
			SELECT cand_usrname,job_id INTO temp_candUsrname,temp_jobID
            FROM applies
            WHERE cand_usrname = p_username AND applies.job_id = p_jobID AND appl_state = 'Cancelled';
            
            IF temp_candUsrname IS NOT NULL THEN
				UPDATE applies SET appl_state = 'Active' WHERE cand_usrname = temp_candUsrname AND job_id = temp_jobID;
				SELECT 'Successfully updated application' AS message;
            ELSE
				SIGNAL SQLSTATE '45000'
				SET MESSAGE_TEXT = 'No cancelled application exists';
                
			END IF;
				
    END CASE;
END $
DELIMITER ;


DROP PROCEDURE IF EXISTS fillGrades;
DELIMITER $$
CREATE PROCEDURE fillGrades(IN input_job INT)
BEGIN

    DECLARE finished INT DEFAULT 0;
    DECLARE applicant VARCHAR(30);
    DECLARE evaluator1 VARCHAR(30);
    DECLARE evaluator2 VARCHAR(30);
    DECLARE calculated_grade1 TINYINT(4);
    DECLARE calculated_grade2 TINYINT(4);

    DECLARE cursor_applicants CURSOR FOR 
    SELECT cand_usrname,grader1,grader2
    FROM applies INNER JOIN job ON job.id=applies.job_id
    WHERE applies.job_id=input_job AND applies.appl_state = 'Active' AND (applies.grade1 IS NULL OR applies.grade2 IS NULL);
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND 
    SET finished=1;
    
    OPEN cursor_applicants;
    REPEAT 
    
        FETCH cursor_applicants INTO applicant,evaluator1,evaluator2;
        CALL grading(evaluator1,applicant,input_job,calculated_grade1);
        CALL grading(evaluator2,applicant,input_job,calculated_grade2);

        UPDATE applies
        SET grade1=calculated_grade1, grade2=calculated_grade2
        WHERE cand_usrname=applicant AND job_id=input_job;

    UNTIL finished=1
    END REPEAT;
    CLOSE cursor_applicants;    

END $$
DELIMITER ;

######################################################################################################################################################################

DROP PROCEDURE IF EXISTS findEmployee;
DELIMITER $$
CREATE PROCEDURE findEmployee(IN job_ID INT)
BEGIN

    CALL fillGrades(job_ID);

    SELECT cand_usrname,(grade1+grade2)/2 AS grade 
    FROM applies
    WHERE applies.job_id = job_ID AND applies.appl_state = 'Active'
    ORDER BY grade DESC,appl_date ASC
    LIMIT 1;
    
    INSERT INTO application_history (cand_usrname,grader1,grader2,job_id,final_grade)
        SELECT applies.cand_usrname,job.grader1,job.grader2,applies.job_id,(applies.grade1+applies.grade2)/2
        FROM applies INNER JOIN job ON job.id=applies.job_id
        WHERE applies.job_id=job_ID AND applies.appl_state = 'Active'; 

    INSERT INTO application_history (cand_usrname,grader1,grader2,job_id,final_grade)
        SELECT applies.cand_usrname,job.grader1,job.grader2,applies.job_id,0
        FROM applies INNER JOIN job ON job.id=applies.job_id
        WHERE applies.job_id=job_ID AND applies.appl_state = 'Cancelled';     

    DELETE FROM applies
    WHERE  applies.job_id=job_ID; 

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS gradeRange;

DELIMITER $

CREATE PROCEDURE gradeRange(IN grade1 FLOAT, IN grade2 FLOAT)
BEGIN
    SELECT cand_usrname AS applicant, job_id AS job
    FROM application_history 
    WHERE final_grade BETWEEN grade1 AND grade2;
END$
DELIMITER ;

ALTER TABLE application_history
ADD INDEX grade_idx (final_grade);

######################################################################################################################################################################

DROP PROCEDURE IF EXISTS evaluatedBy;

DELIMITER $

CREATE PROCEDURE evaluatedBy(IN eval_usrname VARCHAR(30))
BEGIN
    SELECT cand_usrname AS applicant, job_id AS job
    FROM application_history
    WHERE grader1 = eval_usrname OR grader2 = eval_usrname;
END$
DELIMITER ;

ALTER TABLE application_history
ADD INDEX grader_idx (grader1,grader2);




-- EXPLAIN SELECT cand_usrname AS applicant, job_id AS job
-- FROM application_history 
-- WHERE final_grade BETWEEN 1 AND 20;

-- EXPLAIN SELECT cand_usrname AS applicant, job_id AS job
-- FROM application_history
-- WHERE grader1 = 'seceval70000' OR grader2 = 'seceval70000';


DROP PROCEDURE IF EXISTS clearTable;

DELIMITER $$
CREATE PROCEDURE IF NOT EXISTS clearTable(IN tableName VARCHAR(20))
BEGIN 
    SET @x = CONCAT('DELETE FROM ',tableName); # Making querie string  
   
    PREPARE stmnt FROM @x;      # Making the string an actual sql querie
    EXECUTE stmnt;              # Executing the querie we made 
    DEALLOCATE PREPARE stmnt;   # Deallocating the memory from the statement we made and executed

END$$
DELIMITER ;


DROP PROCEDURE IF EXISTS clearDB;

DELIMITER $$
CREATE PROCEDURE IF NOT EXISTS clearDB()
BEGIN 
    CALL clearTable('user');
    CALL clearTable('subject');
    CALL clearTable('etairia');
    CALL clearTable('degree');
    CALL clearTable('application_history');
END$$
DELIMITER ;
########################################    INSERT    ########################################
INSERT INTO user(username,password,name,lastname,email)
VALUES('SpirosP','1234','Spiros','Papageorgiou','spiros@users.db'),
	  ('markB','kram','Mark','Burgess','mark@users.db'),
      ('treyE','yert','Trey','Estes','trey@users.db'),
	  ('cordeliaW','ailrdroc','Cordelia','Watts','cordel@users.db'),
      ('wilmaB','amliw','Wilma','Bush','wilma@users.db'),
	  ('anastasiaC','aisatsana','Anastasia','Chan','ana@users.db'),
      ('kellyC','yllek','Kelly','Clayton','kelly@users.db'),
	  ('francW','cnarf','Franciszek','Weaver','franc@users.db'),
      ('ellieF','eille','Ellie','Fuentes','ellie@users.db'),
	  ('claireM','erailc','Claire','Mcgowan','claire@users.db'),
      ('rayS','yar','Ray','Smith','ray@users.db'),
	  ('zachC','hcaz','Zachary','Chandler','zach@users.db')
;

INSERT INTO admins(username)
VALUES('claireM'),
      ('ellieF')
;


INSERT INTO employee(username,bio,sistatikes,certificates)
VALUES('SpirosP',NULL,'sistat_Spiros.pdf','cert_Spiros.pdf'),
	  ('markB',NULL,'sistat_Mark.pdf','cert_Mark.pdf'),
      ('treyE',NULL,'sistat_Trey.pdf','cert_Trey.pdf'),
	  ('cordeliaW',NULL,'sistat_Cord.pdf','cert_Cord.pdf'),
      ('wilmaB',NULL,'sistat_Wil.pdf','cert_Wil.pdf'),
	  ('anastasiaC',NULL,'sistat_Ana.pdf','cert_Ana.pdf')
;


INSERT INTO etairia(AFM,DOY,name,tel,street,num,city,country)
VALUES('a','Patron','et1','1111111111','st1','1','Patra','Greece'),
	  ('b','Athinon','et2','2222222222','st2','2','Athina','Greece'),
      ('c','Thesalonikis','et3','3333333333','st3','3','Thesaloniki','Greece')
;


INSERT INTO evaluator(username,exp_years,firm)
VALUES('kellyC',0,'a'),
	  ('francW',1,'b'),
      ('ellieF',2,'b'),
	  ('claireM',3,'a'),
      ('rayS',4,'c'),
	  ('zachC',5,'c')
;


INSERT INTO degree(titlos,idryma,bathmida)
VALUES('Computer Engineering and informatics','University of Patras','MSc'),
	  ('Electrical Engineering','University of Patras','BSc'),
      ('Law','University of Athens','BSc'),
      ('Mechanical Engineering','University of Patras','PhD'),
      ('Biology','University of Patras','PhD'),
      ('Economics','University of Athens','BSc')
;


INSERT INTO has_degree(degr_title,degr_idryma,cand_usrname,etos,grade)
VALUES('Computer Engineering and informatics','University of Patras','SpirosP',2022,8.5),
	  ('Law','University of Athens','markB',2017,9),
      ('Economics','University of Athens','treyE',2020,7.4),
      ('Mechanical Engineering','University of Patras','cordeliaW',2019,7.6),
      ('Electrical Engineering','University of Patras','anastasiaC',2015,7),
      ('Biology','University of Patras','wilmaB',2021,6.7)
;



INSERT INTO job(start_date,salary,position,edra,evaluator)
VALUES('2024-03-01',3500.0,'Manager','Athens','kellyC'),
	  ('2024-02-23',2200.0,'Researcher','Athens','rayS'),
      ('2024-03-15',1400.0,'Intermediate Software Engineer','Thesaloniki','ellieF'),
	  ('2024-05-14',1500.0,'Intermediate Software Engineer','Thesaloniki','francW'),
      ('2024-02-18',1400.0,'Junior Software Engineer','Patra','claireM'),
	  ('2024-04-23',1200.0,'Junior Software Engineer','Athens','zachC'),
      ('2024-04-01',2700.0,'Assistant Attorney','Athens','zachC'),
	  ('2024-06-01',1000.0,'Internship','Patra','zachC')
;

INSERT INTO applies(cand_usrname,job_id,appl_state)
VALUES('SpirosP',1,'Active'),
	  ('SpirosP',3,'Cancelled'),
      ('SpirosP',4,'Active'),
	  ('markB',7,'Cancelled'),
      ('cordeliaW',8,'Active'),
	  ('wilmaB',5,'Cancelled'), 
      ('wilmaB',2,'Active')
;


INSERT INTO languages(candid,lang)
VALUES('treyE','GR,EN,FR'),
	  ('cordeliaW','GR,EN'),
      ('wilmaB','GR,EN,SP,GE'),
	  ('anastasiaC','GR,EN,CH')
;


INSERT INTO project(candid,descr,url)
VALUES('SpirosP',"Created a database for hotel reservations.","www.github.com/SpirosP/code/"),
	  ('SpirosP',"A ML application to predict the weather.","www.github.com/SpirosP/code/"),
      ('markB',"Participated in trial for human rights violations","www.github.com/markB/code/"),
	  ('treyE',"Mathematical predictions for stock prices.","www.github.com/treyE/code/"),
      ('cordeliaW',"Design of a small turbine engine in colaboration with ESA.","www.github.com/cordeliaW/code/"),
	  ('treyE',"Statistical analysis of investments for AlphaBank.","www.github.com/treyE/code/"),
      ('anastasiaC',"Research on local fauna","www.github.com/anastasiaC/code/")
;


INSERT INTO subject(title,descr,belongs_to)
VALUES('Computer Engineering',"Hardware and Software",NULL),
      ('Database Programming',"Principles of Database design and use.",'Computer Engineering'),
      ('DML'," Data manipulation languages are computer programming languages used for inserting,
				deleting, and updating data in a database.An example is SQL language",'Database Programming'),
      
      ('Computer Architecture',"Configuration of computer hardware.",'Computer Engineering'),
      ('HDL',"Hardware description language to design digital logic.",'Computer Architecture'),
      
      ('Mechanical Engineering',"Mechanical and aerospace engineering",NULL),
      ('Fluid Mechanics',"the study of fluid behavior at rest and in motion. Fluid mechanics has a wide range
			of applications in mechanical and chemical engineering, in biological systems, and in astrophysics.",'Mechanical Engineering'),
	  
      ('Artificial Intelligence',"Efficient algorithms used in multiple applications",'Computer Engineering'),
      ('Machine  Learning',"A part of artificial intelligence used to teach computers to do what comes naturally to humans",'Artificial Intelligence'),
	  
      ('Law',"Greek Law",NULL),
      ('International Law',"Set of rules, norms, and standards generally recognized as binding between states. It establishes
			norms for states across a broad range of domains, including war and diplomacy, economic relations, and human rights.",'Law')
;

            
INSERT INTO requires(job_id,subject_title)
VALUES(7,'International Law'),
	  (1,'Computer Architecture'),
      (2,'Machine  Learning'),
	  (3,'Database Programming'),
      (4,'Database Programming'),
	  (5,'HDL'),
      (6,'HDL'),
	  (8,'Fluid Mechanics')
;


INSERT INTO user(username,password,name,lastname,email)
VALUES
      ('kostas791','hallaw','Kostas','Papaspyrou','olikostas@gmail.com'),
      ('Thanos','tzeleOE','Thanasis','Tzampatzis','thanasis2003@gmail.com'),
      ('Trakis','trakis190','Dimitris','Giannakopoylos','zaxari@gmail.com'),
      ('t0p','akyro','Andreas','Tatsopoulos','notAndrew@gmail.com'),
      ('Tsosbo','League','Argyris','Koutalas','koutalas@gmail.com'),
      ('bigMAN','gunned','Stefanos','Xios','pstSipsas@gmail.com'),
      ('megalos','alphaskasi','Thanos','Mikroutsikos','mikroutsikos@gmail.com'),
      ('PROEDROS','marevaAGAPIMOU','Kyriakos','Mitsotakis','kommaPasisEllados@gmail.com'),
      ('Partakias','Dhmosio','Nikos','Androulakis','epidomaYparksis@gmail.com'),
      ('BROEDROS','mercedesBENZ','Aleksis','Tsipras','strofi360moires@gmail.com'),
      ('random1','random12','Panagiotis','Alafaouzeos','trifuli@gmail.com'),
      ('random2','random22','Antonis','Petrou','arsak@gmail.com');

INSERT INTO admins(username)
VALUES
      ('kostas791'),
      ('PROEDROS');


INSERT INTO employee(username,bio,sistatikes,certificates)
VALUES
      ('Partakias',NULL,'sistat_Partakias.pdf','cert_Partakias.pdf'),
      ('Thanos',NULL,'sistat_Thanos.pdf','cert_Thanos.pdf'),
      ('BROEDROS',NULL,'sistat_BROEDROS.pdf','cert_BROEDROS.pdf'),
      ('megalos',NULL,'sistat_megalos.pdf','cert_megalos.pdf'),
      ('bigMAN',NULL,'sistat_bigMAN.pdf','cert_Tsosbo.pdf'),
      ('random1',NULL,'sistat_random1.pdf','cert_random1.pdf');


INSERT INTO etairia(AFM,DOY,name,tel,street,num,city,country)
VALUES
      ('d','Metsobou','et4','4444444444','st4','4','Metsobo','Greece'),
      ('e','Artas','et5','5555555555','st5','5','Arta','Greece'),
      ('f','Trikalwn','et6','6666666666','st6','6','Trikala','Greece');


INSERT INTO evaluator(username,exp_years,firm)
VALUES
      ('kostas791',9,'d'),
      ('PROEDROS',9,'f'),
      ('t0p',2,'e'),
      ('Trakis',4,'f'),
      ('TSOSBO',0,'d'),
      ('random2',3,'e');


INSERT INTO degree(titlos,idryma,bathmida)
VALUES
		('Filologos','University of Athens','BSc'),
		('Mousikis','University of Patras','BSc'),
		('Cryptography','University of Athens','PhD'),
		('Iatriki','University of Patras','BSc'),
        ('Nosileutiki','University of Athens','BSc'),
        ('Fysiki','University of Patras','PhD');


INSERT INTO has_degree(degr_title,degr_idryma,cand_usrname,etos,grade)
VALUES
      ('Filologos','University of Athens','Partakias',2021,6),
      ('Mousikis','University of Patras','Thanos',2018,9),
      ('Cryptography','University of Athens','BROEDROS',2020,10),
	  ('Fysiki','University of Patras','random1',2023,7);


INSERT INTO job(start_date,salary,position,edra,evaluator)
VALUES
      ('2024-04-12','2300.0','Mousikos se sxoleio','Patra','kostas791'),
      ('2024-05-11','2100.0','Filologos se sxoleio','Patra','PROEDROS'),
      ('2024-06-09','4100.0','Kathigitis Kryptografias','Athens','t0p'),
      ('2024-07-28','700.0','Mousikos se sxoleio','Thesaloniki','Trakis'),
      ('2024-08-29','1000.0','Analytis keimenwn','Patra','TSOSBO'),
      ('2024-10-12','800.0','Fysikos se sxoleio','Athens','random2'),
      ('2024-11-07','750.0','Fysikos se frontistirio','Patra','t0p'),
      ('2024-08-16','950.0','Cybersecutiry engineer','Thesaloniki','kostas791');

INSERT INTO applies(cand_usrname,job_id,appl_state)
VALUES
      ('Partakias',9,'Active'),
      ('BROEDROS',11,'Active'),
      ('megalos',12,'Cancelled'),
      ('Thanos',10,'Active'),
      ('bigMAN',13,'Active'),
      ('Thanos',14,'Cancelled'),
      ('Partakias',15,'Active'),
      ('BROEDROS',16,'Active'),
      ('megalos',9,'Cancelled');


INSERT INTO languages(candid,lang)
VALUES
      ('Partakias','GR,EN'),
      ('Thanos','GR,FR'),
      ('megalos','GR'),
      ('BROEDROS','GR,EN,GE');


INSERT INTO project(candid,descr,url)
VALUES
      ('Partakias',"Kati me ypologistes","github.com/Partakias/"),
      ('BROEDROS',"Kati me mousiki","mousiki.gr/BROEDROS/"),
      ('Thanos',"Graphic Design kai tetoia","thanossite.gr/thanos/"),
      ('megalos',"Pos na ftiakseis ton teleio kafe","Kilimanjaro.gr/megalos"),
      ('bigMAN',"Advanced pliroforiaka systimata","ceid.gr/bigMAN/"),
      ('Partakias',"Made a pentesting tool","github.com/kostas791/"),
      ('BROEDROS',"Made a C library","github.com/kostas791/");


INSERT INTO subject(title,descr,belongs_to)
VALUES
    ('Music','Na kserei na paizei ena organo',NULL),
    ('Literature','Na kserei na kanei analysh keimenou',NULL),
    ('Cryptography','Na kserei tis arxes kryptografias',NULL),
    ('Fysiki','Na kserei na kanei fysiki',NULL),
	('Sxetikotitas','Na kserei theoria sxetikotitas','Fysiki'),
    ('AES','Na kserei pos douleuei o AES','Cryptography'),
    ('Dynameis','Na kserei analysh dynamewn se kinoumeno antikeimeno','Fysiki'),
    ('Keimenografos','Na mporei na kanei diorthosi keimenou','Literature');
            
INSERT INTO requires(job_id,subject_title)
VALUES
      (9,'Music'),
      (10,'Literature'),
      (11,'Cryptography'),
      (12,'Music'),
      (13,'Literature'),
      (14,'Sxetikotitas'),
      (15,'Dynameis'),
      (16,'AES');



INSERT INTO user(username,password,name,lastname,email)
VALUES('iMaxinq','Maxwell420','Maximos','Frountzos','MaxwellFr@gmail.com'),
	  ('BessyLoL','Kotsiri123Kotsiri','Natalia','Kotsiri','BessyKots@gmail.com'),
      ('LokoLuke','BamBamPewPew','Loukas','Tyxeropoulos','LoukasTyx@gmail.com'),
      ('GiovanniGeorgio','GeoGeoGiGi','Giannis','Georgiou','GiovanniGeo@gmail.com'),
      ('Nikolis54','Nick2003','Nikolaos','Andrikopoulos','NikolasAndr@gmail.com'),
      ('Marika365','Ririka20!','Maria','Karagianni','MariaKar@gmail.com'),
      ('Riritos','Aris1111','Aristeidis','Relos','AristeidRel@gmail.com'),
      ('ChrisP','chrischris','Xristos','Papanikolaou','ChrisPapan@gmail.com'),
      ('Lenio666','elenid1m1triou','Eleni','Dimitriou','EleniDim@gmail.com'),
      ('Achilleas12','ach1ll789!','Achilleas','Phleidis','AchilPhl@gmail.com'),
      ('Patro4x4','2003!!2003','Patroklos','Menoitiou','PatrMen@gmail.com'),
      ('Agaphmemnonas21','XrysBrys123','Agamemnonas','Atreidis','AgamemnAtr@gmail.com');

INSERT INTO etairia(AFM,DOY,name,tel,street,num,city,country)
VALUES('109350999','Patron','Volksvaggos','2610222420','Kolokotroni','1','Patra','Greece'),
	('620785420','Athinon','Sutzuki','2610930301','Karolou','75','Athina','Greece'),
      ('991601690','Thesalonikis','AlfaIoylieta','2610220342','Kanakari','334','Thesaloniki','Greece');

INSERT INTO evaluator(username,exp_years,firm)
VALUES('BessyLoL',1,'109350999'),
	('GiovanniGeorgio',5,'991601690'),
      ('Riritos',2,'109350999'),
	('Lenio666',1,'991601690'),
      ('Achilleas12',7,'620785420'),
	('Patro4x4',3,'109350999');

INSERT INTO employee(username,bio,sistatikes,certificates)
VALUES('iMaxinq',"O Maximos Frountzos spoydase sto CEID sthn Patra, doylepse gia 4 xronia sthn AMD.",'sistat_Max.pdf','cert_Max.pdf'),
	('LokoLuke',"O Loukas Tyxeropoulos spoydase sto tmhma oikonomikwn epistimwn sthn Athina opoy kai apofitise me arista",'sistat_Louk.pdf','cert_Louk.pdf'),
      ('Nikolis54',"O Nikolaos Andrikopoulos spoydase sto tmhma Mathimatikwn kai epeita spoudase sto tmhma fysikhs
       sthn Thessaloniki kai idryse thn MathLab.",'sistat_Nikolas.pdf','cert_Nikolas.pdf'),
	('Marika365',"H Maria Karagianni spoydase dioikish twn epixeirisewn sthn Athina.",'sistat_Maria.pdf','cert_Maria.pdf'),
      ('ChrisP',"O Christos Papanikolaou prokeitai gia autodidakto programmatisth me empeiria 3 etwn.",'sistat_Xristos.pdf','cert_Xristos.pdf'),
	('Agaphmemnonas21',"O Agamemnonas Atreidis spoydase sthn Thessaloniki politikos mixanikos",'sistat_Agamemn.pdf','cert_Agamemn.pdf');

INSERT INTO languages(candid,lang)
VALUES('iMaxinq','GR,EN,FR,SP,GE'),
	('LokoLuke','GR'),
      ('Nikolis54','GR,EN,SP,GE'),
	('Agaphmemnonas21','GR,CH');

INSERT INTO project(candid,descr,url)
VALUES('iMaxinq',"Created a database for a travelling agency.","www.github.com/iMaxinq/code/"),
	('Nikolis54',"Did the calculations for a required weather prediction","www.github.com/Nikolis54/code/"),
      ('Marika365',"Took the necessary actions for increasing the company's profits","www.github.com/Marika365/code/"),
	('iMaxinq',"Mathematical predictions for stock prices.","www.github.com/iMaxinq/code/"),
      ('Agaphmemnonas21',"Designed the blueprint for an extension to the company's main building","www.github.com/Agaphmemnonas21/code/"),
	('LokoLuke',"Statistical analysis of investments for the company","www.github.com/LokoLuke/code/"),
      ('ChrisP',"Made the company's website","www.github.com/ChrisP/code/");

INSERT INTO job(start_date,salary,position,edra,evaluator)
VALUES('2024-02-18',3500.0,'Manager','Athens','Lenio666'),
	  ('2024-02-20',3100.0,'Mathematician','Patras','Riritos'),
      ('2024-09-15',1300.0,'Software Engineer','Patras','GiovanniGeorgio'),
	  ('2024-02-24',1600.0,'Software Engineer','Thessaloniki','Lenio666'),
      ('2024-11-18',1100.0,'Accountant','Patras','BessyLoL'),
	  ('2024-04-23',1100.0,'Software Engineer','Thessaloniki','Riritos'),
      ('2024-04-01',2760.0,'Software Engineer','Athens','Achilleas12'),
	  ('2024-12-01',2100.0,'Civil Engineer','Patras','Patro4x4');

INSERT INTO subject(title,descr,belongs_to)
VALUES('Statistics',"Collection of data to predict future behaviors",NULL),
      ('Numerical Analysis',"Development of efficient algorithms through numerical approximation for solving mathematical problems",NULL),
      ('Programming',"Creating instructions for a computer to understand and execute",NULL),
      ('Website development',"Writing code for websites",'Programming'),
      ('Logistics',"Planning, coordination, and implementation of the flow of goods, services, and information from their origin to consumption",NULL),
      ('AI',"Algorithms that simulate human behavior",NULL),
      ('Root-Finding Algorithms',"A part of Numerical analysis that deals with methods to find roots of equations",'Numerical Analysis'),
      ('Newtonian Physics research',"Fundamental laws regarding the motion of objects",NULL);

INSERT INTO requires(job_id,subject_title)
VALUES(17,'Statistics'),
	  (18,'Numerical Analysis'),
      (19,'Programming'),
	  (20,'Website development'),
      (21,'Logistics'),
      (22,'AI'),
      (23,'Root-Finding Algorithms'),
	  (24,'Newtonian Physics research');

INSERT INTO applies(cand_usrname,job_id,appl_state)
VALUES('iMaxinq',19,'Active'),
	  ('Agaphmemnonas21',24,'Cancelled'),
      ('iMaxinq',20,'Active'),
	  ('LokoLuke',21,'Cancelled'),
      ('ChrisP',23,'Active'),
	  ('Marika365',17,'Active');
      
INSERT INTO degree(titlos,idryma,bathmida)
VALUES('Computer Engineering and informatics','University of Athens','PhD'),
	  ('Mathematics','University of Thessaloniki','BSc'),
      ('Economics','University of Patras','MSc'),
      ('Business Administration','University of Athens','MSc'),
      ('Civil Engineering','University of Thessaloniki','MSc'),
      ('Physics','University of Thessaloniki','PhD');

INSERT INTO has_degree(degr_title,degr_idryma,cand_usrname,etos,grade)
VALUES('Computer Engineering and informatics','University of Patras','iMaxinq',2021,8.3),
	  ('Mathematics','University of Thessaloniki','Nikolis54',2016,7.4),
      ('Economics','University of Athens','LokoLuke',2013,10),
      ('Business Administration','University of Athens','Marika365',2017,7.6),
      ('Civil Engineering','University of Thessaloniki','Agaphmemnonas21',2014,7.4),
      ('Physics','University of Thessaloniki','Nikolis54',2017,8.9);