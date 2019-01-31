DROP KEYSPACE IF EXISTS example;
CREATE KEYSPACE IF NOT EXISTS example WITH replication = {'class': 'SimpleStrategy', 'replication_factor': '3'};
USE example; 

DROP TABLE IF EXISTS test;
CREATE TABLE IF NOT EXISTS test(
C1 Text, C2 Text, C3 Text, C4 Text, C5 Text, C6 Text, C7 Text, C8 Text, C9 Text, C10 Text, C11 Text, C12 Text, C13 Text, C14 Text, C15 Text, C16 Text, C17 Text, C18 Text, C19 Text, C20 Text, C21 Text, C22 Text, C23 Text, C24 Text, C25 Text, C26 Text, C27 Text, C28 Text, C29 Text, C30 Text, C31 Text, C32 Text, C33 Text, C34 Text, C35 Text, C36 Text, C37 Text, C38 Text, C39 Text, C40 Text, C41 Text, C42 Text, C43 Text, C44 Text, C45 Text, C46 Text, C47 Text, C48 Text, C49 Text, C50 Text, C51 Text, C52 Text, C53 Text, C54 Text, C55 Text, C56 Text, C57 Text, C58 Text, C59 Text, C60 Text, C61 Text, C62 Text, C63 Text, C64 Text, C65 Text, C66 Text, C67 Text, C68 Text, C69 Text, C70 Text, C71 Text, C72 Text, C73 Text, C74 Text, C75 Text, C76 Text, C77 Text, C78 Text, C79 Text, C80 Text, C81 Text, C82 Text, C83 Text, C84 Text, C85 Text, C86 Text, C87 Text, C88 Text, C89 Text, C90 Text, C91 Text, C92 Text, C93 Text, 
PRIMARY KEY(C1, C35));
#DESCRIBE TABLE test;

# create index on test(C2);
# create index on test(C3);
# create index on test(C4);
# create index on test(C5);
# create index on test(C6);
# create index on test(C7);
# create index on test(C8);
# create index on test(C9);
# create index on test(C10);
# create index on test(C11);
# create index on test(C12);
# create index on test(C13);
# create index on test(C14);
# create index on test(C15);
# create index on test(C16);
# create index on test(C17);
# create index on test(C18);
# create index on test(C19);
# create index on test(C20);
# create index on test(C21);
# create index on test(C22);
# create index on test(C23);
# create index on test(C24);
# create index on test(C25);