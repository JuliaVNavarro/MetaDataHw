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
    `max_parent_cardinality` INT NOT NULL,
    `min_child_cardinality` INT NOT NULL,
    `max_child_cardinality` INT NOT NULL,
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `attributes_check_type`(
	IN in_attribute_name VARCHAR(64), IN attribute_type VARCHAR(20))
    /**
    Validate that the attribute type value in the attribute matches the supplied value.
    This is used in the on insert trigger for the varchar and decimal categories of
    attribute.
    @param		in_attribute_name	The attribute that we're checking.
    @param		in_attribute_type	The type that it should have.
    */
BEGIN
	DECLARE message VARCHAR(100);
    IF (SELECT	count(*)
		FROM	attributes
        WHERE	attribute_name = in_attribute_name) <> 1 THEN
		SIGNAL SQLSTATE '45000' set message_text = 'Error, unable to find that attribute';
	ELSEIF (SELECT	data_type
			FROM	attributes
			WHERE	attribute_name = in_attribute_name) <> attribute_type THEN
		SET message = CONCAT('Error, unable to set these properties for attribute that is not: ', attribute_type);
		SIGNAL SQLSTATE '45000' set message_text = message;
	END IF;
END;

CREATE DEFINER=`root`@`localhost` TRIGGER `decimals_BEFORE_INSERT` BEFORE INSERT ON `decimals` FOR EACH ROW BEGIN
	-- Make sure that this is a decimal category of a proper decimal attribute.
	CALL attributes_check_type (new.attribute_name, 'decimal');
END;

CREATE DEFINER=`root`@`localhost` TRIGGER `varchars_BEFORE_INSERT` BEFORE INSERT ON `varchars` FOR EACH ROW BEGIN
	-- Make sure that this is a decimal category of a proper decimal attribute.
	CALL attributes_check_type (new.attribute_name, 'varchar');
END;

CREATE DEFINER=`root`@`localhost` PROCEDURE `attribute_complete`(IN v_attribute_name VARCHAR(64))
/**
	Check the supplied attribute to make sure that if it is a datatype that needs
	additional information regarding the storage of the attribute, that we have
	a corresponding row in the correct category table for that attribute.
	@param	v_attribute_name	The namt of the attribute to check.
*/
BEGIN
	IF NOT EXISTS (	SELECT	'X'
					FROM	attributes
                    WHERE	attribute_name = v_attribute_name) THEN
		-- Attribute does not exist, no need to check further
		SIGNAL SQLSTATE '45000' set message_text = 'Error, unable to find that attribute';
	ELSEIF (	SELECT	data_type
				FROM	attributes
                WHERE	attribute_name = v_attribute_name) = 'decimal' AND
			NOT EXISTS (	SELECT	'X'
							FROM	decimals
                            WHERE	attribute_name = v_attribute_name) THEN
		-- It says it's a decimal, but the category entry is missing.
		SIGNAL SQLSTATE '45000' set message_text = 'Error, missing precision and scale for this attribute!';
	ELSEIF (	SELECT	data_type
				FROM	attributes
                WHERE	attribute_name = v_attribute_name) = 'varchar' AND
			NOT EXISTS (	SELECT	'X'
							FROM	varchars
                            WHERE	attribute_name = v_attribute_name) THEN
		-- It says it's a varchar, but the category entry is missing.
		SIGNAL SQLSTATE '45000' set message_text = 'Error, missing length for this attribute!';
	END IF;
END;

CREATE DEFINER=`root`@`localhost` TRIGGER `attributes_BEFORE_UPDATE` BEFORE UPDATE ON `attributes` FOR EACH ROW BEGIN
	IF new.data_type <> old.attribute_name THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, you cannot change the type of an attribute!';
	END IF;
END;

INSERT INTO data_types (data_type) VALUES
('int'), ('decimal'), ('float'), ('varchar'), ('date'), ('time');

INSERT INTO models (model_name, model_description, model_date) VALUES
('Sample Model', 'A sample of a model', '2022-04-19');

INSERT INTO relation_schemes (rs_name, rs_description, rs_model_name) VALUES
('Employees', 'A person who works for a company', 'Sample Model'),
('Departments', 'A part of a company', 'Sample Model');

INSERT INTO attributes (attribute_name, rs_name, model_name, data_type) VALUES
('firstName', 'Employees', 'Sample Model', 'varchar'),
('lastName', 'Employees', 'Sample Model', 'varchar'),
('SSN', 'Employees', 'Sample Model', 'int'),
('annualSalary', 'Employees', 'Sample Model', 'decimal'),
('hireDate', 'Employees', 'Sample Model', 'date'),
('incentiveCompensationPercentage', 'Employees', 'Sample Model', 'float'),
('name', 'Departments', 'Sample Model', 'varchar'),
('description', 'Departments', 'Sample Model', 'varchar'),
('abbreviation', 'Departments', 'Sample Model', 'varchar');

INSERT INTO attributes (attribute_name, rs_name, model_name, data_type) VALUES
('employeeID', 'Employees', 'Sample Model', 'varchar');

INSERT INTO candidate_keys (candidate_key_name, rs_name, model_name) VALUES
('Employees Primary Key', 'Employees', 'Sample Model'),
('Departments Primary Key', 'Departments', 'Sample Model');

INSERT INTO candidate_key_attributes (rs_name, model_name, ck_name, attribute_name, order_number) VALUES
('Employees', 'Sample Model', 'Employees Primary Key', 'employeeID', 1),
('Departments', 'Sample Model', 'Departments Primary Key', 'name', 1);

INSERT INTO candidate_keys (candidate_key_name, rs_name, model_name) VALUES
('Employees Candidate Key', 'Employees', 'Sample Model');

INSERT INTO candidate_key_attributes (rs_name, model_name, ck_name, attribute_name, order_number) VALUES
('Employees', 'Sample Model', 'Employees Candidate Key', 'SSN', 1);

INSERT INTO decimals (`precision`, scale, model_name, rs_name, attribute_name, data_type) VALUES
(10, 2, 'Sample Model', 'Employees', 'annualSalary', 'decimal');

INSERT INTO varchars (length, model_name, rs_name, attribute_name, data_type) VALUES
(100, 'Sample Model', 'Employees', 'firstName', 'varchar');
