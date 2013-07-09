CREATE TABLE `letters` (
    `id` INTEGER PRIMARY KEY,
    `letter` TEXT NOT NULL UNIQUE
);

INSERT INTO `letters` (`letter`) VALUES
("A"), ("Á"), ("Â"), ("Ã"), ("Å"),
("a"), ("á"), ("â"), ("ã"), ("å"),
("E"), ("É"), ("Ê"),
("e"), ("é"), ("ê"),
("Z");
