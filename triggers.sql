-- the creation date defaults to NOW() if not specified
CREATE TRIGGER `modelDate_BEFORE_INSERT` BEFORE INSERT ON `models` FOR EACH ROW BEGIN
  IF(new.modelDate = NULL) THEN
    SET new.modelDate = NOW();
  END IF;
END;
