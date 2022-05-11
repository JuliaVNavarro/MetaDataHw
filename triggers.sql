-- the creation date defaults to NOW() if not specified
CREATE TRIGGER `modelDate_BEFORE_INSERT` BEFORE INSERT ON `models` FOR EACH ROW BEGIN
  IF(new.modelDate = NULL) THEN
    SET new.modelDate = NOW();
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
