#CREATE DATABASE maDMPs;
USE maDMPs;

# BASE TABLES
# -----------------------------------------------------
CREATE TABLE awards(
  id INTEGER NOT NULL AUTO_INCREMENT,
  description TEXT,
  title VARCHAR(255) NOT NULL,
  amount FLOAT,
  public_access_mandate BOOLEAN NOT NULL DEFAULT 0,
  award_date DATETIME,
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
CREATE TABLE documents(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  title VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE stages(
  id INTEGER NOT NULL AUTO_INCREMENT,
  title VARCHAR(255) NOT NULL,
  start_date DATETIME,
  public BOOLEAN NOT NULL DEFAULT 0,
  created_at TIMESTAMP,
  source_id INTEGER NOT NULL,
  source_json TEXT,
  PRIMARY KEY (id)
);
CREATE TABLE identifiers(
  id INTEGER NOT NULL AUTO_INCREMENT,
  value VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE orgs(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  name VARCHAR(255) NOT NULL,
  city VARCHAR(255),
  state VARCHAR(255),
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
  title VARCHAR(255) NOT NULL,
  description TEXT,
  license TEXT,
  publication_date VARCHAR(50),
  language VARCHAR(5),
  source_id INTEGER NOT NULL,
  source_json TEXT,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE sources(
  id INTEGER NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  last_download DATETIME,
  created_at TIMESTAMP,
  PRIMARY KEY (id)
);
CREATE TABLE types(
  id INTEGER NOT NULL AUTO_INCREMENT,
  value VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE api_scans(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  project_id INTEGER NOT NULL,
  last_scan DATETIME NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);

# JOIN TABLES
# -----------------------------------------------------
CREATE TABLE org_contributors(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  org_id INTEGER NOT NULL,
  contributor_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE org_identifiers(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  org_id INTEGER NOT NULL,
  identifier_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE org_types(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  org_id INTEGER NOT NULL,
  type_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE org_awards(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  award_id INTEGER NOT NULL,
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
CREATE TABLE award_contributors(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  award_id INTEGER NOT NULL,
  contributor_id INTEGER NOT NULL,
  type_id INTEGER,
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
  type_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE project_contributors(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  project_id INTEGER NOT NULL,
  contributor_id INTEGER NOT NULL,
  type_id INTEGER,
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
CREATE TABLE project_stages(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  project_id INTEGER NOT NULL,
  stage_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE project_documents(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  project_id INTEGER NOT NULL,
  document_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE stage_identifiers(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  stage_id INTEGER NOT NULL,
  identifier_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE stage_types(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  stage_id INTEGER NOT NULL,
  type_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE stage_contributors(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  stage_id INTEGER NOT NULL,
  contributor_id INTEGER NOT NULL,
  type_id INTEGER,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE document_identifiers(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  document_id INTEGER NOT NULL,
  identifier_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);
CREATE TABLE document_types(
  id INTEGER NOT NULL AUTO_INCREMENT,
  source_id INTEGER NOT NULL,
  document_id INTEGER NOT NULL,
  type_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id)
);

INSERT INTO sources (name) VALUES ('geome');
INSERT INTO sources (name) VALUES ('bco_dmo');
INSERT INTO sources (name) VALUES ('biocode');
INSERT INTO sources (name) VALUES ('nsf');
