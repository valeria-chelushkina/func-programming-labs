-- Demo data for the "Information resources of the department" system.
--
-- WARNING: this script resets all application tables before inserting.
-- It is meant for a demo/reset, not for a live database.
--
-- Run:
--   Get-Content .\sql\seed.sql -Raw |
--     docker exec -i fp-mysql mysql --default-character-set=utf8mb4 -uroot -proot dept_resources

SET NAMES utf8mb4;

DELETE FROM usage_stats;
DELETE FROM resource_urls;
DELETE FROM resource_authors;
DELETE FROM resources;
DELETE FROM users;
DELETE FROM authors;
DELETE FROM usage_conditions;
DELETE FROM purposes;
DELETE FROM kinds;

-- Dictionaries -------------------------------------------------------------

INSERT INTO kinds (id, name) VALUES
  (1, 'Електронний підручник'),
  (2, 'Навчальний посібник'),
  (3, 'Методичні вказівки'),
  (4, 'Відеолекція'),
  (5, 'Програмний засіб'),
  (6, 'База даних / датасет');

INSERT INTO purposes (id, name) VALUES
  (1, 'Навчання'),
  (2, 'Наукова робота'),
  (3, 'Методичне забезпечення'),
  (4, 'Адміністрування');

INSERT INTO usage_conditions (id, name, description) VALUES
  (1, 'Вільний доступ', 'Доступний усім без реєстрації'),
  (2, 'Лише для студентів', 'Потрібен студентський обліковий запис'),
  (3, 'За паролем', 'Пароль видає викладач'),
  (4, 'Ліцензія CC BY-NC', 'Дозволено некомерційне використання з посиланням');

-- Authors ------------------------------------------------------------------

INSERT INTO authors (id, full_name, email, affiliation) VALUES
  (1, 'Коваленко Олена Миколаївна', 'o.kovalenko@univ.edu.ua', 'Кафедра інформаційних систем'),
  (2, 'Шевченко Андрій Петрович', 'a.shevchenko@univ.edu.ua', 'Кафедра інформаційних систем'),
  (3, 'Бондар Ірина Василівна', 'i.bondar@univ.edu.ua', 'Кафедра програмної інженерії'),
  (4, 'Мельник Дмитро Олегович', 'd.melnyk@univ.edu.ua', 'Кафедра комп''ютерних мереж'),
  (5, 'Ткачук Наталія Сергіївна', 'n.tkachuk@univ.edu.ua', 'Кафедра інформаційних систем'),
  (6, 'Гриценко Павло Андрійович', 'p.grytsenko@univ.edu.ua', 'Наукова лабораторія кафедри');

-- Users --------------------------------------------------------------------

INSERT INTO users (id, full_name, email, role, department) VALUES
  (1, 'Іваненко Марія Сергіївна', 'm.ivanenko@student.univ.edu.ua', 'student', 'Інформаційні системи'),
  (2, 'Петренко Олег Вікторович', 'o.petrenko@student.univ.edu.ua', 'student', 'Інформаційні системи'),
  (3, 'Сидоренко Анна Ігорівна', 'a.sydorenko@univ.edu.ua', 'teacher', 'Кафедра інформаційних систем'),
  (4, 'Романюк Богдан Тарасович', 'b.romaniuk@univ.edu.ua', 'teacher', 'Кафедра програмної інженерії'),
  (5, 'Лисенко Оксана Петрівна', 'o.lysenko@univ.edu.ua', 'staff', 'Деканат факультету');

-- Resources ----------------------------------------------------------------

INSERT INTO resources
  (id, name, annotation, kind_id, purpose_id, condition_id, opened_on, term_text, valid_until)
VALUES
  (1, 'Основи функціонального програмування',
      'Підручник з базових понять функціонального програмування: чисті функції, рекурсія, списки, типи та монади.',
      1, 1, 1, '2023-09-01', 'Безстроково', NULL),
  (2, 'Практикум з Haskell',
      'Набір практичних завдань і прикладів для вивчення мови Haskell та роботи з GHC.',
      2, 1, 2, '2024-02-15', '3 роки', '2027-02-15'),
  (3, 'Методичні вказівки до лабораторних з баз даних',
      'Інструкції до лабораторних робіт із проєктування та нормалізації реляційних баз даних.',
      3, 3, 1, '2023-09-10', 'Безстроково', NULL),
  (4, 'Відеокурс з SQL',
      'Серія відеолекцій із запитів SELECT, JOIN, агрегатних функцій та транзакцій.',
      4, 1, 2, '2024-09-01', 'До завершення семестру', '2027-01-31'),
  (5, 'Система тестування знань',
      'Вебзастосунок для проведення проміжного та підсумкового тестування студентів.',
      5, 1, 3, '2022-11-20', 'Безстроково', NULL),
  (6, 'Датасет успішності студентів',
      'Анонімізований набір даних про результати навчання для наукових досліджень.',
      6, 2, 4, '2025-03-12', '2 роки', '2027-03-12'),
  (7, 'Конспект лекцій з теорії алгоритмів',
      'Стислий конспект з асимптотичної складності, сортування, графів і динамічного програмування.',
      1, 1, 1, '2023-02-01', 'Безстроково', NULL),
  (8, 'Лабораторний стенд з комп''ютерних мереж',
      'Віртуальний стенд для лабораторних робіт із маршрутизації та діагностики мереж.',
      5, 1, 3, '2024-10-05', '1 рік', '2026-10-05'),
  (9, 'Навчальний посібник з Python',
      'Вступ до Python для студентів першого курсу: синтаксис, колекції, файли, модулі.',
      2, 1, 1, '2024-09-01', 'Безстроково', NULL),
  (10, 'Архів наукових публікацій кафедри',
      'Електронний архів статей, тез і звітів викладачів кафедри за останні роки.',
      6, 2, 1, '2021-09-01', 'Безстроково', NULL);

