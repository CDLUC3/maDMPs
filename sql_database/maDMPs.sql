#CREATE DATABASE maDMPs;
USE maDMPs;

CREATE TABLE sources(
  id INTEGER,
  name VARCHAR(255),
  directory VARCHAR(255),
  last_download DATETIME,
  created_at TIMESTAMP,
  PRIMARY KEY (id)
);
CREATE TABLE projects(
  id INTEGER NOT NULL AUTO_INCREMENT,
  title VARCHAR(255),
  source_id INTEGER NOT NULL,
  source_json JSON,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE project_identifiers(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  project_id INTEGER NOT NULL,
  identifier VARCHAR(50) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE markers(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  source_json JSON,
  project_id INTEGER NOT NULL,
  value VARCHAR(255) NOT NULL,
  uri VARCHAR(255),
  defined_by VARCHAR(255),
  definition TEXT,
  PRIMARY KEY (id)
);
CREATE TABLE expeditions(
  id INTEGER NOT NULL AUTO_INCREMENT,
  title VARCHAR(255),
  start_date DATETIME,
  public BOOLEAN NOT NULL DEFAULT 0,
  created_at TIMESTAMP,
  source_id INTEGER NOT NULL,
  source_json JSON,
  PRIMARY KEY (id)
);
CREATE TABLE project_expeditions(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  project_id INTEGER NOT NULL,
  expedition_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE expedition_identifiers(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  expedition_id INTEGER NOT NULL,
  identifier VARCHAR(50) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE authors(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  name VARCHAR(255),
  email VARCHAR(255),
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE author_identifiers(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  author_id INTEGER NOT NULL,
  identifier VARCHAR(50) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE project_authors(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  project_id INTEGER NOT NULL,
  author_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE expedition_authors(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  expedition_id INTEGER NOT NULL,
  author_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);

INSERT INTO sources (id, name, directory, output)
VALUES (1, 'GeOMe', 'geome_reader', 'geome_reader/output.json');
INSERT INTO sources (id, name) VALUES (2, 'BCO-DMO');
