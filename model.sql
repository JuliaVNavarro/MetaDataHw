CREATE TABLE `models` (
    `modelName` VARCHAR(100) NOT NULL,
    `modelDescription` VARCHAR(100) NOT NULL,
    `modelDate` date NOT NULL,
    PRIMARY KEY (`modelName`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `relationschemes` (
    `rsName` VARCHAR(100) NOT NULL,
    `rsDescription` VARCHAR(100) NOT NULL,
    `rsModelName` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`rsName`, `rsModelName`),
    CONSTRAINT `rs_models_fk_01` FOREIGN KEY (`rsModelName`) REFERENCES `models` (`modelName`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `datatypes` (
    `datatype` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`datatype`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `attributes` (
    `attributeName` VARCHAR(100) NOT NULL,
    `rsName` VARCHAR(100) NOT NULL,
    `modelName` VARCHAR(100) NOT NULL,
    `datatype` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`attributeName`, `rsName`, `modelName`, `datatype`),
    CONSTRAINT `attributes_rs_fk_01` FOREIGN KEY (`rsName`) REFERENCES `relationschemes` (`rsName`),
    CONSTRAINT `attributes_rs_fk_02` FOREIGN KEY (`modelName`) REFERENCES `relationschemes` (`rsModelName`),
    CONSTRAINT `attributes_datatypes_fk_01` FOREIGN KEY (`datatype`) REFERENCES `datatypes` (`datatype`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `candidatekeys` (
    `candidateKeyName` VARCHAR(100) NOT NULL,
    `rsName` VARCHAR(100) NOT NULL,
    `modelName` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`candidateKeyName`, `modelName`),
    CONSTRAINT `ck_rs_fk_01` FOREIGN KEY (`rsName`) REFERENCES `relationschemes` (`rsName`),
    CONSTRAINT `ck_rs_fk_02` FOREIGN KEY (`modelName`) REFERENCES `relationschemes` (`rsModelName`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `candidatekeyattributes` (
    `rsName` VARCHAR(100) NOT NULL,
    `modelName` VARCHAR(100) NOT NULL,
    `ckName` VARCHAR(100) NOT NULL,
    `attributeName` VARCHAR(100) NOT NULL,
    `orderNumber` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`modelName`, `rsName`, `ckName`, `attributeName`),
    CONSTRAINT `cka_attributes_fk_01` FOREIGN KEY (`modelName`) REFERENCES `attributes` (`modelName`),
    CONSTRAINT `cka_attributes_fk_02` FOREIGN KEY (`rsName`) REFERENCES `attributes` (`rsName`),
    CONSTRAINT `cka_attributes_fk_03` FOREIGN KEY (`attributeName`) REFERENCES `attributes` (`attributeName`),
    CONSTRAINT `cka_ck_fk_01` FOREIGN KEY (`ckName`) REFERENCES `candidatekeys` (`candidateKeyName`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `decimals` (
    `precision` INT NOT NULL,
    `scale`     INT NOT NULL,
    `modelName` VARCHAR(100) NOT NULL,
    `rsName`    VARCHAR(100) NOT NULL,
    `attributeName` VARCHAR(100) NOT NULL,
    `datatype`  VARCHAR(100) NOT NULL,
    PRIMARY KEY (`modelName`, `rsName`, `attributeName`, `datatype`),
    CONSTRAINT  `decimals_attributes_fk_01` FOREIGN KEY (`modelName`) REFERENCES `attributes` (`modelName`),
    CONSTRAINT  `decimals_attributes_fk_02` FOREIGN KEY (`rsName`) REFERENCES `attributes` (`rsName`),
    CONSTRAINT  `decimals_attributes_fk_03` FOREIGN KEY (`attributeName`) REFERENCES `attributes` (`rsName`),
    CONSTRAINT  `decimals_attributes_fk_04`  FOREIGN KEY (`datatype`) REFERENCES `attributes` (`datatype`),
    CONSTRAINT `scale_range` CHECK (scale > 0 AND scale <= `precision`),
    CONSTRAINT `precision_range` CHECK (`precision` > scale AND `precision` < 66)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `varchars` (
    `length` INT NOT NULL,
    `maxSize` INT NOT NULL,
    `modelName` VARCHAR(100) NOT NULL,
    `rsName` VARCHAR(100) NOT NULL,
    `attributeName` VARCHAR(100) NOT NULL,
    `datatype` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`modelName`, `rsName`, `attributeName`, `datatype`),
    CONSTRAINT  `varchars_attributes_fk_01` FOREIGN KEY (`modelName`) REFERENCES `attributes` (`modelName`),
    CONSTRAINT  `varchars_attributes_fk_02` FOREIGN KEY (`rsName`) REFERENCES `attributes` (`rsName`),
    CONSTRAINT  `varchars_attributes_fk_03` FOREIGN KEY (`attributeName`) REFERENCES `attributes` (`rsName`),
    CONSTRAINT  `varchars_attributes_fk_04`  FOREIGN KEY (`datatype`) REFERENCES `attributes` (`datatype`),
    CONSTRAINT `varchar_pos` CHECK (length > 1 AND length < 65536)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE DEFINER=`Audrey`@`localhost` PROCEDURE `attributes_check_type`(
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
        WHERE	attributeName = in_attribute_name) <> 1 THEN
		SIGNAL SQLSTATE '45000' set message_text = 'Error, unable to find that attribute';
	ELSEIF (SELECT	attributeName
			FROM	attributes
			WHERE	attributeName = in_attribute_name) <> attribute_type THEN
		SET message = CONCAT('Error, unable to set these properties for attribute that is not: ', attribute_type);
		SIGNAL SQLSTATE '45000' set message_text = message;
	END IF;
END;

CREATE DEFINER=`Audrey`@`localhost` TRIGGER `decimals_BEFORE_INSERT` BEFORE INSERT ON `decimals` FOR EACH ROW BEGIN
	-- Make sure that this is a decimal category of a proper decimal attribute.
	CALL attributes_check_type (new.attributeName, 'decimal');
END;

CREATE DEFINER=`Audrey`@`localhost` TRIGGER `varchars_BEFORE_INSERT` BEFORE INSERT ON `varchars` FOR EACH ROW BEGIN
	-- Make sure that this is a decimal category of a proper decimal attribute.
	CALL attributes_check_type (new.attributeName, 'varchar');
END;

CREATE DEFINER=`Audrey`@`localhost` PROCEDURE `attribute_complete`(IN v_attribute_name VARCHAR(64))
/**
	Check the supplied attribute to make sure that if it is a datatype that needs
	additional information regarding the storage of the attribute, that we have
	a corresponding row in the correct category table for that attribute.
	@param	v_attribute_name	The namt of the attribute to check.
*/
BEGIN
	IF NOT EXISTS (	SELECT	'X'
					FROM	attributes
                    WHERE	attributeName = v_attribute_name) THEN
		-- Attribute does not exist, no need to check further
		SIGNAL SQLSTATE '45000' set message_text = 'Error, unable to find that attribute';
	ELSEIF (	SELECT	datatype
				FROM	attributes
                WHERE	attributeName = v_attribute_name) = 'decimal' AND
			NOT EXISTS (	SELECT	'X'
							FROM	decimals
                            WHERE	attributeName = v_attribute_name) THEN
		-- It says it's a decimal, but the category entry is missing.
		SIGNAL SQLSTATE '45000' set message_text = 'Error, missing precision and scale for this attribute!';
	ELSEIF (	SELECT	datatype
				FROM	attributes
                WHERE	attributeName = v_attribute_name) = 'varchar' AND
			NOT EXISTS (	SELECT	'X'
							FROM	varchars
                            WHERE	attributeName = v_attribute_name) THEN
		-- It says it's a varchar, but the category entry is missing.
		SIGNAL SQLSTATE '45000' set message_text = 'Error, missing length for this attribute!';
	END IF;
END;

CREATE DEFINER=`Audrey`@`localhost` TRIGGER `attributes_BEFORE_UPDATE` BEFORE UPDATE ON `attributes` FOR EACH ROW BEGIN
	IF new.datatype <> old.attributeName THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, you cannot change the type of an attribute!';
	END IF;
END

INSERT INTO datatypes (datatype) VALUES
('int'), ('decimal'), ('float'), ('varchar'), ('date'), ('time');

INSERT INTO models (modelName, modelDescription, modelDate) VALUES
('Sample Model', 'A sample of a model', '2022-04-19');

INSERT INTO relationschemes (rsName, rsDescription, rsModelName) VALUES
('Employees', 'A person who works for a company', 'Sample Model'),
('Departments', 'A part of a company', 'Sample Model');

INSERT INTO attributes (attributeName, rsName, modelName, datatype) VALUES
('firstName', 'Employees', 'Sample Model', 'varchar'),
('lastName', 'Employees', 'Sample Model', 'varchar'),
('SSN', 'Employees', 'Sample Model', 'int'),
('annualSalary', 'Employees', 'Sample Model', 'decimal'),
('hireDate', 'Employees', 'Sample Model', 'date'),
('incentiveCompensationPercentage', 'Employees', 'Sample Model', 'float'),
('name', 'Departments', 'Sample Model', 'varchar'),
('description', 'Departments', 'Sample Model', 'varchar'),
('abbreviation', 'Departments', 'Sample Model', 'varchar');