-- Resource authors ---------------------------------------------------------

INSERT INTO resource_authors (resource_id, author_id) VALUES
  (1, 1), (1, 2),
  (2, 1),
  (3, 3),
  (4, 2),
  (5, 5),
  (6, 6),
  (7, 1),
  (8, 4),
  (9, 3),
  (10, 5), (10, 6);

-- Resource URLs ------------------------------------------------------------

INSERT INTO resource_urls (resource_id, url, label, is_primary) VALUES
  (1, 'https://res.univ.edu.ua/fp-textbook', 'основна', TRUE),
  (1, 'https://github.com/univ/fp-textbook', 'дзеркало', FALSE),
  (2, 'https://res.univ.edu.ua/haskell-workshop', 'основна', TRUE),
  (3, 'https://res.univ.edu.ua/db-labs', 'основна', TRUE),
  (4, 'https://res.univ.edu.ua/sql-video', 'основна', TRUE),
  (5, 'https://test.univ.edu.ua', 'вхід', TRUE),
  (6, 'https://data.univ.edu.ua/students', 'основна', TRUE),
  (7, 'https://res.univ.edu.ua/algorithms', 'основна', TRUE),
  (8, 'https://netlab.univ.edu.ua', 'стенд', TRUE),
  (9, 'https://res.univ.edu.ua/python', 'основна', TRUE),
  (10, 'https://archive.univ.edu.ua/publications', 'основна', TRUE);

-- Usage statistics ---------------------------------------------------------

INSERT INTO usage_stats (user_id, resource_id, used_at, action) VALUES
  (1, 1,  NOW() - INTERVAL 28 DAY, 'view'),
  (2, 1,  NOW() - INTERVAL 27 DAY, 'view'),
  (3, 1,  NOW() - INTERVAL 25 DAY, 'download'),
  (1, 1,  NOW() - INTERVAL 20 DAY, 'download'),
  (4, 1,  NOW() - INTERVAL 18 DAY, 'view'),
  (2, 1,  NOW() - INTERVAL 14 DAY, 'view'),
  (3, 1,  NOW() - INTERVAL 10 DAY, 'view'),
  (1, 1,  NOW() - INTERVAL  3 DAY, 'view'),

  (1, 2,  NOW() - INTERVAL 26 DAY, 'view'),
  (2, 2,  NOW() - INTERVAL 22 DAY, 'download'),
  (3, 2,  NOW() - INTERVAL 16 DAY, 'view'),
  (1, 2,  NOW() - INTERVAL  8 DAY, 'view'),
  (4, 2,  NOW() - INTERVAL  2 DAY, 'download'),

  (1, 3,  NOW() - INTERVAL 24 DAY, 'view'),
  (2, 3,  NOW() - INTERVAL 19 DAY, 'view'),
  (3, 3,  NOW() - INTERVAL  9 DAY, 'download'),
  (1, 3,  NOW() - INTERVAL  4 DAY, 'view'),

  (1, 4,  NOW() - INTERVAL 23 DAY, 'view'),
  (4, 4,  NOW() - INTERVAL 17 DAY, 'view'),
  (2, 4,  NOW() - INTERVAL 11 DAY, 'view'),
  (3, 4,  NOW() - INTERVAL  1 DAY, 'view'),

  (2, 5,  NOW() - INTERVAL 21 DAY, 'view'),
  (3, 5,  NOW() - INTERVAL 12 DAY, 'open'),
  (1, 5,  NOW() - INTERVAL  5 DAY, 'view'),

  (3, 6,  NOW() - INTERVAL 15 DAY, 'download'),
  (4, 6,  NOW() - INTERVAL  6 DAY, 'download'),

  (1, 7,  NOW() - INTERVAL 13 DAY, 'view'),
  (2, 8,  NOW() - INTERVAL  7 DAY, 'open'),
  (1, 9,  NOW() - INTERVAL  2 DAY, 'view'),
  (4, 10, NOW() - INTERVAL  1 DAY, 'view');
