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
