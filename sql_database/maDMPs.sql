#CREATE DATABASE maDMPs;
USE maDMPs;

# BASE TABLES
# -----------------------------------------------------
CREATE TABLE awards(
  id INTEGER NOT NULL AUTO_INCREMENT,
  description TEXT,
  title VARCHAR(255),
  offered_by INTEGER,
  source_id INTEGER NOT NULL,
  source_json TEXT,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE contributors(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  name VARCHAR(255),
  email VARCHAR(255),
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE expeditions(
  id INTEGER NOT NULL AUTO_INCREMENT,
  title VARCHAR(255),
  start_date DATETIME,
  public BOOLEAN NOT NULL DEFAULT 0,
  created_at TIMESTAMP,
  source_id INTEGER NOT NULL,
  source_json TEXT,
  PRIMARY KEY (id)
);
CREATE TABLE identifiers(
  id INTEGER NOT NULL AUTO_INCREMENT,
  identifier VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE orgs(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  name VARCHAR(255),
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE markers(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  source_json TEXT,
  project_id INTEGER NOT NULL,
  value VARCHAR(255) NOT NULL,
  uri VARCHAR(255),
  defined_by VARCHAR(255),
  definition TEXT,
  PRIMARY KEY (id)
);
CREATE TABLE projects(
  id INTEGER NOT NULL AUTO_INCREMENT,
  title VARCHAR(255),
  description TEXT,
  license TEXT NOT NULL,
  source_id INTEGER NOT NULL,
  source_json TEXT,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE sources(
  id INTEGER NOT NULL AUTO_INCREMENT,
  name VARCHAR(255),
  directory VARCHAR(255),
  last_download DATETIME,
  created_at TIMESTAMP,
  PRIMARY KEY (id)
);
CREATE TABLE types(
  id INTEGER NOT NULL AUTO_INCREMENT,
  type VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);

# JOIN TABLES
# -----------------------------------------------------
CREATE TABLE org_identifiers(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  org_id INTEGER NOT NULL,
  identifier VARCHAR(50) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE org_types(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  org_id INTEGER NOT NULL,
  type VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE org_awards(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  project_id INTEGER NOT NULL,
  org_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE contributor_identifiers(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  contributor_id INTEGER NOT NULL,
  identifier_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE contributor_types(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  contributor_id INTEGER NOT NULL,
  type_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE award_identifiers(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  award_id INTEGER NOT NULL,
  identifier_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE award_types(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  award_id INTEGER NOT NULL,
  type_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE project_identifiers(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  identifier_id INTEGER NOT NULL,
  project_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE project_types(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  project_id INTEGER NOT NULL,
  type VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE project_contributors(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  project_id INTEGER NOT NULL,
  contributor_id INTEGER NOT NULL,
  role INTEGER NOT NULL,                    # 0 = Principal Investigator, 1 = Co-principal Investigator, 2 = Researcher
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE project_awards(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  project_id INTEGER NOT NULL,
  award_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
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
  identifier_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE expedition_contributors(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  expedition_id INTEGER NOT NULL,
  contributor_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);

INSERT INTO sources (name, directory) VALUES ('GeOMe', 'geome_reader');
INSERT INTO sources (name, directory) VALUES ('BCO-DMO', 'bco_dmo');
INSERT INTO sources (name, directory) VALUES ('Biocode', 'biocode');
