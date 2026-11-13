-- Schema: "Information resources of the department"
-- 9 tables, InnoDB, utf8mb4.
-- Safe to re-run: drops tables in reverse dependency order first.

DROP TABLE IF EXISTS usage_stats;
DROP TABLE IF EXISTS resource_urls;
DROP TABLE IF EXISTS resource_authors;
DROP TABLE IF EXISTS resources;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS authors;
DROP TABLE IF EXISTS usage_conditions;
DROP TABLE IF EXISTS purposes;
DROP TABLE IF EXISTS kinds;

CREATE TABLE kinds (
  id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(64) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE purposes (
  id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(64) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE usage_conditions (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100) NOT NULL UNIQUE,
  description TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE authors (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  full_name   VARCHAR(150) NOT NULL,
  email       VARCHAR(150),
  affiliation VARCHAR(150)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE resources (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name         VARCHAR(255) NOT NULL,
  annotation   TEXT NOT NULL,
  kind_id      INT UNSIGNED NOT NULL,
  purpose_id   INT UNSIGNED NOT NULL,
  condition_id INT UNSIGNED NOT NULL,
  opened_on    DATE NOT NULL,
  term_text    VARCHAR(100) NOT NULL,
  valid_until  DATE NULL,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_resources_kind      FOREIGN KEY (kind_id)      REFERENCES kinds (id),
  CONSTRAINT fk_resources_purpose   FOREIGN KEY (purpose_id)   REFERENCES purposes (id),
  CONSTRAINT fk_resources_condition FOREIGN KEY (condition_id) REFERENCES usage_conditions (id),
  FULLTEXT KEY ft_resources (name, annotation)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE resource_authors (
  resource_id INT UNSIGNED NOT NULL,
  author_id   INT UNSIGNED NOT NULL,
  PRIMARY KEY (resource_id, author_id),
  CONSTRAINT fk_ra_resource FOREIGN KEY (resource_id) REFERENCES resources (id) ON DELETE CASCADE,
  CONSTRAINT fk_ra_author   FOREIGN KEY (author_id)   REFERENCES authors (id)   ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE resource_urls (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  resource_id INT UNSIGNED NOT NULL,
  url         VARCHAR(500) NOT NULL,
  label       VARCHAR(100),
  is_primary  BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT fk_urls_resource FOREIGN KEY (resource_id) REFERENCES resources (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE users (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  full_name  VARCHAR(150) NOT NULL,
  email      VARCHAR(150) NOT NULL UNIQUE,
  role       ENUM('student','teacher','staff') NOT NULL DEFAULT 'student',
  department VARCHAR(150)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE usage_stats (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id     INT UNSIGNED NOT NULL,
  resource_id INT UNSIGNED NOT NULL,
  used_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  action      ENUM('view','download','open') NOT NULL DEFAULT 'view',
  CONSTRAINT fk_stats_user     FOREIGN KEY (user_id)     REFERENCES users (id),
  CONSTRAINT fk_stats_resource FOREIGN KEY (resource_id) REFERENCES resources (id) ON DELETE CASCADE,
  KEY idx_stats_resource_time (resource_id, used_at),
  KEY idx_stats_user_time     (user_id, used_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
