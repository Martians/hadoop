
CREATE KEYSPACE IF NOT EXISTS example WITH replication = {'class': 'SimpleStrategy', 'replication_factor': '1'};
USE example;

CREATE TABLE IF NOT EXISTS test(id INT, name TEXT, PRIMARY KEY(id));

INSERT INTO test(id, name) VALUES (1, 'name1');
INSERT INTO test(id, name) VALUES (2, 'name2');
INSERT INTO test(id, name) VALUES (3, 'name3');
INSERT INTO test(id, name) VALUES (4, 'name4');