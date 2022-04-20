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

CREATE TABLE `types` (
    `typeName` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`typeName`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `attributes` (
    `attributeName` VARCHAR(100) NOT NULL,
    `rsName` VARCHAR(100) NOT NULL,
    `modelName` VARCHAR(100) NOT NULL,
    `typeName` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`attributeName`, `rsName`, `modelName`),
    CONSTRAINT `attributes_rs_fk_01` FOREIGN KEY (`rsName`) REFERENCES `relationschemes` (`rsName`),
    CONSTRAINT `attributes_rs_fk_02` FOREIGN KEY (`modelName`) REFERENCES `relationschemes` (`rsModelName`),
    CONSTRAINT `attributes_types_fk_01` FOREIGN KEY (`typeName`) REFERENCES `types` (`typeName`)
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