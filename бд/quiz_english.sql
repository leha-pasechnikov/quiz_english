DROP DATABASE IF EXISTS english_tasks;
CREATE DATABASE english_tasks;
USE english_tasks;

-- Таблица админа
CREATE TABLE admin (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL
);

-- Таблица пользователей
CREATE TABLE user (
    id INT AUTO_INCREMENT PRIMARY KEY,
    last_name VARCHAR(255) NOT NULL,
    first_name VARCHAR(255) NOT NULL,
    middle_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    score INT NOT NULL,
    time_score TIMESTAMP NOT NULL, -- время изменения очков в триггере

    note TEXT(25000) NOT NULL -- заметки пользователя
);

-- Таблица слов
CREATE TABLE words (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    word VARCHAR(100),
    transcription VARCHAR(100),
    FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Таблица тем
CREATE TABLE topic (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL
);

-- Таблица разделов
CREATE TABLE section (
    id INT AUTO_INCREMENT PRIMARY KEY,
    topic_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    FOREIGN KEY (topic_id) REFERENCES topic(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- |--------------|-------------------|--------------|--------------|---------------|--------------|----------------|
-- |Таблица       | Атрибуты          | fix_word     | text_answer  | listen_answer | match        | multiple_choice|
-- |--------------|-------------------|--------------|--------------|---------------|--------------|----------------|
-- |              | id                |      +       |      +       |       +       |      +       |       +        |
-- |              | section_id        |      +       |      +       |       +       |      +       |       +        |
-- |              | hint              |     +-       |     +-       |      +-       |     +-       |      +-        |
-- | task         | title             |     +-       |     +-       |      +-       |     +-       |      +-        |
-- |              | text              |     +-       |     +-       |      +-       |     +-       |      +-        |
-- |              | text_after_answer |     +-       |     +-       |      +-       |     +-       |      +-        |
-- |              | file_link         |      -       |      -       |       +       |      -       |       -        |
-- |              | type              | fix_word     | text_answer  | listen_answer |    match     | multiple_choice|
-- |--------------|-------------------|--------------|--------------|---------------|--------------|----------------|
-- |              | id                |      +       |      +       |       +       |      +       |       +        |
-- |              | task_id           |      +       |      +       |       +       |      +       |       +        |
-- |              | title             |      +       |      -       |       -       |      +       |       +        |
-- | item         | text              |      +       |      -       |       -       |      -       |       +        |
-- |              | points            |      +       |      +       |       +       |      +       |       +        |
-- |              | number            |      +       |      +       |       +       |      -       |       -        |
-- |--------------|------------------ |--------------|--------------|---------------|--------------|----------------|
-- |              | id                |      +       |      +       |       +       |      +       |       +        |
-- |              | item_id           |      +       |      +       |       +       |      +       |       +        |
-- |answer_option | left_text         |      -       |      +       |       -       |      +       |       -        |
-- |              | text              |      +       |      +       |       +       |      +       |       +        |
-- |              | is_correct        |      T       |     T/F      |       T       |      T       |       T        |
-- |--------------|-------------------|--------------|--------------|---------------|--------------|----------------|

-- + NOT NULL нужно заполнить
-- +- NULL можно заполнить можно не заполнять
-- - NULL нельзя заполнять
-- T - только TRUE
-- T/F - TRUE ИЛИ FALSE не NULL

CREATE TABLE task (
    id INT AUTO_INCREMENT PRIMARY KEY,
    section_id INT NOT NULL,
    hint TEXT NULL, -- подсказка
    title VARCHAR(255) NULL, -- название
    text TEXT NULL, -- текст задания если есть
    text_after_answer TEXT NULL, -- текст появляющийся после ответа
    file_link VARCHAR(255), -- Путь к файлу, если есть
    type ENUM('fix_word', 'text_answer', 'listen_answer', 'match', 'multiple_choice') NOT NULL, -- тип задания (write - ввод, choose - выбор, match - сопоставление)
    FOREIGN KEY (section_id) REFERENCES section(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Таблица пунктов (вопросы в задании)
CREATE TABLE item (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task_id INT NOT NULL,
    title VARCHAR(255) NULL, -- название пункта
    number VARCHAR(10) NULL, -- номер пункта если надо
    text TEXT NULL, -- содержание пунктов если надо
    points INT NOT NULL, -- кол-во баллов за один верный ответ
    FOREIGN KEY (task_id) REFERENCES task(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Таблица вариантов ответов
-- * для типа "choose" (со связью 1 к n):
-- left_text NULL, text - вариант ответа, is_correct - правильный ли
-- * для типа "write" (со связью 1 к n):
-- left_text NULL, text - вариант ответа, is_correct - 1
-- * для типа "match" (со связью 1 к n):
-- left_text левое сопоставление, text - правое сопоставление, is_correct - 1
CREATE TABLE answer_option (
    id INT AUTO_INCREMENT PRIMARY KEY,
    item_id INT NOT NULL,
    left_text TEXT NULL,  -- Левая часть сопоставления
    text TEXT NOT NULL, -- Текст варианта ответа
    is_correct BOOLEAN NOT NULL, -- Правильный ли ответ
    FOREIGN KEY (item_id) REFERENCES item(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Таблица ответов пользователей на варианты ответов
CREATE TABLE answer_option_result (
    id INT AUTO_INCREMENT PRIMARY KEY,
    answer_option_id INT NOT NULL,
    user_id INT NOT NULL,
    text TEXT NULL, -- Текст ответа пользователя, если тип "write"
    -- is_correct BOOLEAN NOT NULL, -- Ответ отмечен верным или нет, если тип "choose"
    UNIQUE (answer_option_id, user_id),
    FOREIGN KEY (answer_option_id) REFERENCES answer_option(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE ON UPDATE CASCADE
);


DELIMITER //

CREATE TRIGGER before_insert_user
BEFORE INSERT ON user
FOR EACH ROW
BEGIN
    -- Хешируем пароль с использованием SHA2 (256 бит)
    IF NEW.password IS NOT NULL AND NEW.password != '' THEN
        SET NEW.password = SHA2(NEW.password, 256);
    END IF;
END;

//
DELIMITER ;

DELIMITER //

CREATE TRIGGER before_update_user
BEFORE UPDATE ON user
FOR EACH ROW
BEGIN
    -- Если новый пароль не пустой, хешируем его
    IF NEW.password IS NOT NULL AND NEW.password != '' THEN
        SET NEW.password = SHA2(NEW.password, 256);
    END IF;
END;

//
DELIMITER ;

DELIMITER //

CREATE TRIGGER before_insert_admin
BEFORE INSERT ON admin
FOR EACH ROW
BEGIN
    -- Хешируем пароль с использованием SHA2 (256 бит)
    IF NEW.password IS NOT NULL AND NEW.password != '' THEN
        SET NEW.password = SHA2(NEW.password, 256);
    END IF;
END;

//
DELIMITER ;

DELIMITER //

CREATE TRIGGER before_update_admin
BEFORE UPDATE ON admin
FOR EACH ROW
BEGIN
    -- Если новый пароль не пустой, хешируем его
    IF NEW.password IS NOT NULL AND NEW.password != '' THEN
        SET NEW.password = SHA2(NEW.password, 256);
    END IF;
END;

//
DELIMITER ;


DELIMITER $$

CREATE TRIGGER task_before_insert
BEFORE INSERT ON task
FOR EACH ROW
BEGIN
    DECLARE type_text VARCHAR(255);

    IF NEW.type = 'listen_answer' THEN
        IF NEW.file_link IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: file_link для listen_answer не может быть пустым';
        END IF;
    ELSE
        IF NEW.file_link IS NOT NULL THEN
            SET type_text = CONCAT('Ошибка: file_link для ', NEW.type, ' должен быть пустым');
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = type_text;
        END IF;
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER task_before_update
BEFORE UPDATE ON task
FOR EACH ROW
BEGIN
    DECLARE type_text VARCHAR(255);
    DECLARE item_count INT;

    -- Проверка на наличие зависимых записей в таблице item
    SELECT COUNT(*) INTO item_count FROM item WHERE task_id = OLD.id;

    IF item_count > 0 AND NEW.type != OLD.type THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: Нельзя изменить тип задачи, на которую ссылается таблица item.';
    END IF;

    IF NEW.type = 'listen_answer' THEN
        IF NEW.file_link IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: file_link для listen_answer не может быть пустым';
        END IF;
    ELSE
        IF NEW.file_link IS NOT NULL THEN
            SET type_text = CONCAT('Ошибка: file_link для ', NEW.type, ' должен быть пустым');
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = type_text;
        END IF;
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER item_before_insert
BEFORE INSERT ON item
FOR EACH ROW
BEGIN
    DECLARE task_type VARCHAR(255);

    -- Получаем тип задачи из таблицы task по task_id
    SELECT type INTO task_type FROM task WHERE id = NEW.task_id;

    -- Проверка типа задачи
    IF task_type IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: Не найден тип задачи';
    ELSEIF task_type = 'fix_word' THEN
        IF NEW.title IS NULL THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: title для fix_word не может быть пустым';
        ELSEIF NEW.text IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: text для fix_word не может быть пустым';
		ELSEIF NEW.points IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: points для fix_word не может быть пустым';
		ELSEIF NEW.number IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: number для fix_word не может быть пустым';
        END IF;
	ELSEIF task_type = 'text_answer' THEN
        IF NEW.title IS NOT NULL THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: title для text_answer должен быть пустым';
        ELSEIF NEW.text IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: text для text_answer должен быть пустым';
		ELSEIF NEW.points IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: points для text_answer не может быть пустым';
		ELSEIF NEW.number IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: number для text_answer не может быть пустым';
        END IF;
	ELSEIF task_type = 'listen_answer' THEN
        IF NEW.title IS NOT NULL THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: title для listen_answer должен быть пустым';
        ELSEIF NEW.text IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: text для listen_answer должен быть пустым';
		ELSEIF NEW.points IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: points для listen_answer не может быть пустым';
		ELSEIF NEW.number IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: number для listen_answer не может быть пустым';
        END IF;
	ELSEIF task_type = 'match' THEN
        IF NEW.title IS NULL THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: title для match не может быть пустым';
        ELSEIF NEW.text IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: text для match должен быть пустым';
		ELSEIF NEW.points IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: points для match не может быть пустым';
		ELSEIF NEW.number IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: number для match должен быть пустым';
        END IF;
	ELSEIF task_type = 'multiple_choice' THEN
        IF NEW.title IS NULL THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: title для match не может быть пустым';
        ELSEIF NEW.text IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: text для match не может быть пустым';
		ELSEIF NEW.points IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: points для match не может быть пустым';
		ELSEIF NEW.number IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: number для match должен быть пустым';
        END IF;
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER item_before_update
BEFORE UPDATE ON item
FOR EACH ROW
BEGIN
    DECLARE task_type VARCHAR(255);

    -- Получаем тип задачи из таблицы task по task_id
    SELECT type INTO task_type FROM task WHERE id = NEW.task_id;

    -- Проверка типа задачи
    IF task_type IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: Не найден тип задачи';
    ELSEIF task_type = 'fix_word' THEN
        IF NEW.title IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: title для fix_word не может быть пустым';
        ELSEIF NEW.text IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: text для fix_word не может быть пустым';
        ELSEIF NEW.points IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: points для fix_word не может быть пустым';
        ELSEIF NEW.number IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: number для fix_word не может быть пустым';
        END IF;
    ELSEIF task_type = 'text_answer' THEN
        IF NEW.title IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: title для text_answer должен быть пустым';
        ELSEIF NEW.text IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: text для text_answer должен быть пустым';
        ELSEIF NEW.points IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: points для text_answer не может быть пустым';
        ELSEIF NEW.number IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: number для text_answer не может быть пустым';
        END IF;
    ELSEIF task_type = 'listen_answer' THEN
        IF NEW.title IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: title для listen_answer должен быть пустым';
        ELSEIF NEW.text IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: text для listen_answer должен быть пустым';
        ELSEIF NEW.points IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: points для listen_answer не может быть пустым';
        ELSEIF NEW.number IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: number для listen_answer не может быть пустым';
        END IF;
    ELSEIF task_type = 'match' THEN
        IF NEW.title IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: title для match не может быть пустым';
        ELSEIF NEW.text IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: text для match должен быть пустым';
        ELSEIF NEW.points IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: points для match не может быть пустым';
        ELSEIF NEW.number IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: number для match должен быть пустым';
        END IF;
    ELSEIF task_type = 'multiple_choice' THEN
        IF NEW.title IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: title для multiple_choice не может быть пустым';
        ELSEIF NEW.text IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: text для multiple_choice не может быть пустым';
        ELSEIF NEW.points IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: points для multiple_choice не может быть пустым';
        ELSEIF NEW.number IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: number для multiple_choice должен быть пустым';
        END IF;
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE TRIGGER answer_option_before_insert
BEFORE INSERT ON answer_option
FOR EACH ROW
BEGIN
    DECLARE task_type VARCHAR(255);

    -- Получаем тип задачи из таблицы task по task_id
    SELECT task.type INTO task_type
    FROM task
    JOIN item ON item.task_id = task.id
    WHERE item.id = NEW.item_id;

    -- Проверка типа задачи
    IF task_type IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: Не найден тип задачи';
    ELSEIF task_type = 'fix_word' THEN
        IF NEW.left_text IS NOT NULL THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: left_text для fix_word должно быть пустым';
        ELSEIF NEW.text IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: text для fix_word не может быть пустым';
		ELSEIF NEW.is_correct != TRUE THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: is_correct для fix_word должен быть True';
        END IF;
	ELSEIF task_type = 'text_answer' THEN
        IF NEW.left_text IS NULL THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: left_text для text_answer не может быть пустым';
        ELSEIF NEW.text IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: text для text_answer не может быть пустым';
		ELSEIF NEW.is_correct is NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: is_correct для text_answer не может быть пустым';
        END IF;
	ELSEIF task_type = 'listen_answer' THEN
        IF NEW.left_text IS NOT NULL THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: left_text для listen_answer должен быть пустым';
        ELSEIF NEW.text IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: text для listen_answer не может быть пустым';
		ELSEIF NEW.is_correct != TRUE THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: is_correct для listen_answer должен быть True';
        END IF;
	ELSEIF task_type = 'match' THEN
        IF NEW.left_text IS NULL THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: left_text для match не может быть пустым';
        ELSEIF NEW.text IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: text для match не может быть пустым';
		ELSEIF NEW.is_correct != TRUE THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: is_correct для match должен быть True';
        END IF;
	ELSEIF task_type = 'multiple_choice' THEN
        IF NEW.left_text IS NOT NULL THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: left_text для match должен быть пустым';
        ELSEIF NEW.text IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: text для match не может быть пустым';
		ELSEIF NEW.is_correct != TRUE THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: is_correct для match должен быть True';
        END IF;
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER answer_option_before_update
BEFORE UPDATE ON answer_option
FOR EACH ROW
BEGIN
    DECLARE task_type VARCHAR(255);

    -- Получаем тип задачи из таблицы task по task_id
    SELECT task.type INTO task_type
    FROM task
    JOIN item ON item.task_id = task.id
    WHERE item.id = NEW.item_id;

    -- Проверка типа задачи
    IF task_type IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: Не найден тип задачи';
    ELSEIF task_type = 'fix_word' THEN
        IF NEW.left_text IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: left_text для fix_word должно быть пустым';
        ELSEIF NEW.text IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: text для fix_word не может быть пустым';
        ELSEIF NEW.is_correct != TRUE THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: is_correct для fix_word должен быть True';
        END IF;
    ELSEIF task_type = 'text_answer' THEN
        IF NEW.left_text IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: left_text для text_answer не может быть пустым';
        ELSEIF NEW.text IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: text для text_answer не может быть пустым';
        ELSEIF NEW.is_correct IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: is_correct для text_answer не может быть пустым';
        END IF;
    ELSEIF task_type = 'listen_answer' THEN
        IF NEW.left_text IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: left_text для listen_answer должен быть пустым';
        ELSEIF NEW.text IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: text для listen_answer не может быть пустым';
        ELSEIF NEW.is_correct != TRUE THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: is_correct для listen_answer должен быть True';
        END IF;
    ELSEIF task_type = 'match' THEN
        IF NEW.left_text IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: left_text для match не может быть пустым';
        ELSEIF NEW.text IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: text для match не может быть пустым';
        ELSEIF NEW.is_correct != TRUE THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: is_correct для match должен быть True';
        END IF;
    ELSEIF task_type = 'multiple_choice' THEN
        IF NEW.left_text IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: left_text для multiple_choice должен быть пустым';
        ELSEIF NEW.text IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: text для multiple_choice не может быть пустым';
        ELSEIF NEW.is_correct != TRUE THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ошибка: is_correct для multiple_choice должен быть True';
        END IF;
    END IF;
END$$

DELIMITER ;







INSERT INTO admin(username, password) VALUES ("admin","admin");

INSERT INTO user (last_name, first_name, middle_name, email, username, password, score, time_score, note) VALUES
('Иванов', 'Иван', 'Иванович', 'ivanov1@example.com', 'login1', 'pass1', 15, '2024-02-24 18:20:20', ''),
('Петров', 'Петр', 'Петрович', 'petrov2@example.com', 'login2', 'pass2', 18, '2024-02-24 18:20:21', ''),
('Сидоров', 'Сидор', 'Сидорович', 'sidorov3@example.com', 'login3', 'pass3', 18, '2024-02-24 18:20:20', ''),
('Кузнецов', 'Алексей', 'Алексеевич', 'kuznetsov4@example.com', 'login4', 'pass4', 20, '2024-02-24 18:20:20', '');

SELECT username, score, time_score FROM user ORDER BY score DESC, time_score ASC;

INSERT INTO topic(id, title) VALUES
(1, "Military arts"),
(2, "Military-Political Outcomes and Lessons of the War"),
(3, "The causes of the Second World War"),
(4, "The main events of the Second World War"),
(5, "Вопросы для итоговой викторины");

INSERT INTO section(id,topic_id,title) VALUES
(1,1,"Grammar and Vocabulary"),
(2,1,"Listening"),
(3,1,"Reading"),
(4,1,"Test yourself"),

(5, 2, "Grammar and Vocabulary"),
(6, 2, "Listening"),
(7, 2, "Reading"),
(8, 2, "Test yourself"),

(9, 3, "Grammar and Vocabulary"),
(10, 3, "Listening"),
(11, 3, "Reading"),
(12, 3, "Test yourself"),

(13, 4, "Grammar and Vocabulary"),
(14, 4, "Listening"),
(15, 4, "Reading"),
(16, 4, "Test yourself");

-- Military arts
-- Grammar and Vocabulary
INSERT INTO task(id,section_id, hint, title, file_link, text, text_after_answer, type) VALUES
(1,1,
"Прочитайте приведённый ниже текст / приведённые ниже тексты. Преобразуйте,
если необходимо, слова, напечатанные заглавными буквами в конце строк,
обозначенных номерами 1–7, так, чтобы они грамматически соответствовали
содержанию текстов. Заполните пропуски полученными словами.",
"The El Alamein operation",
null,
null,
null,
"fix_word"),
(2,1,
"Прочитайте приведённый ниже текст. Образуйте от слов, напечатанных заглавными
буквами в конце строк, обозначенных номерами 8–17, однокоренные слова так, чтобы
они грамматически и лексически соответствовали содержанию текста. Заполните
пропуски полученными словами.",
null,
null,
null,
null,
"fix_word"),
(3,1,
"Прочитайте текст с пропусками, обозначенными номерами 18–25. Эти номера
соответствуют заданиям 18–25, в которых представлены возможные варианты
ответов. Запишите в поле ответа цифру 1, 2, 3 или 4, соответствующую выбранному
Вами варианту ответа.",
null,
null,
"The military strategy of the Allies during World War II was enriched not only by their
experience of conducting large-scale amphibious operations, but also by their experience in
planning and executing operations involving various types of forces, coordinating their efforts,
and providing comprehensive support. The success of their fighting efforts was largely
achieved 18._________ the use of disguise and deception tactics, the resolute concentration of
forces and resources, and the effective suppression of enemy fire.
The military operations in the Pacific Ocean, 19 __________ they had a wide spatial
scope, were less intense than the armed struggle in other theatres of war, not only on the
Eastern European front (the Soviet-German front) but also in Western Europe, in Italy and
France. The Allies deployed four field armies, three fleets, three air armies, 20 ________
various formations and units from the ground forces, navy, and air force, to participate in the
Pacific campaign. Despite the unique conditions of the naval theatre, the operational tasks
were typically solved through the combined efforts of all branches of the armed forces.
Significant changes have occurred 21 __________ the perception of the role and
importance of various branches of the navy. 22 ___________ 1944, aircraft carriers have
replaced battleships as the main force in naval operations. These aircraft carrier task forces
consist of 4 to 8 or 8 to 16 aircraft carriers, along with surface ships and submarines to support
their operations. Unlike in the Western European and Mediterranean theatres, only 1 to 2
divisions were typically involved in amphibious operations in the Pacific, with 7 divisions
participating in some of the larger operations. In 23 __________ cases, ground forces were
supported by a significant number of aircraft and naval assets. During planning, emphasis was
placed on reconnaissance, air superiority, and surprise.
Given the vast distances between Pacific islands, the deployment of Allied fleets on
mobile bases played an important role. These bases consisted 24 ________ floating docks,
workshops, tankers, and transport ships with material supplies. This allowed for the
replenishment of supplies, minor repairs to ships 25 ________ sea, and the maintenance of
ships and aircraft in combat areas for longer periods of time.",
null,
"text_answer");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(1, 1, "INVOLVE",
"Despite the much lower intensity of armed conflict _________ the Allied forces, the geographic scope of military operations they conducted covered almost the entire globe.",
1, "1"),
(2, 1, "BE",
"The El Alamein operation (October 23 - November 27, 1942) _____________ a major offensive operation by Allied forces (led by British 8th Army, under Lieutenant General Bernard Montgomery) aimed at defeating the Italo-German forces in Africa (led by Field Marshal Erwin Rommel) and gaining the strategic advantage in the struggle for control of the Mediterranean coast in North Africa.",
1, "2"),
(3, 1, "FOLLOW",
"The plan was to break through enemy defenses through two main and auxiliary attacks, ________ by further advance by armored units.",
1, "3"),
(4, 1, "PENETRATE",
"However, after four days of fighting, the Allies _______________ 3-5 kilometers into enemy lines and suffered significant casualties - losses among armored divisions reached up to 40%.",
1, "4"),
(5, 1, "DECEIVE",
"The El Alamein offensive is instructive for the careful preparation of future Allied offensives. It involved measures __________ the enemy about the location of the main attack, such as lighting the battlefield at night with light reflected from clouds and illuminating the dividing lines between units with candles in cans facing the enemy.",
1, "5"),
(6, 1, "MASS",
"Additionally, forces and equipment _______ in the area of the breakthrough.",
1, "6"),
(7, 1, "BE",
"However, the experience from El Alamein confirmed that the biggest challenge in Allied offensive operations was breaking through the enemy defenses, which ______often narrow (3-8 kilometers) and slow-moving.",
1, "7");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(8, 2, "INCLUDE",
"The Normandy landings, also known as Operation Neptune, were a series of military operations conducted by the Allied forces, __________ the United States, Britain, and Canada, between June 6 and July 24, 1944.",
1, "8"),
(9, 2, "STRATEGY",
"The goal of these operations was to establish a _________ foothold on the coast of Normandy, France, in order to launch a subsequent offensive towards Germany. The landing sites were located on the coast, extending 80 kilometers in length and 100 kilometers deep.",
1, "9"),
(10, 2, "ONE",
"The Normandy amphibious operation took place in two stages. In the _________ stage, from June 6 to 12, 1944, under conditions of absolute dominance at sea and air, Allied forces managed to establish a beachhead up to 80 kilometers along the front line and 13 to 15 kilometers deep on the coast of the Seine Gulf, and landed up to 12 divisions in Normandy.",
1, "10"),
(11, 2, "DEEP",
"In the second stage, from June 13 to July 24, the beachhead was expanded to 100 kilometers along the frontline and 20 to 40 kilometers in ______.",
1, "11"),
(12, 2, "TWO",
"By the end of July, Anglo-American and Canadian forces had reached the Lesse Line, south of Saint-Lo and Caumont and east of Winstream, marking the start of the opening of a ________ front in Europe.",
1, "12"),
(13, 2, "FAR",
"As a result of the operation, conditions were created for a _______ Allied offensive in Western Europe. Allied forces and assets outnumbered the Nazi group 2.5 times in terms of personnel, 2.8 times in terms of tanks, and 13 times in terms of aviation.",
1, "13"),
(14, 2, "OPERATE",
"By the end of the ___________, there were 32 Allied divisions on the beachhead, with up to 2,500 tanks operating as part of these forces, and 11,000 combat aircraft supporting them from the air.",
1, "14"),
(15, 2, "AMPHIBIA",
"From a military perspective, the experience of the Allied forces in planning and executing the largest ________ operation of World War II, the Normandy Landings, is of great interest.",
1, "15"),
(16, 2, "LOCATE",
"The operation was instructive in terms of deceiving the enemy about the ________ of the landing and, as a result, achieving surprise.",
1, "16"),
(17, 2, "DEFEND",
"It also involved careful planning and organization of the interaction between large naval forces and ground forces, as well as aircraft during the invasion of an _________ coast, aiming for reliable suppression of enemy fire and comprehensive support.",
1, "17");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(18,3,null,null,1,"18"),
(19,3,null,null,1,"19"),
(20,3,null,null,1,"20"),
(21,3,null,null,1,"21"),
(22,3,null,null,1,"22"),
(23,3,null,null,1,"23"),
(24,3,null,null,1,"24"),
(25,3,null,null,1,"25");

INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(1,1,null, "involving", True),
(2,2,null, "was", True),
(3, 3, NULL, "followed", TRUE),
(4, 4, NULL, "had penetrated", TRUE),
(5, 5, NULL, "to deceive", TRUE),
(6, 6, NULL, "were massed", TRUE),
(7, 7, NULL, "were", TRUE),
(8, 8, NULL, "including", TRUE),
(9, 9, NULL, "strategic", TRUE),
(10, 10, NULL, "first", TRUE),
(11, 11, NULL, "depth", TRUE),
(12, 12, NULL, "second", TRUE),
(13, 13, NULL, "further", TRUE),
(14, 14, NULL, "operation", TRUE),
(15, 15, NULL, "amphibious", TRUE),
(16, 16, NULL, "location", TRUE),
(17, 17, NULL, "undefended", TRUE);

INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(18,18,'1',"1) by", False),
(19,18,'2',"2)	through", True),
(20,18,'3',"3)	to", False),
(21,18,'4',"4)	at", False),

(22, 19, '1', "1) although", True),
(23, 19, '2', "2) despite of", False),
(24, 19, '3', "3) since", False),
(25, 19, '4', "4) moreover", False),

(26, 20, '1', "1) of", False),
(27, 20, '2', "2) as well as", True),
(28, 20, '3', "3) by", False),
(29, 20, '4', "4) along", False),

(30, 21, '1', "1) at", False),
(31, 21, '2', "2) since", False),
(32, 21, '3', "3) over", False),
(33, 21, '4', "4) in", True),

(34, 22, '1', "1) by", False),
(35, 22, '2', "2) in", False),
(36, 22, '3', "3) since", True),
(37, 22, '4', "4) after", False),

(38, 23, '1', "1) everyone", False),
(39, 23, '2', "2) no one", False),
(40, 23, '3', "3) all", True),
(41, 23, '4', "4) any", False),

(42, 24, '1', "1) of", True),
(43, 24, '2', "2) by", False),
(44, 24, '3', "3) in", False),
(45, 24, '4', "4) over", False),

(46, 25, '1', "1) above", False),
(47, 25, '2', "2) at", True),
(48, 25, '3', "3) beyond", False),
(49, 25, '4', "4) over", False);

-- Listening
INSERT INTO task(id,section_id, hint, title, file_link, text, text_after_answer, type) VALUES
(4,2,
"Вы услышите монолог. Определите, какие из приведённых утверждений А–G соответствуют содержанию текста (1 – True), какие не соответствуют (2 – False) и о чём в тексте не сказано, то есть на основании текста нельзя дать ни положительного, ни отрицательного ответа (3 – Not stated). Занесите номер выбранного Вами варианта ответа в таблицу. Вы услышите запись дважды.",
null,
"audio.mp3",
"A.	 Three periods saw the use of strategic defense: the summer and fall of 1941, the summer and fall of 1942, and the summer of 1943.
B.	 During the intense summer-autumn fighting of 1941, Soviet forces launched approximately 120 counterattacks and offensive operations in front-line positions.
C.	The anti-Soviet orientation of Japan's foreign policy led to considering the USSR as the main land-based enemy and the United States as the primary sea-based adversary.
D.	During the fighting on the Soviet-German front, four of the eight major military campaigns were initiated by offensive actions.
E.	 The strategic offensive succeeded due to the clandestine buildup of offensive forces and reserves, and successful deception tactics to gain surprise.
F.	 Despite carrying out some independent strategic tasks, the Soviet Navy and Air Force primarily directed their efforts toward supporting the ground forces.
G.	 The Navy had an essential wartime and air strategic task: the protection of water routes, to safeguard transit of forces, people, war materials and economic necessities.
H.	 Thus, in the political and military circles of Germany, Italy, and Japan on the eve of World War II, there were plans for world domination and a reorganization of the world order in their favor.
I.	 The rapprochement between militaristic Japan, Germany, and Italy on the eve of World War II was not an accident.
J.	 Soviet naval strategy during the war was characterized by the full allocation of resources to primary missions.
",
"During the Great Patriotic War, Soviet military art saw the development of strategies, operational art, and tactics. The Soviet strategy, as a theory and practice of warfare, was enriched by the experiences of strategic defense and offensive (counter-offensive).
Strategic defense was employed three times: in the summer and autumn campaigns of 1941 and 1942, and in the summer of 1943. In the first two instances, the defense was imposed, as the enemy had the initiative and the ability to determine the course, time, and place of action. In 1943, however, the Red Army held the strategic initiative, superiority in forces and resources, and large strategic reserves.
A characteristic feature of the Soviet defense strategy, especially in forced situations, was its active nature, with a desire to conduct offensive operations, counterattacks, air strikes, and artillery strikes, as well as maneuvers (regroupings) of forces and equipment. For example, during the summer-autumn campaign of 1941, the Soviet troops conducted approximately 20 front-line counterattacks and offensive operations.
In order to increase the stability of their defense, the Soviet military leadership early on created deeply entrenched lines of defense.
The main form of strategic defense was the strategic operation of the front. During the first months of the Great Patriotic War, it became clear that the efforts
of one front alone were often insufficient to successfully defend against the enemy's attacks. This led to the realization that it was necessary to use a group of fronts in order to solve strategic defense tasks. This was a new development in Soviet military strategy.
The predominant and decisive type of strategic action of the Red Army during the Great Patriotic War was strategic offensive. Of the eight military campaigns on the Soviet-German front, six were offensive. Strategic offensive was carried out by conducting frontline and depth operations either in one or two strategic directions (during the second period of war) or on the entire Soviet-German front (during 1944 campaigns). It could also be conducted simultaneously in all major strategic directions or on the whole front (during winter campaign of 1941-42 and 1945 campaign). If strategic offensive started after strategic defense, it was counteroffensive. Counteroffensive actions of Red Army near Moscow (1941), Stalingrad (1942), and Kursk (1943) were successful.
The success of the strategic offensive was facilitated by the secret creation of offensive troops and strategic reserves, as well as measures to deceive the enemy in order to achieve surprise. The correct timing of the offensive and the conquest of air supremacy were also important factors.
The main methods used to defeat the enemy in strategic operations included encircling large groups and destroying them (Stalingrad and Iasi-Kishinev), dissecting the strategic front (Belgorod-Kharkov) or fragmenting it (Orel and Dnieper-Carpathian), and delivering a powerful enveloping strike to pin enemy groups to a natural frontier they could not easily cross (for example, the sea in the East Prussian operation). These methods were often combined, and one developed into another.
The Great Patriotic War was a long and difficult struggle, primarily between ground armies. Although the Soviet Navy and Air Force independently performed some important tasks of strategic significance, they focused their main efforts on supporting the ground forces.
The strategic use of the air force was based on the principle of massing their efforts in critical areas and sectors of the front. For this purpose, powerful aviation groups were formed. These groups were created by transferring aviation formations from other fronts and aviation units from the Supreme Command's reserve, as well as by involving long-range aircraft in solving key tasks.
The Soviet Navy performed two main groups of tasks during the war. The first group included joint actions with the Red Army and participation in defensive and offensive operations on the front lines and in strategic areas near the coast, as well as in lake and river regions. The second group consisted of independent combat operations and actions on sea communications in order to protect their own communications and disrupt the enemy's maritime communication systems.
An important strategic task for the Navy during the Great Patriotic War was to protect sea, lake, and river communications in order to ensure the safe transportation of troops, civilians, military equipment, and national economic goods via waterways. This became especially important during a time when other methods of supplying and replenishing troops were no longer feasible (such as defending naval bases, coastal towns, and bridgeheads).
During the war, the Soviet fleet transported more than 10 million military personnel, over 105 million tons of military equipment and national economic cargo, as well as 17 million tons of supplies from the Allies through external maritime routes.
Characteristic features of Soviet naval warfare during the Great Patriotic War included:
- Determination of goals and action plans to fulfill assigned tasks
- Calculated choice of target and location for main impact or effort concentration
– The massing of forces in a crucial direction and their subsequent separation, which provides the opportunity for increased efforts in the future.
– The primary and fullest possible provision of forces for the main tasks.
– Careful organization of the interaction between heterogeneous forces, both among themselves and within each type of force.
",
"listen_answer");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(26,4,null,null,1,"A"),
(27,4,null,null,1,"B"),
(28,4,null,null,1,"C"),
(29,4,null,null,1,"D"),
(30,4,null,null,1,"E"),
(31,4,null,null,1,"F"),
(32,4,null,null,1,"G"),
(33,4,null,null,1,"H"),
(34,4,null,null,1,"I"),
(35,4,null,null,1,"J");

INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(50,26,null, "1", True),
(51,27,null, "2", True),
(52,28,null, "3", True),
(53,29,null, "2", True),
(54,30,null, "1", True),
(55,31,null, "1", True),
(56,32,null, "2", True),
(57,33,null, "3", True),
(58,34,null, "3", True),
(59,35,null, "1", True);

-- Reading
INSERT INTO task(id,section_id, hint, title, file_link, text, text_after_answer, type) VALUES
(5,3,
"Установите соответствие между текстами A–G и заголовками 1–8.
Занесите свои ответы в таблицу. Используйте каждую цифру только
один раз. В задании один заголовок лишний.
",
null,
null,
"A.
The Battle of Moscow was a series of defensive and offensive operations conducted by the Soviet troops during the Great Patriotic War. It took place in the western strategic direction, with the goal of defending Moscow and the central industrial region, as well as defeating the threatening German forces from Army Group Center.
The significance of the Battle of Moscow extends beyond the borders of the Soviet Union:
1. It deterred Japan and Turkey from joining the war on Germany's side.
2. It marked a fundamental turning point in the course of the war.
3. It demonstrated the crisis of Germany's \"blitzkrieg\" strategy.
4. It was Germany's first major setback since September 1939.
5. During the Battle of Moscow, Soviet military strategy was further refined. The command was able to prepare and consolidate reserves, organizing close cooperation between fronts in the central area of the Soviet-German front. The success of the counteroffensive near Moscow was aided by offensive operations of Red Army forces in the northwestern direction near Leningrad (the Tikhvin offensive, November 10 - December 30, 1942) and in the southern area in the Rostov region (the Rostov offensive, November 17 - December 2, 1941).

B.
The Battle for Leningrad, which lasted from July 10, 1941 to August 9, 1944, was a combination of defensive and offensive operations by the Red Army in the northwestern strategic direction aimed at protecting the city and defeating the Nazi troops.
An important role in defending Leningrad from sea attacks was played by the heroic defenses of the Moonsund Islands, Hanko Peninsula, Tallinn naval base, Oranienbaum bridgehead, and Kronstadt. Between July and September, a well-fortified system of defensive lines was established directly around Leningrad. Overall, the failure of enemy plans to capture the city led to the collapse of German intentions to transfer their main forces from Army Group North towards Moscow.
The failures of the Soviet offensive operations near Leningrad in 1942, in the Lyuban and Sinyavin areas, were taken into consideration by the Soviet high command. According to the plans of the Supreme Command, the successful operations of the Red Army to break the Siege of Leningrad would be assisted by offensive actions in the Stalingrad region.
As a result of the offensives of the Leningrad, Volkhov, and 2nd Baltic fronts in the Leningrad-Novgorod operation (January 14 - March 1, 1944), Army Group North suffered a severe defeat, almost completely liberating the entire Leningrad region and part of the Kalinin region. The date of January 27 was designated as the Day of Military Glory of Russia, commemorating the lifting of the Siege of Leningrad. Soviet troops also entered the borders of Estonia, creating favorable conditions for the defeat of the enemy in the Baltics.

C.
The Battle of Stalingrad was a series of defensive (July 17 - November 18, 1942) and offensive operations (November 19, 1942 - February 2, 1943) conducted by Soviet troops during the Great Patriotic War, with the goal of defending Stalingrad (now known as Volgograd) and defeating a group of German troops operating in that region.
During the battles for Stalingrad, tactics such as street fighting, coordinated assaults by infantry units, and sniper engagements became prominent.
Even during the defensive battle, the Soviet command began to concentrate forces in order to launch a counteroffensive. The covert preparations for this operation lasted from September until mid-November 1942. At the same time, large-scale measures were taken to deceive the enemy, including conducting a strategic offensive in the area of the Rzhev-Vyazma salient.
Taking into account the fact that G.K. Zhukov was often sent to the most critical sectors of the front, the Supreme Command Headquarters appointed him as the representative for the preparation and conduct of the counteroffensive in Stalingrad and the second Rzhev-Sychyev strategic offensive operation (Operation Mars) in November and December 1942. The German command knew that Zhukov was not under Stalingrad but under Rzhev in November 1942.
The success of Operation Ring, which resulted in the capture of over 91,000 people, including 2,500 officers and 24 generals, was facilitated by the simultaneous offensive of Soviet troops on the outer front of the encirclement.
On October 21, 1944, the Presidium of the Supreme Soviet of the USSR recognized the contribution of Soviet artillerymen to the victory in the Battle of Stalingrad by establishing an annual celebration of Artillery Day. Since 1964, this day has been known as the Day of Rocket Troops and Artillery and is celebrated on the day when the counteroffensive operation began - November 19. From 1989 to 2006, the celebration was held on the third Sunday of November.

D.
The Battle for the Caucasus was a series of defensive (July 25 - December 31, 1942) and offensive (January 1 - October 9, 1943) operations conducted by Soviet troops in the Caucasus and Transcaucasia. The goal of these operations was to defend the region and defeat the German-fascist and Romanian forces (Army Group \"A\"), as well as Chechen collaborators and German-Italian naval forces.
After encircling and destroying a Soviet group south and southeast of Rostov, the Soviet forces aimed to gain access to Transcaucasia by bypassing the Caucasus from the west and east, simultaneously overcoming the Caucasus Ridge through the passes. This allowed a connection to be established with the Turkish army, which was stationed near the borders of the USSR but did not participate in the war. Additionally, all Soviet naval bases on the Black Sea were destroyed.
To fulfill these tasks, the Army Group A, led by Field Marshal V. List, was formed. It consisted of 167,000 soldiers, 1,130 tanks, 4,540 guns and mortars, and up to 1,000 aircraft. These troops were opposed by the forces of the Southern and North Caucasus fronts, which consisted of 112 thousand soldiers, 121 tanks, 2,160 guns and mortars, 130 aircraft, as well as the forces of the Black Sea Fleet and Azov military flotilla.
By the beginning of autumn 1942, German forces had managed to conquer most of the Kuban region and the North Caucasus. However, in September 1942, they were halted in the foothills of the Main Caucasus Range and on the Terek River near Malgobek, thus only partially achieving the goals of their Edelweiss Plan. Despite this, the losses for Army Group A had exceeded 100,000 men. The success of Soviet forces was greatly aided by the weakened state of Army Group A, as Romanian and later German units were diverted to Stalingrad in September.

E.
The Battle of Kursk was a series of strategic defensive and offensive operations conducted by the Red Army from July 5 to August 23 in the Kursk salient area. The goal was to disrupt a German offensive and defeat their strategic groups.
After revealing the enemy's plans, the Supreme Command decided to temporarily switch to the defensive in order to weaken the German strike groups and create conditions for a counterattack. This strategy allowed the Red Army to launch a general offensive later on.
As a result of the victory at the Battle of Kursk, the Soviet army finally seized the strategic initiative, marking a significant turning point in the war. After creating a large gap in the southwest wing of the front, Soviet troops launched a strategic counteroffensive on a wide scale, leading to a strategic pursuit of German forces. This pursuit continued until the end of 1943, culminating in the liberation of Left-Bank Ukraine. The success at Kursk set the stage for an offensive in Belarus, ultimately leading to the German and allied forces going on the defensive on all fronts and the beginning of the collapse of the Nazi bloc.
The art of war has been enriched through the experience of fighting, with the deliberate creation of a stable strategic defense in order to launch a counteroffensive. The Battle of Kursk, near the village of Prokhorovka, was the largest tank battle in history, with up to 1,200 tanks participating on both sides. Nazi troops lost up to 400 tanks and assault guns, as well as over 10,000 soldiers, in the area of responsibility of the Voronezh Front.

F.
The Battle of the Dnieper was an offensive operation carried out by Soviet troops in order to liberate the region of Donbass and the Left-Bank Ukraine, as well as to force the Dnieper and capture and hold bridgeheads on its right bank in order to create conditions for a further strategic offensive by the Red Army in Belarus and the Right-Bank Ukraine.
The German command, after the defeat at Kursk, realized the danger of a further advance of Soviet forces and planned to construct powerful defensive fortifications along the Dnieper river, which was considered the largest obstacle in the west. On August 11th, 1943, the German headquarters issued an order for the construction of what was known as the \"Eastern Rampart,\" with a focus on areas where the river could be crossed, such as Kremenchuk, Nikopol, and Zaporozhye.
By the beginning of the battle for the Dnieper, Soviet troops faced a group of German forces consisting of the 2nd Army Group Center (under Field Marshal Gunther von Kluge) and Army Group South (under Field Marshal Erich von Manstein). This group numbered approximately 1.24 million soldiers, 12,600 artillery pieces, 2,100 tanks, and 2,100 aircraft.
During the Battle of the Dnieper, experience was gained in:
- simultaneous offensive operations in several directions on a broad front,
- pursuing the enemy and breaching their intermediate defensive lines while on the move, using advanced units extensively,
- crossing both planned and unplanned water obstacles,
- using strategic reserves to build up an impact force in depth.

G.
The Belarusian Strategic Offensive Operation was one of the most significant strategic operations of World War II, aimed at defeating the German Army Group Centre.
According to the Soviet command's plan, it involved encircling and destroying the flank groups of Army Group Centre in the Vitebsk and Bobruisk areas. This was followed by covering the gaps created along the converging lines of the main forces of Army Group Centre, a maneuver known as \"double pincers\". This was the first stage of the operation. In the second stage, the plan was to launch a general offensive and pursue the enemy, an idea that was brilliantly executed by the Supreme Command.
To dispel the doubts of the Allied forces, who did not believe in the grand success of the Red Army in Belarus, as well as to boost the morale of Soviet citizens, on Monday, July 17, 1944, approximately 57,000 captured German soldiers and officers marched along the Garden Ring in Moscow. This event, in honor of the musical comedy with the same name, was dubbed the \"Big Waltz.\" The irrigation machines following the prisoners conducted a thorough cleanup of the capital's streets.
The Belarus operation was characterized by the extensive use of artillery, with 150 to 200 guns and mortars deployed per kilometer of the breakthrough zone, and a novel approach to artillery support for infantry and tank assaults - a double barrage. The experience gained from the employment of armored and mechanized units was instructive.

H.
The Berlin Operation was a major military offensive during the Great Patriotic War. It was conducted by the Soviet troops of the 1st, 2nd, and 3rd Belorussian fronts, as well as the 1st Ukrainian Front, the 18th Air Army, and parts of the Baltic and Dnieper fleets. The goal of the operation was to defeat the German forces in the Vistula and Central Army Groups, capture Berlin, reach the Elbe river, and link up with Allied forces.
The Berlin Operation was a plan by a group of fronts to surround and dismember the largest enemy strategic group during World War II. The 1st Belorussian Front, led by Marshal of the Soviet Union Georgy Zhukov, was tasked with capturing Berlin and reaching the Elbe River within 12 to 15 days. The 1st Ukrainian Front, under the command of Marshal I.S. Konev, had the objective of defeating the enemy forces in the Cottbus region and south of Berlin, and capturing the border cities of Belitz and Wittenberg, as well as the Elbe River, leading to Dresden, within 10 to 12 days. The 2nd Belorussian Front, commanded by Marshal Konstantin Rokossovsky, was responsible for crossing the Oder River, defeating the Stettin Group of the enemy, and cutting off the main forces of the 3rd Army from Berlin.
The Berlin operation was characterized by its preparation in a short period of time, the use of searchlights by the 1st Belorussian Front to transition to the offensive during the night, the involvement of a variety of armored and mechanized units, the full implementation of artillery and air support, and the actions of assault teams during the fighting in the city.
",
null,
"match");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(36,5,"1.	The Hellish Battle on the Volga",null,1,null),
(37,5,"2.	Breaching the Eastern Rampart: A River of Blood	7. The Double Pincers: The Death Knell of Army Group Centre",null,1,null),
(38,5,"3.	The City  in Flames: The Last Days of the Reich",null,1,null),
(39,5,"4.	The Mountains of Fire: Soviet Defense and German Failure",null,1,null),
(40,5,"5.	The main features of the WWII",null,1,null),
(41,5,"6.	The Ground Trembled: The Largest Tank Battle in History",null,1,null),
(42,5,"7.	The Double Pincers: The Death Knell of Army Group Centre",null,1,null),
(43,5,"8. Defense, Siege, and Liberation",null,1,null),
(44,5,"9. The Significance of The Battle - A Turning Point in WWII",null,1,null);

INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(60,36,"A", "9", True),
(61,37,"B", "8", True),
(62,38,"C", "1", True),
(63,39,"D", "4", True),
(64,40,"E", "6", True),
(65,41,"F", "2", True),
(66,42,"G", "7", True),
(67,43,"H", "3", True);
-- 44 item_id не нужен

-- Test yourself
INSERT INTO task(id,section_id, hint, title, file_link, text, text_after_answer, type) VALUES
(6,4,
null,
"The structure and functions of state and military administrative bodies during the war in the USSR: the State Defense Committee, the Supreme High Command Headquarters, and the General Staff.",
null,
null,
null,
"multiple_choice");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(45,6,"1.	The coordination of military construction issues and the direct preparation of the country for defense prior to the war were carried out by:",
"a) The General Staff of the Red Army (headed by G.K. Zhukov);
b) The Supreme Soviet of the USSR (presided over by M.I. Kalinin);
c) The People's Commissariat of Defense (led by S.K. Timoshenko);
d) The Defense Committee under the Soviet of People's Commissars (chaired by K.E. Voroshilov).
",1,null);

INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(68,45,null, "d", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(46,6,"2. The main purpose of creating the State Defense Committee at the beginning of the Great Patriotic War was:",
"a) to centralize the vertical of government power in the Soviet Union;
b) to strengthen the authority of the People's Commissar for Defense;
c) to combat the cult of personality in the Soviet system;
d) to satisfy I.V. Stalin's personal power ambitions.",
1,null);

INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(69,46,null, "ab", TRUE);
-- (70,46,null, "b", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(47,6,"3. The main governing body of the Armed Forces of the USSR during the Great Patriotic War:",
"a) was a General Staff under the People's Commissariat of Defense;
b) was the Headquarters of the Supreme High Command (Supreme Command Headquarters);
c) was the Main Headquarters of the People's Defense Commissariat;
d) was Defense Committee of the Council of People's Commissars.",
1,null);

INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(71,47,null, "b", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(48,6,"4. The structure of the State Defense Committee included:",
"a) Departments of the Central Committee of the Communist Party of the Soviet Union overseeing specific areas of the economy of the USSR;
b) Various temporary commissions that, as needed, either ceased operations or were transformed into permanent bodies - The State Defense Committees;
c) The General Staff of the People's Commissariat of Defense and Supreme Command Headquarters;
d) International observers who coordinated their work with representatives from the People's Commissariat for Foreign Affairs.",
1,null);

INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(72,48,null, "b", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(49,6,"5. The State Defense Committees’ tasks did not include the following issues:",
"a) conducting the USSR's foreign policy, including matters related to the post-war world political system;
b) rebuilding the economy after the war;
c) mobilizing the country's resources for the front and national economy;
d) relocating industrial facilities from dangerous areas and transferring enterprises to safe areas.",
1,null);

INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(73,49,null, "a", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(50,6,"6. To manage the work of the State Defense Committee and coordinate efforts among its structural divisions:",
"a) on July 10, 1941, the State Defense Committees Secretariat was formed;
b) on August 2, 1941, the Operational Bureau was created;
c) on December 8, 1942, the Operational Bureau existed;
d) no information available on the establishment of the State Defense Committees Secretariat on November 19, 1942.",
1,null);

INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(74,50,null, "c", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(51,6,"7. The intermediate command authority between the headquarters of the supreme command and the fronts during the Great Patriotic War:",
"a) was the institution of representatives of the Headquarters in military instances;
b) was not created;
c) were the Main Commands of troops in strategic areas created for a certain period;
d) was the State Defense Committee.",
1,null);

INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(75,51,null, "ac", TRUE);
-- (76,51,null, "с", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(52,6,"8. During the Berlin Operation (April 16 – May 8, 1945), for the first time in the history of wars:",
"a) an air-ground offensive operation was carried out;
b) the operation of a group of fronts was held to encircle and simultaneously dismember the largest strategic enemy group numbering more than 1 million people;
c) an air campaign took place to isolate the area of military operations;
d) there was atomic bombing of an enemy military group.",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(77,52,null, "b", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(53,6,"9. The concept of the 'Eastern Wall' is associated with the Battle of the Dnieper (August – December 1943). This concept means:",
"a) the stage of enemy fire suppression, first used by Soviet gunners during the crossing of the Dnieper River near the Dnieper Bridgehead;
b) the defensive fortifications were supported by the largest water barrier when moving westward - the Dnieper River;
c) the name given to the tank army by Erich von Manstein for its successful counterattack in the Kiev area in 1943;
d) the line of contact between troops on the Soviet-German front after the Red Army's offensive during the Battle of the Dnieper.",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(78,53,null, "b", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(54,6,"10. The Belarusian strategic offensive operation (June 23 – August 29, 1944) was aimed at:",
"a) to withdraw Poland from the war on the side of Germany;
b) demonstrating the power of the Red Army to the Allies in order to convince them to open a second front in Western Europe;
c) defeat the German Army Group Center;
d) overcoming the German 'Eastern Wall' - a line of long-term defensive structures in the eastern regions of Belarus.",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(79,54,null, "c", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(55,6,"11. The Soviet troops advanced up to 800 kilometers during the offensive stage of the Battle of the Caucasus, which took place from January 1 to October 9, 1943. This success is mainly due to",
"a) the reinforcement of the Red Army's forces in the Caucasus by Allied Turkish troops;
b) the significant results of the Battle of Stalingrad, as a real threat was created to cut off the grouping of German troops in the Caucasus from the main forces of the Wehrmacht;
c) the encirclement and defeat of the main forces of Army Group A, operating in the Caucasus, in the foothills of the Main Caucasus Ridge;
d) the defeat of the main forces of the German Black Sea Fleet in the Black Sea and the disruption of maritime communications for Army Group 'A', which was operating in the Caucasus region.",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(80,55,null, "b", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(56,6,"12. The success of the strategic offensive by the Soviet troops during the Great Patriotic War was due to several factors:",
"a) choosing the right time and place to launch an offensive;
b) gaining operational air superiority;
c) informing the enemy of an impending offensive in order to suppress their morale;
d) creating both offensive and defensive groups of troops in the direction of the main attacks.",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(81,56,null, "ab", TRUE);
-- (82,56,null, "b", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(57,6,"13. Name the operations in which the Soviet troops, during the strategic offensive, implemented the following method of defeating the enemy – the encirclement of large groups with their subsequent destruction:",
"a) Belgorod-Kharkov operation;
b) Stalingrad operation;
c) Iasi-Kishinev operation;
d) The Orel operation.",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(83,57,null, "bc", TRUE);
-- (84,57,null, "c", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(58,6,"14. During the Great Patriotic War, the Soviet Navy carried out the following groups of missions:",
"a) conducting exercises and maneuvers;
b) ensuring the actions of the Red Army and assisting Soviet troops in order to solve combat tasks assigned to them;
c) maintaining formations and units of the fleet in constant combat readiness;
d) independent combat operations and operations to protect communications and disrupt enemy maritime communications.",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(85,58,null, "bd", TRUE);
-- (86,58,null, "d", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(59,6,"15. The military actions of the Great Patriotic War demonstrated the increased importance of air defense forces. During this period, they played a crucial role in solving various tasks:",
"a) protecting the largest cities and most important industrial areas in the Western European part of the USSR from air attacks;
b) achieving strategic air superiority;
c) protecting large groups of troops, naval forces, logistical facilities, and communications from air attacks;
d) disrupting the enemy's air defenses.",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(87,59,null, "ac", TRUE);
-- (88,59,null, "c", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(60,6,"16. The main difference between the Allied military operations and those on the Soviet-German front was:",
"a) the use of only the most advanced weapons and military equipment in military operations;
b) a much lower level of intensity in the armed struggle;
c) an increased ferocity in the armed conflict;
d) a significant spatial scope for military operations.",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(89,60,null, "bd", TRUE);
-- (90,60,null, "d", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(61,6,"17. The purpose of the El Alamein offensive operation, which took place from October 23 to November 27, 1942, by the Allied forces in North Africa, was to:",
"a) withdraw from the war the allies of the Nazi coalition in North Africa – Egypt, Libya, Tunisia, Algeria and Morocco;
b) seize the strategic initiative in the struggle for the Mediterranean coast of North Africa;
c) seize the strategic initiative in the struggle for the northwest Atlantic coast of Africa;
d) take control of territories rich in oil and gas.",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(91,61,null, "b", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(62,6,"18. The most significant phase of the Normandy amphibious operation, Neptune (June 6 - July 24, 1944), was the time period:",
"a) seizing a beachhead in the Pas-de-Calais Strait;
b) capture of a bridgehead on the coast of the Bay of Seine;
c) expansion of the bridgehead and connection with a group of allied troops landed in the south of France;
d) expansion of the bridgehead and the capture of Paris.",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(92,62,null, "b", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(63,6,"19. The Norman amphibious operation Neptune (June 6 – July 24, 1944)",
"a) is characterized by the organization of interaction between large naval forces, ground forces, and aviation;
b) was the largest amphibious operation during the Second World War;
c) is characterized by advanced equipment on the coast at the landing site;
d) has been successful in providing integrated lighting support for amphibious troops.",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(93,63,null, "ab", TRUE);
-- (94,63,null, "b", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(64,6,"20. In which theater of military operations did the allies of the USSR not conduct military operations?",
"a) Eastern European Theater of Operations;
b) Pacific Theater of Operations;
c) North African Theater of Operations;
d) The Mediterranean Theater of Operations.",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(95,64,null, "a", TRUE);