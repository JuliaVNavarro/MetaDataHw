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
--a key can only have attributes that come from the same relation scheme as the key itself

4) A foreign key constraint cannot have the same name as a candidate key
5) splitting the key
*/

