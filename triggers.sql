-- the creation date defaults to NOW() if not specified
CREATE TRIGGER `model_date_BEFORE_INSERT` BEFORE INSERT ON `models` FOR EACH ROW BEGIN
  IF(new.model_date IS NULL) THEN
    SET new.model_date = NOW();
  END IF;
END;

-- you cannot use a float attribute in a candidate key
CREATE TRIGGER `dataType_BEFORE_INSERT` BEFORE INSERT ON `candidate_key_attributes` FOR EACH ROW BEGIN
    IF(EXISTS (SELECT attribute_name
        FROM attributes
        WHERE attribute_name = new.attribute_name AND data_type = 'float')) THEN
        SIGNAL SQLSTATE  '45000' SET MESSAGE_TEXT = 'You cannot have a float as a candidate key';
    END IF;
END;

-- a key can only have attributes that come from the same relation scheme as the key itself

CREATE TRIGGER `key_BEFORE_INSERT` BEFORE INSERT ON `candidate_key_attributes` FOR EACH ROW BEGIN

    IF(EXISTS (
        SELECT rs_name
        FROM candidate_keys
        WHERE candidate_key_name = new.candidate_key_name)) != new.rs_name)
        THEN SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'a key can only have attributes that come from the same relation scheme as the key itself';
  END IF;
END;


/*
4) A foreign key constraint cannot have the same name as a candidate key
*/

DELIMITER //
CREATE TRIGGER `candidate_keys_BEFORE_INSERT` BEFORE INSERT ON `candidate_keys` FOR EACH ROW BEGIN
    call get_key_name(new.candidate_key_name, new.model_name);
END;

CREATE TRIGGER `primary_keys_BEFORE_INSERT` BEFORE INSERT ON `primary_keys` FOR EACH ROW BEGIN
    call get_key_name(new.pk_name, new.model_name);
END;
DELIMITER ;

DELIMITER //
CREATE PROCEDURE `get_key_name` (IN in_constraint_name VARCHAR(50),
                                            IN in_model_name VARCHAR(50))
BEGIN
    IF(SELECT COUNT(*) FROM candidate_keys
        WHERE candidate_key_name= in_constraint_name
        AND candidate_keys.candidate_key_name LIKE '%ck'
        AND model_name = in_model_name) > 0
    THEN
        SIGNAL SQLSTATE '45000'
        SET message_text = 'Error: There is already a candidate key with that constraint name.';
    END IF;
    IF (SELECT COUNT(*) FROM primary_keys
        WHERE pk_name = in_constraint_name
        AND model_name = in_model_name) > 0
    THEN
        SIGNAL SQLSTATE '45000'
        SET message_text = 'Error: There is already a primary key with that constraint name.';
    END IF;
END //
DELIMITER ;




CREATE PROCEDURE `attributes_check_type`(
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

CREATE TRIGGER `decimals_BEFORE_INSERT` BEFORE INSERT ON `decimals` FOR EACH ROW BEGIN
	-- Make sure that this is a decimal category of a proper decimal attribute.
	CALL attributes_check_type (new.attribute_name, 'decimal');
END;

CREATE TRIGGER `varchars_BEFORE_INSERT` BEFORE INSERT ON `varchars` FOR EACH ROW BEGIN
	-- Make sure that this is a decimal category of a proper decimal attribute.
	CALL attributes_check_type (new.attribute_name, 'varchar');
END;

CREATE PROCEDURE `attribute_complete`(IN v_attribute_name VARCHAR(64))
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

CREATE TRIGGER `attributes_BEFORE_UPDATE` BEFORE UPDATE ON `attributes` FOR EACH ROW BEGIN
	IF new.data_type <> old.attribute_name THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, you cannot change the type of an attribute!';
	END IF;
END;

CREATE PROCEDURE `split_key` (IN in_model_name VARCHAR(50), IN in_relation_scheme VARCHAR(50))
BEGIN
    IF (SELECT COUNT(migrated_attribute) 
	FROM attribute_relationships
        WHERE model_name = in_model_name
        AND child_rs_name = in_relation_scheme
        AND migrated_attribute NOT IN
        (SELECT (attribute_name) 
	 FROM candidate_key_attributes
         WHERE model_name = in_model_name
         AND rs_name = in_relation_scheme) <> 0)
    THEN
        IF (SELECT COUNT(attribute_name) 
	    FROM candidate_key_attributes
            WHERE model_name = in_model_name
            AND rs_name = in_relation_scheme
            AND attribute_name NOT IN
            (SELECT (migrated_attribute) 
	     FROM attribute_relationships
             WHERE model_name = in_model_name
             AND child_rs_name = in_relation_scheme) = 0)
        THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: A foreign key constraint cannot split the key of the parent';
        END IF;
    END IF;
END;
