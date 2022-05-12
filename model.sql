/* DDL */

CREATE TABLE `models` (
    `model_name` VARCHAR(100) NOT NULL,
    `model_description` VARCHAR(100) NOT NULL,
    `model_date` date NOT NULL,
    PRIMARY KEY `models_pk` (`model_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `relation_schemes` (
    `rs_name` VARCHAR(100) NOT NULL,
    `rs_description` VARCHAR(100) NOT NULL,
    `rs_model_name` VARCHAR(100) NOT NULL,
    PRIMARY KEY `relation_schemes_pk` (`rs_name`, `rs_model_name`),
    CONSTRAINT `rs_models_fk_01` FOREIGN KEY (`rs_model_name`) REFERENCES `models` (`model_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `data_types` (
    `data_type` VARCHAR(100) NOT NULL,
    PRIMARY KEY `data_types_pk` (`data_type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `attributes` (
    `attribute_name` VARCHAR(100) NOT NULL,
    `rs_name` VARCHAR(100) NOT NULL,
    `model_name` VARCHAR(100) NOT NULL,
    `data_type` VARCHAR(100) NOT NULL,
    PRIMARY KEY `attributes_pk` (`attribute_name`, `rs_name`, `model_name`),
    CONSTRAINT `attributes_rs_fk_01` FOREIGN KEY (`rs_name`, `model_name`) REFERENCES `relation_schemes` (`rs_name`, rs_model_name),
    CONSTRAINT `attributes_data_types_fk_01` FOREIGN KEY (`data_type`) REFERENCES `data_types` (`data_type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `candidate_keys` (
    `candidate_key_name` VARCHAR(100) NOT NULL,
    `rs_name` VARCHAR(100) NOT NULL,
    `model_name` VARCHAR(100) NOT NULL,
    PRIMARY KEY `candidate_keys_pk` (`candidate_key_name`, `model_name`),
    CONSTRAINT `candidate_keys_relation_schemes_fk_01` FOREIGN KEY (`rs_name`, `model_name`) REFERENCES `relation_schemes` (`rs_name`, `rs_model_name`),
    CONSTRAINT `candidate_keys_models_fk_02` FOREIGN KEY (`model_name`) REFERENCES `models` (`model_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `primary_keys` (
    `model_name` VARCHAR(100) NOT NULL,
    `pk_name` VARCHAR(100) NOT NULL,
    PRIMARY KEY `primary_keys_pk` (`model_name`, `pk_name`),
    CONSTRAINT `primary_keys_ck_fk_01` FOREIGN KEY (`model_name`, `pk_name`) REFERENCES `candidate_keys` (`model_name`, `candidate_key_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `candidate_key_attributes` (
    `rs_name` VARCHAR(100) NOT NULL,
    `model_name` VARCHAR(100) NOT NULL,
    `ck_name` VARCHAR(100) NOT NULL,
    `attribute_name` VARCHAR(100) NOT NULL,
    `order_number` VARCHAR(100) NOT NULL,
    PRIMARY KEY `candidate_key_attributes_pk` (`attribute_name`, `model_name`, `rs_name`, `ck_name`),
    CONSTRAINT UNIQUE `candidate_key_attributes_uk_01` (`model_name`, `ck_name`, `order_number`),
    CONSTRAINT `cka_attributes_fk_01` FOREIGN KEY (`rs_name`, `model_name`, `attribute_name`) REFERENCES `attributes` (`rs_name`, `model_name`, `attribute_name`),
    CONSTRAINT `cka_ck_fk_01` FOREIGN KEY (`ck_name`, `model_name`) REFERENCES `candidate_keys` (`candidate_key_name`, `model_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `decimals` (
    `precision` INT NOT NULL,
    `scale`     INT NOT NULL,
    `model_name` VARCHAR(100) NOT NULL,
    `rs_name`    VARCHAR(100) NOT NULL,
    `attribute_name` VARCHAR(100) NOT NULL,
    PRIMARY KEY `decimals_pk` (`model_name`, `rs_name`, `attribute_name`),
    CONSTRAINT  `decimals_attributes_fk_01` FOREIGN KEY (`attribute_name`, `rs_name`, `model_name`) REFERENCES `attributes` (`attribute_name`, `rs_name`, `model_name`),
    CONSTRAINT `scale_range` CHECK (scale > 0 AND scale <= `precision`),
    CONSTRAINT `precision_range` CHECK (`precision` > scale AND `precision` < 66)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `varchars` (
    `length` INT NOT NULL,
    `model_name` VARCHAR(100) NOT NULL,
    `rs_name` VARCHAR(100) NOT NULL,
    `attribute_name` VARCHAR(100) NOT NULL,
    PRIMARY KEY `varchars_pk` (`model_name`, `rs_name`, `attribute_name`),
    CONSTRAINT  `varchars_attributes_fk_01` FOREIGN KEY (`attribute_name`, `rs_name`, `model_name`) REFERENCES `attributes` (`attribute_name`, `rs_name`, `model_name`),
    CONSTRAINT `varchar_pos` CHECK (`length` > 1 AND `length` < 65536)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `relationships` (
    `relationship_name` VARCHAR(100) NOT NULL,
    `model_name` VARCHAR(100) NOT NULL,
    `rs_name` VARCHAR(100) NOT NULL,
    `min_parent_cardinality` INT NOT NULL,
    `max_parent_cardinality` VARCHAR(5) NOT NULL,
    `min_child_cardinality` INT NOT NULL,
    `max_child_cardinality` VARCHAR(5) NOT NULL,
    `parent` VARCHAR(100) NOT NULL,
    `child` VARCHAR(100) NOT NULL,
    `pk_name` VARCHAR(100) NOT NULL,
    PRIMARY KEY `relationships_pk` (`relationship_name`, `model_name`),
    CONSTRAINT `relationships_model_fk_01` FOREIGN KEY (`model_name`) REFERENCES `models` (`model_name`),
    CONSTRAINT `relationships_rs_fk_01` FOREIGN KEY (`model_name`,`rs_name`) REFERENCES `relation_schemes` (`rs_model_name`, `rs_name`),
    CONSTRAINT `relationships_primary_keys_fk_01` FOREIGN KEY (`model_name`, `pk_name`) REFERENCES `primary_keys` (`model_name`, `pk_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `attribute_relationships` (
    `migrated_attribute` VARCHAR(100) NOT NULL,
    `relationship_name` VARCHAR(100) NOT NULL,
    `child_rs_name` VARCHAR(100) NOT NULL,
    `model_name` VARCHAR(100) NOT NULL,
    `ck_name` VARCHAR(100) NOT NULL,
    `parent_rs_name` VARCHAR(100) NOT NULL,
    `parent_key_attribute` VARCHAR(100) NOT NULL,
    PRIMARY KEY `attribute_relationships_pk` (`relationship_name`, `model_name`, `parent_rs_name`, `parent_key_attribute`),
    CONSTRAINT UNIQUE `attribute_relationships_uk_01` (`migrated_attribute`, `relationship_name`, `child_rs_name`, `model_name`),
    CONSTRAINT `attribute_relationships_attributes_fk_01` FOREIGN KEY (`migrated_attribute`, `child_rs_name`, `model_name`) REFERENCES `attributes` (`attribute_name`, `rs_name`, `model_name`),
    CONSTRAINT `attribute_relationships_relationships_fk_01` FOREIGN KEY (`relationship_name`, `model_name`) REFERENCES `relationships` (`relationship_name`, `model_name`),
    CONSTRAINT `attribute_relationships_pk_fk_01` FOREIGN KEY (`model_name`, `ck_name`) REFERENCES `primary_keys` (`model_name`, `pk_name`),
    CONSTRAINT `attribute_relationships_cka_fk_01` FOREIGN KEY (`parent_key_attribute`, `model_name`, `parent_rs_name`, `ck_name`) REFERENCES `candidate_key_attributes` (`attribute_name`, `model_name`, `rs_name`, `ck_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


/* DML */
INSERT INTO data_types (data_type) VALUES
('int'), ('decimal'), ('float'), ('varchar'), ('date'), ('time');

INSERT INTO `models` (model_name, model_description) values
('MetaData Model', 'Model to test MetaDate Project');

INSERT INTO `relation_schemes` (rs_name, rs_description, rs_model_name) VALUES
('students', 'student information', 'MetaData Model'),
('enrollments', 'enrollment information', 'MetaData Model'),
('transcript_entries', 'transcript entry information', 'MetaData Model'),
('sections', 'sections information', 'MetaData Model'),
('courses', 'course information', 'MetaData Model'),
('departments', 'department information', 'MetaData Model');

INSERT INTO attributes (attribute_name, rs_name, model_name, data_type) VALUES
('student_id', 'students', 'MetaData Model', 'int'),
('last_name', 'students', 'MetaData Model', 'varchar'),
('first_name', 'students', 'MetaData Model', 'varchar'),
('name', 'departments', 'MetaData Model', 'varchar'),
('name', 'courses', 'MetaData Model', 'varchar'),
('number', 'courses', 'MetaData Model', 'int'),
('description', 'courses', 'MetaData Model', 'varchar'),
('units', 'courses', 'MetaData Model', 'int'),
('title', 'courses', 'MetaData Model', 'varchar'),
-- ('weekday_combinations', 'days', 'MetaData Model', 'varchar')
-- ('instructor_name', 'instructors', 'MetaData Model', 'varchar')
-- ('name', 'semesters', 'MetaData Model', 'varchar')
('department_name', 'sections', 'MetaData Model', 'varchar'),
('course_number', 'sections', 'MetaData Model', 'int'),
('number', 'sections', 'MetaData Model', 'int'),
('year', 'sections', 'MetaData Model', 'int'),
('semester', 'sections', 'MetaData Model', 'varchar'),
('instructor', 'sections', 'MetaData Model', 'varchar'),
('start_time', 'sections', 'MetaData Model', 'time'),
('days', 'sections', 'MetaData Model', 'varchar'),
-- ('grade_letter', 'grades', 'MetaData Model', 'varchar')
('student_id', 'enrollments', 'MetaData Model', 'int'),
('department_name', 'enrollments', 'MetaData Model', 'varchar'),
('course_number', 'enrollments', 'MetaData Model', 'int'),
('section_number', 'enrollments', 'MetaData Model', 'int'),
('year', 'enrollments', 'MetaData Model', 'int'),
('semester', 'enrollments', 'MetaData Model', 'varchar'),
('grade', 'enrollments', 'MetaData Model', 'varchar'),
('student_id', 'transcript_entries', 'MetaData Model', 'int'),
('department_name', 'transcript_entries', 'MetaData Model', 'varchar'),
('course_number', 'transcript_entries', 'MetaData Model', 'int'),
('section_number', 'transcript_entries', 'MetaData Model', 'int'),
('year', 'transcript_entries', 'MetaData Model', 'int'),
('semester', 'transcript_entries', 'MetaData Model', 'varchar');

INSERT INTO candidate_keys (candidate_key_name, rs_name, model_name) VALUES
('students_pk', 'students', 'MetaData Model'),
('enrollments_pk', 'enrollments', 'MetaData Model'),
('transcript_entries_pk', 'transcript_entries', 'MetaData Model'),
('sections_pk', 'sections', 'MetaData Model'),
('courses_pk', 'courses', 'MetaData Model'),
('courses_uk_01', 'courses', 'MetaData Model'),
('departments_pk', 'departments', 'MetaData Model');

INSERT INTO primary_keys (model_name, pk_name) VALUES
('MetaData Model', 'departments_pk'),
('MetaData Model', 'courses_pk'),
('MetaData Model', 'sections_pk'),
('MetaData Model', 'students_pk'),
('MetaData Model', 'enrollments_pk'),
('MetaData Model', 'transcript_entries_pk');

INSERT INTO candidate_key_attributes (rs_name, model_name, ck_name, attribute_name, order_number) VALUES
('students', 'MetaData Model', 'students_pk', 'student_id', 1),
('enrollments', 'MetaData Model', 'enrollments_pk', 'student_id', 1),
('enrollments', 'MetaData Model', 'enrollments_pk', 'department_name', 2),
('enrollments', 'MetaData Model', 'enrollments_pk', 'course_number', 3),
('enrollments', 'MetaData Model', 'enrollments_pk', 'section_number', 4),
('enrollments', 'MetaData Model', 'enrollments_pk', 'year', 5),
('enrollments', 'MetaData Model', 'enrollments_pk', 'semester', 6),
('transcript_entries', 'MetaData Model', 'transcript_entries_pk', 'student_id', 1),
('transcript_entries', 'MetaData Model', 'transcript_entries_pk', 'department_name', 2),
('transcript_entries', 'MetaData Model', 'transcript_entries_pk', 'course_number', 3),
('sections', 'MetaData Model', 'sections_pk', 'department_name', 1),
('sections', 'MetaData Model', 'sections_pk', 'course_number', 2),
('sections', 'MetaData Model', 'sections_pk', 'number', 3),
('sections', 'MetaData Model', 'sections_pk', 'year', 4),
('sections', 'MetaData Model', 'sections_pk', 'semester', 5),
('courses', 'MetaData Model', 'courses_pk', 'name', 1),
('courses', 'MetaData Model', 'courses_pk', 'number', 2),
('courses', 'MetaData Model', 'courses_uk_01', 'name', 1),
('courses', 'MetaData Model', 'courses_uk_01', 'title', 2),
('departments', 'MetaData Model', 'departments_pk', 'name', 1);


insert into relationships (relationship_name, model_name, rs_name, min_parent_cardinality, max_parent_cardinality, min_child_cardinality, max_child_cardinality, parent, child, pk_name) values
('students_enrollments_relationship', 'MetaData Model', 'students', 1, 1, 0, 'MANY', 'students', 'enrollments', 'students_pk'),
('enrollments_transcript_entries_relationship', 'MetaData Model', 'enrollments', 1, 1, 0, 1, 'enrollments', 'transcript_entries', 'enrollments_pk'),
('sections_enrollments_relationship', 'MetaData Model', 'sections', 1, 1, 0, 'MANY', 'sections', 'enrollments', 'sections_pk'),
('courses_sections_relationship', 'MetaData Model', 'courses', 1, 1, 0, 'MANY', 'courses', 'sections', 'courses_pk'),
('departments_courses_relationships', 'MetaData Model', 'departments', 1, 1, 1, 'MANY', 'departments', 'courses', 'departments_pk');

INSERT INTO attribute_relationships (migrated_attribute, relationship_name, child_rs_name, model_name, ck_name, parent_rs_name, parent_key_attribute) VALUES
('student_id', 'students_enrollments_relationship', 'enrollments', 'MetaData Model', 'students_pk', 'students', 'student_id'),
('student_id', 'enrollments_transcript_entries_relationship', 'transcript_entries', 'MetaData Model', 'enrollments_pk', 'enrollments', 'student_id'),
('department_name', 'enrollments_transcript_entries_relationship', 'transcript_entries', 'MetaData Model', 'enrollments_pk', 'enrollments', 'department_name'),
('course_number', 'enrollments_transcript_entries_relationship', 'transcript_entries', 'MetaData Model', 'enrollments_pk', 'enrollments', 'course_number'),
('section_number', 'enrollments_transcript_entries_relationship', 'transcript_entries', 'MetaData Model', 'enrollments_pk', 'enrollments', 'section_number'),
('year', 'enrollments_transcript_entries_relationship', 'transcript_entries', 'MetaData Model', 'enrollments_pk', 'enrollments', 'year'),
('semester', 'enrollments_transcript_entries_relationship', 'transcript_entries', 'MetaData Model', 'enrollments_pk', 'enrollments', 'semester'),
('department_name', 'sections_enrollments_relationship', 'enrollments', 'MetaData Model', 'sections_pk', 'sections', 'department_name'),
('course_number', 'sections_enrollments_relationship', 'enrollments', 'MetaData Model', 'sections_pk', 'sections', 'course_number'),
('section_number', 'sections_enrollments_relationship', 'enrollments', 'MetaData Model', 'sections_pk', 'sections', 'number'),
('year', 'sections_enrollments_relationship', 'enrollments', 'MetaData Model', 'sections_pk', 'sections', 'year'),
('semester', 'sections_enrollments_relationship', 'enrollments', 'MetaData Model', 'sections_pk', 'sections', 'semester'),
('department_name', 'courses_sections_relationship', 'sections', 'MetaData Model', 'courses_pk', 'courses', 'name'),
('course_number', 'courses_sections_relationship', 'sections', 'MetaData Model', 'courses_pk', 'courses', 'number'),
('name', 'departments_courses_relationships', 'courses', 'MetaData Model', 'departments_pk', 'departments', 'name');

INSERT INTO varchars (length, model_name, rs_name, attribute_name) VALUES
(100, 'MetaData Model', 'students', 'last_name'),
(100, 'MetaData Model', 'students', 'first_name'),
(100, 'MetaData Model', 'departments', 'name'),
(100, 'MetaData Model', 'courses', 'name'),
(100, 'MetaData Model', 'courses', 'description'),
(100, 'MetaData Model', 'courses', 'title'),
(100, 'MetaData Model', 'sections', 'department_name'),
(100, 'MetaData Model', 'sections', 'semester'),
(100, 'MetaData Model', 'sections', 'instructor'),
(100, 'MetaData Model', 'sections', 'days'),
(100, 'MetaData Model', 'enrollments', 'department_name'),
(100, 'MetaData Model', 'enrollments', 'semester'),
(100, 'MetaData Model', 'enrollments', 'grade'),
(100, 'MetaData Model', 'transcript_entries', 'department_name'),
(100, 'MetaData Model', 'transcript_entries', 'semester');




/* TEST PLAN */
1. Test that the model_date defaults to now() if not specified.
2. Test that a key can only have attributes that come from the same relation scheme as the key itself.
3. Test that you cannot use a float attribute in a candidate key.
4. 
