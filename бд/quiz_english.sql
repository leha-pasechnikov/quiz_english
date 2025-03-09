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
-- |--------------|-------------------|--------------|--------------|---------------|--------------|----------------|
-- |              | id                |      +       |      +       |       +       |      +       |       +        |
-- |              | item_id           |      +       |      +       |       +       |      +       |       +        |
-- |answer_option | left_text         |      -       |      +       |       -       |      +       |       -        |
-- |              | text (ответ)      |      +       |      +       |       +       |      +       |       +        |
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
CREATE TABLE answer_option (
    id INT AUTO_INCREMENT PRIMARY KEY,
    item_id INT NOT NULL,
    left_text TEXT NULL,
    text TEXT NOT NULL, -- текст ответа
    is_correct BOOLEAN NOT NULL, -- Правильный ли ответ
    FOREIGN KEY (item_id) REFERENCES item(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Таблица ответов пользователей на варианты ответов
CREATE TABLE answer_option_result (
    id INT AUTO_INCREMENT PRIMARY KEY,
    answer_option_id INT NOT NULL,
    user_id INT NOT NULL,
    text TEXT NOT NULL,
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

DELIMITER $$

CREATE TRIGGER update_user_time_score_after_insert
AFTER INSERT ON answer_option_result
FOR EACH ROW
BEGIN
    -- Проверяем, что текст ответа совпадает с правильным вариантом
    IF NEW.text = (SELECT ao.text
                   FROM answer_option ao
                   WHERE ao.id = NEW.answer_option_id
                   AND ao.is_correct = TRUE
                   LIMIT 1) THEN

        -- Обновляем время в поле time_score для соответствующего пользователя
        UPDATE user
        SET time_score = CURRENT_TIMESTAMP
        WHERE id = NEW.user_id;
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE TRIGGER update_user_time_score_after_update
AFTER UPDATE ON answer_option_result
FOR EACH ROW
BEGIN
    -- Проверяем, что текст ответа совпадает с правильным вариантом
    IF NEW.text != OLD.text and NEW.text = (SELECT ao.text
                   FROM answer_option ao
                   WHERE ao.id = NEW.answer_option_id
                   AND ao.is_correct = TRUE
                   LIMIT 1) THEN

        -- Обновляем время в поле time_score для соответствующего пользователя
        UPDATE user
        SET time_score = CURRENT_TIMESTAMP
        WHERE id = NEW.user_id;
    END IF;
END $$

DELIMITER ;




INSERT INTO admin(username, password) VALUES ("admin","admin");

INSERT INTO user (last_name, first_name, middle_name, email, username, password, time_score, note) VALUES
('Иванов', 'Иван', 'Иванович', 'ivanov1@example.com', 'login1', 'pass1', '2024-02-24 18:20:20', ''),
('Петров', 'Петр', 'Петрович', 'petrov2@example.com', 'login2', 'pass2', '2024-02-24 18:20:21', ''),
('Сидоров', 'Сидор', 'Сидорович', 'sidorov3@example.com', 'login3', 'pass3', '2024-02-24 18:20:20', ''),
('Кузнецов', 'Алексей', 'Алексеевич', 'kuznetsov4@example.com', 'login4', 'pass4', '2024-02-24 18:20:20', '');

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

INSERT INTO answer_option(id, item_id,text, left_text, is_correct) VALUES
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
(37,5,"2.	Breaching the Eastern Rampart: A River of Blood",null,1,null),
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


-- Military-Political Outcomes and Lessons of the War
-- Grammar and vocabulary
INSERT INTO task(id,section_id, hint, title, file_link, text, text_after_answer, type) VALUES
(7,5,
"Прочитайте приведённый ниже текст / приведённые ниже тексты.
Преобразуйте, если необходимо, слова, напечатанные заглавными буквами в конце строк, обозначенных номерами 1–5, так,
чтобы они грамматически соответствовали содержанию текстов.
Заполните пропуски полученными словами. ",
"A Historical Analysis",
null,
null,
null,
"fix_word"),
(8,5,
"Прочитайте приведённый ниже текст.
Образуйте от слов, напечатанных заглавными буквами в конце строк, обозначенных номерами 6–10, однокоренные слова так,
чтобы они грамматически и лексически соответствовали содержанию текста.
Заполните пропуски полученными словами. ",
"Average Daily Losses as an Indicator of Warfare:",
null,
null,
null,
"fix_word"),
(9,5,
"Прочитайте текст с пропусками, обозначенными номерами 11–18.
Эти номера соответствуют заданиям 11–18, в которых представлены возможные варианты ответов.
Запишите в поле ответа цифру 1, 2, 3 или 4, соответствующую выбранному Вами варианту ответа.",
"Building a Military Power",
null,
"The socio-economic 11 _________ of the Soviet Union in the 1920s and 1930s enabled the creation of a mass regular army, without which the USSR would not have been able to defend its independence in the impending world war. At the same time, it was not possible to ensure adequate training quality for military personnel or to 12 _________  a sufficiently well-trained mobilization reserve by the beginning of the war. The mistakes made by the highest state leadership in assessing the foreign political situation that had developed by the start of the war, as well as miscalculations in predicting the conditions for the army's entry into the war, were the main reasons for the defeat of the first strategic echelon in the initial months of the war in 1941. The Soviet people paid a bloody 13 _________ for these miscalculations, which manifested, on one hand, in the loss of a significant portion of prepared military personnel, and on the other, in the arrival of poorly trained reinforcements to the troops.
The capabilities of the fighting units were influenced not only by the training of the personnel but also by the level of technical 14 _________ of the troops. It wasn't until the spring of 1942 that Soviet industry managed to restore the production of military equipment and armaments. Meanwhile, the colossal losses of the first year of the war continued to 15 _________ affect the results of military operations until 1943. The superiority obtained in the army's technical equipment by the middle of the war, combined with the growth of military skills, gradually led 16 _________ a decrease in operational losses.
During the war, 19.83 million units of small arms (excluding revolvers and pistols), 98.3 thousand tanks and self-propelled artillery, 525.2 thousand artillery pieces and mortars, 122 thousand aircraft (including 101 thousand combat aircraft), and 70 combat ships of major classes were produced.
The losses were directly dependent on the level of discipline within the troops, the resilience of the forces, their readiness to fight in encirclement, and the 17 _________ quality of political and educational work. During the war years, state awards were established in the names of our great commanders and naval leaders – the Medals of Alexander Nevsky (1942), Suvorov (1942), Kutuzov (1942), Bohdan Khmelnytsky (1943), Nakhimov (1944), Ushakov (1944); the Nakhimov Medal (1944), the Ushakov Medal (1944), and traditional historical military insignia such as epaulettes (1943) were reinstated.
Overall, the Great Patriotic War and the victory in it required unprecedented expenditures and sacrifices of various kinds from the Soviet people. Both the leaders of the Soviet Union and ordinary citizens understood that if Germany had 18 _________ in defeating the USSR in this war, the state would have been liquidated, and vast masses of Slavic and other \"inferior races\" would have been enslaved and exterminated. The victory of fascism posed a threat to all of human civilization, which would have been pushed back in its development. Therefore, the price paid by the USSR for victory in World War II should be known to contemporaries in all developed countries of the world.
",
null,
"text_answer"),
(10,5,
"Прочитайте приведённый ниже текст.
Образуйте от слов, напечатанных заглавными буквами в конце строк, обозначенных номерами 19–29 , однокоренные слова так,
чтобы они грамматически и лексически соответствовали содержанию текста.
Заполните пропуски полученными словами. ",
"The Legacy of the Nuremberg and Tokyo Trials",
null,
null,
null,
"fix_word"),
(11,5,
"Прочитайте приведённый ниже текст / приведённые ниже тексты.
Преобразуйте, если необходимо, слова, напечатанные заглавными буквами в конце строк, обозначенных номерами 1–5, так,
чтобы они грамматически соответствовали содержанию текстов.
Заполните пропуски полученными словами. ",
"Historical Narratives",
null,
null,
null,
"fix_word");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(65, 7, "ANNOUNCE",
"A review of domestic historiography reveals that estimates of the total demographic losses of the USSR population during the Great Patriotic War in the post-war period _________ by officials and published in the open press in a very wide range—from 7-27 to 50 million people. In most cases, these estimates were either deliberately downplayed for opportunistic political reasons or unreasonably overestimated.",
1, "1"),
(66, 7, "INCLUDE",
"Conversely, scientific studies of the long-term demographic losses of the Soviet Union, _________ those conducted in the late 1940s, have determined that the direct military losses of the population of the USSR are between 21.2 and 25.8 million people, which is equivalent to approximately 11-13% of the population of the country at the onset of the war.",
1, "2"),
(67, 7, "RUSSIA",
"The estimate of demographic losses of the Soviet Union, designated as the final figure by  _________  President B.N. Yeltsin on May 8, 1995, was 26.549 million people.",
1, "3"),
(68, 7, "SUMMARIZE",
"Irrecoverable losses of the Soviet Armed Forces are part of the total demographic losses of the Soviet population in the war. By June 1945, the General Staff _________the available data (which was not yet complete) on total losses for the four years of the war.",
1, "4"),
(69, 7, "THIS",
"According to calculations from the late 1940s, the total number of fatalities and _________ who died of wounds amounted to over 6.3 million, the number of prisoners and missing in action was over 3 million, and the number of wounded (not including those who died of wounds) was almost 14 million. Of these wounded, 2.6 million were disabled. According to contemporary official estimates, the data from the initial post-war studies on the number of fatalities and wounded individuals is almost entirely aligned.",
1, "5");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(70, 8, "INDICATE",
"An important _________ for evaluating the art of war is the average daily losses, both total and by periods and campaigns of a particular war.Total average daily losses on the Soviet-German front during the Great Patriotic War averaged 20,869 thousand men, of whom about 8 thousand were irrecoverable.",
1, "6"),
(71, 8, "COMPARATIVE",
"The highest average daily losses occurred during the summer and fall campaigns of 1941, at 24,000 men per day, and during the 1943 campaigns, at 27,300 men per day. In contrast, the losses sustained by the Soviet army and navy during the Soviet-Japanese war were _________ minimal.",
1, "7"),
(72, 8, "ABLE",
"Over the course of 25 days of combat operations, 36,400 men were  _________, including 12,000 killed or missing, amounting to approximately 1,940 men per day.",
1, "8"),
(73, 8, "MONTH",
"The dynamics of the losses of the opposing forces on the Soviet-German front are revealed by the ratio of average _________ losses by periods of the war (in thousand people): in the first period of the war - 752.8:181.3 or 4 .2:1; in the second period - 642.0:238.5 or 2.7:1; in the third period - 571.8:440.3 or 1.3:1.",
1, "9"),
(74, 8, "PROGRESS",
"These figures reveal the steady trends inherent in the dynamics of the losses of the sides during the four years of the war: a _________ decrease in the losses of the Soviet side and a simultaneous increase in the losses of the enemy. Consequently, the enemy suffered irrecoverable losses in the third period of the war that exceeded those of the Soviet troops by a ratio of 1.4 to 1, amounting to approximately 3,547,300 and 2,564,700 men, respectively.",
1, "10");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(75,9,null,null,1,"11"),
(76,9,null,null,1,"12"),
(77,9,null,null,1,"13"),
(78,9,null,null,1,"14"),
(79,9,null,null,1,"15"),
(80,9,null,null,1,"16"),
(81,9,null,null,1,"17"),
(82,9,null,null,1,"18");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(83, 10, "DECLARE",
"The necessity of prosecuting the leaders of the Hitler coalition as international criminals was discussed starting in 1943. During the Moscow Conference of Foreign Ministers of the USSR, the USA, and the UK on November 1, 1943, a Secret Protocol was signed, which included a \"_________  of the Responsibility of the Nazis for the Atrocities Committed\" as its 18th point.",
1, "19"),
(84, 10, "CRIME",
"Subsequently, during the proceedings for the trial of Nazi _________ at the Yalta meeting with Winston Churchill and Franklin D. Roosevelt in Crimea in February 1945, the leader of the USSR, Joseph Stalin, insisted on the need for a tribunal.",
1, "20"),
(85, 10, "AGREE",
"The _________ to establish the International Military Tribunal and its Charter was developed at a meeting of representatives from the four victorious powers in World War II (including France) in London from June 26 to August 8, 1945.",
1, "21"),
(86, 10, "VICTORY",
"From November 20, 1945, to October 1, 1946, the trial of the major Nazi war criminals took place in Nuremberg. For this purpose, an International Tribunal was established, composed of representatives from the countries that emerged _________ in World War II.",
1, "22"),
(87, 10, "law",
"An important aspect is that the Nuremberg Trials marked the first time in history that not just individuals, but also criminal organizations created to achieve _________ goals were put on trial.",
1, "23"),
(88, 10, "NATION",
"On September 30 and October 1, 1946, a verdict was announced. The principles of _________ law contained in the Charter of the International Tribunal and reflected in the verdict were confirmed by the resolution of the United Nations General Assembly on December 11, 1946. ",
1, "24"),
(89, 10, "ORGANISE",
"However, while the tribunal recognized  _________  such as the SS (internal troops and security services), SD (security service), Gestapo (secret state police), and the leadership core of the National Socialist Party as criminal organizations, it did not rule on the criminality of the high command and the general staff of the Wehrmacht.",
1, "25"),
(90, 10, "JAPAN",
"The Tokyo War Crimes Tribunal for the main _________ war criminals took place in Tokyo from May 3, 1946, to November 12, 1948, at the International Military Tribunal for the Far East. The sentences of death imposed on those convicted were carried out on the night of December 23, 1948, in Tokyo.",
1, "26"),
(91, 10, "SIGN",
"The Tokyo Trials, like the Nuremberg Trials, were _________ for establishing the principles and norms of modern international law, which consider aggression as a grave crime that can warrant the death penalty. ",
1, "27"),
(92, 10, "APPLY",
"The normative documents produced during these trials do not mention the _________  of statutes of limitations to war crimes and war criminals. However, the Declaration regarding the defeat of Germany dated June 5, 1945 (Article 11) states that the arrest and extradition of war criminals should take place at any time.",
1, "28"),
(93, 10, "LIMIT",
"At the same time, in West Germany from 1964 to 1967, there were active initiatives to cease the prosecution of war criminals due to the expiration of the statutes of limitations for their crimes. In response to such attempts, the UN General Assembly adopted Resolution No. 2391 (XXIII) on November 26, 1968, during its 23rd session, which established the Convention on the Non-Applicability of Statutory _________ to War Crimes and Crimes Against Humanity.",
1, "29");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(94, 11, "dictate",
"The disagreements among the allies of the anti-Hitler coalition during World War II, as well as the differing assessments of their contributions to the victory over the military-political fascist bloc in the post-war years, _________by the varying goals pursued by the leadership of the USSR, the USA, and the UK.",
1, "30"),
(95, 11, "eliminate",
"The leadership of the USSR and its Red Army pursued lofty and noble goals in this war—defeating the aggressor (Nazi Germany) and _________ fascism in Europe, as well as the strict and timely fulfillment of allied obligations during the defeat of the Kwantung Army in the Far East during the Soviet-Japanese War.",
1, "31"),
(96, 11, "aim",
"On the other hand, the leaders of the ruling circles of the USA and the UK did not seek the complete destruction of the German fascist and Japanese troops; rather, they _________ to eliminate them as dangerous competitors in global markets and sources of raw materials",
1, "32"),
(97, 11, "two",
"Despite the USSR's involvement in the anti-Hitler coalition, there was a clear desire to weaken and drain the Soviet Union, as evidenced by various tactics related to delaying the opening of a _________ front in Europe. The Allies began military action in Western Europe only after it became clear that the Red Army was capable of achieving victory over Germany without their assistance.",
1, "33"),
(98, 11, "give",
"_________ these contradictions, disputes continue to this day and are becoming increasingly heated, taking on various forms of ideological struggle over the assessment of the outcomes of World War II. This situation is compounded by the rise of neo-fascism, extremism, and terrorism in the world. Moreover, similar to the 20th century, the politics of leading foreign countries are characterized by double standards.",
1, "34"),
(99, 11, "they",
"This is manifested in overtly anti-Russian positions on a number of international issues and the transfer of political agendas to areas such as culture and sports. There is a clear tendency to rewrite historical truths and to falsify _________ for narrow self-serving interests while simultaneously offering a one-sided assessment of today’s realities. Unfortunately, such an approach does not contribute to the improvement of international relations; it is a dead-end strategy that is unlikely to succeed in the near or long term.",
1, "35");

INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(96,65,null, "were announced", True),
(97,66,null, "including", True),
(98, 67, NULL, "Russian", TRUE),
(99, 68, NULL, "had summarized", TRUE),
(100, 69, NULL, "those", TRUE),
(101, 70, NULL, "indicator", TRUE),
(102, 71, NULL, "comparatively", TRUE),
(103, 72, NULL, "disabled", TRUE), -- DISABLE ?
(104, 73, NULL, "monthly", TRUE),
(105, 74, NULL, "progressive", TRUE);

INSERT INTO answer_option(id, item_id,text, left_text, is_correct) VALUES
(106,75,'1',"1. advancement", False),
(107,75,'2',"2. development", True),
(108,75,'3',"3. outcome", False),
(109,75,'4',"4. change", False),

(110, 76, '1', "1. create", True),
(111, 76, '2', "2. build", False),
(112, 76, '3', "3. design", False),
(113, 76, '4', "4. form", False),

(114, 77, '1', "1. amount", False),
(115, 77, '2', "2. price", True),
(116, 77, '3', "3. cost", False),
(117, 77, '4', "4. bill", False),

(118, 78, '1', "1. appliances", False),
(119, 78, '2', "2. accessories", False),
(120, 78, '3', "3. material", False),
(121, 78, '4', "4. equipment", True),

(122, 79, '1', "1. upset", False),
(123, 79, '2', "2. act", False),
(124, 79, '3', "3. disturb", False),
(125, 79, '4', "4. affect", True),

(126, 80, '1', "1. in", False),
(127, 80, '2', "2. to", True),
(128, 80, '3', "3. on", False),
(129, 80, '4', "4. with", False),

(130, 81, '1', "1. condition", False),
(131, 81, '2', "2. variety", False),
(132, 81, '3', "3. quality", True),
(133, 81, '4', "4. kind", False),

(134, 82, '1', "1. succeeded", True),
(135, 82, '2', "2. achieved", False),
(136, 82, '3', "3. got", False),
(137, 82, '4', "4. won", False);

INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(138,83,null, "declaration", True),
(139,84,null, "criminals", True),
(140, 85, NULL, "agreement", TRUE),
(141, 86, NULL, "victorious", TRUE),
(142, 87, NULL, "unlawful", TRUE),
(143, 88, NULL, "international", TRUE),
(144, 89, NULL, "organizations", TRUE),
(145, 90, NULL, "Japanese", TRUE),
(146, 91, NULL, "significant", TRUE),
(147, 92, NULL, "application", TRUE),
(148, 93, NULL, "limitations", TRUE);

INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(149,94,null, "are dictated", True),
(150, 95, NULL, "eliminating", TRUE),
(151, 96, NULL, "aimed", TRUE),
(152, 97, NULL, "second", TRUE),
(153, 98, NULL, "given", TRUE),
(154, 99, NULL, "them", TRUE);

-- Listening
INSERT INTO task(id,section_id, hint, title, file_link, text, text_after_answer, type) VALUES
(12,6,
"Вы услышите монолог.
Определите, какие из приведённых утверждений А–G соответствуют содержанию текста (1 – True), какие не соответствуют (2 – False) и о чём в тексте не сказано, то есть на основании текста нельзя дать ни положительного, ни отрицательного ответа (3 – Not stated).
Занесите номер выбранного Вами варианта ответа в таблицу.
Вы услышите запись дважды",
null,
"Listening.mp3",
"
A.	The lend-lease program sent various types of aid, including weapons, military equipment, and food supplies to the USSR.
B.	The majority of Lend-Lease supplies to the USSR were delivered between the years 1943 and 1945.
C.	. The payments for the deliveries under the Lend-Lease program began during World War II.
D.	The lend-lease program was initiated because of a formal treaty between the USSR and the USA.
E.	The lend-lease program included a provision for sending troops to assist the Soviet Army.
F.	The USSR received most of its lend-lease supplies through the Black Sea route.
G.	All equipment supplied under the Lend-Lease program was used efficiently by the Soviet army.
H.	The reverse lend-lease program involved the supply of materials from the USSR to the USA.
I.	The lend-lease program was operational for only two years.
J.	The lend-lease cargoes reached the USSR via five distinct routes.
",
"
The assistance of the Allies to the Soviet Union, in addition to conducting joint military operations, also included the supply of weapons, military equipment, ammunition, logistical support, and various types of raw materials to the USSR. The main suppliers of materials were the USA, the UK, and Canada, and the form of supply was through government lend-lease programs (from the English \"lend\" – to give on loan and \"lease\" – to rent).
The inclusion of the USSR in the lend-lease program occurred with a significant delay – only in October 1941. Washington believed that the USSR would not be able to withstand the onslaught of the Wehrmacht for long and feared that any supplied weapons and materials to the Red Army would simply become trophies.
On June 11, 1942, an \"Agreement between the Governments of the USSR and the USA on Principles Applicable to Mutual Assistance in Waging War Against Aggression\" was signed in Washington.
A total of 42 countries received cargo supplies through lend-lease programs during World War II. An analysis of data on the quantity and nomenclature of goods supplied to the USSR under the lend-lease program indicates that the most significant supplies for the Red Army were automotive equipment (accounting for over 60%), aviation fuel (up to 40%), explosives, and gunpowder (about 55%).
In addition to weapons and military equipment, the lend-lease program also sent railway tracks, locomotives, tires, and other equipment to the USSR. Food supplies were also an important form of aid to the Red Army.
However, overall, the total share of materials supplied through lend-lease did not exceed an average of 4-5%. Even so, the very fact of assistance from the Allies and the awareness of this support among ordinary soldiers and sailors of the Red Army, as well as ordinary Soviet citizens, was significant.
Lend-lease cargoes reached the USSR via five routes: through Arctic convoys to Murmansk, by ships across the Black Sea, by rail and road transport through Iran, by air transport through the Far East, and through the Soviet Arctic. The largest share of supplies came from the Far Eastern route, while the supplies through the Soviet Arctic and the Black Sea were the least significant. The volume of supplies to the USSR depended not on the production capabilities of American industry but was limited by the tonnage of available transport vessels.
In addition to the direct supply program under lend-lease, there was also a reverse lend-lease program, which involved the supply of various goods to the USA from the USSR. Among the materials supplied under reverse lend-lease were chrome ore, manganese ore, gold, platinum, timber, and others. The reverse lend-lease program also included free repairs of American ships in Soviet ports and other services.
The payment for deliveries under the Lend-Lease program began to be made by the Soviet Union only after the Great Patriotic War. Evaluating the military aid provided by the Allies in terms of supplying the USSR with weapons, military equipment, property, and other cargo, the following conclusions can be drawn.
Firstly, the foundation of the Lend-Lease aid program was based on the financial and economic interests of the United States, rather than on the interests of the Allies aimed at achieving victory over a common enemy.
Secondly, the Allies generally supplied the USSR with less than the best samples of their technology.
Thirdly, the overwhelming majority of the equipment, machinery, and materials were delivered to the USSR in the years 1943-1945, that is, after the turning point in the course of the war. Thus, over 70% of Lend-Lease supplies were from the years 1943 to 1945, and during the most dire period of the war for the USSR, the aid from the Allies was not particularly noticeable. The situation in this regard is largely analogous to the situation with military assistance and the opening of the second front in Europe.
Fourthly, far from all the equipment supplied under Lend-Lease was used by the army and navy. For example, out of 202 torpedo boats delivered to the USSR, 118 never participated in the combat operations of the Great Patriotic War, as they were commissioned after its conclusion.
Fifthly, the relations between the USSR and the USA related to the military aid program under Lend-Lease did not end with the conclusion of World War II. Serious financial obligations were placed on the Soviet Union.
Sixthly, the Americans themselves never regarded aid to the Soviet Union under the Lend-Lease program as a decisive factor in the USSR's victory over Germany. US President Franklin D. Roosevelt explicitly stated that \"helping the Russians is money well spent.\" Indeed, Lend-Lease did not have a decisive impact on the outcome of the war between the USSR and Germany.
At the same time, these supplies positively influenced the combat readiness of the Red Army, preserved the lives and health of Soviet soldiers, and brought the overall Victory closer. For this alone, the citizens of the Russian Federation should be grateful to their allies.
",
"listen_answer");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(100,12,null,null,1,"A"),
(101,12,null,null,1,"B"),
(102,12,null,null,1,"C"),
(103,12,null,null,1,"D"),
(104,12,null,null,1,"E"),
(105,12,null,null,1,"F"),
(106,12,null,null,1,"G"),
(107,12,null,null,1,"H"),
(108,12,null,null,1,"I"),
(109,12,null,null,1,"J");

INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(155,100,null, "1", True),
(156,101,null, "1", True),
(157,102,null, "2", True),
(158,103,null, "3", True),
(159,104,null, "3", True),
(160,105,null, "2", True),
(161,106,null, "2", True),
(162,107,null, "1", True),
(163,108,null, "3", True),
(164,109,null, "1", True);

-- Reading
INSERT INTO task(id,section_id, hint, title, file_link, text, text_after_answer, type) VALUES
(13,7,
"Прочитайте текст и заполните пропуски A–F частями предложений,
обозначенными цифрами 1–7. Одна из частей в списке 1–7 лишняя.
Занесите цифры, обозначающие соответствующие части предложений, в таблицу.
",
"Beyond Triumph",
null,
"The price of victory is a crucial part of any war and reflects a complex set of intellectual, spiritual, economic, military, A ____________________, as well as the losses, costs, damage, and harm they have incurred. The price of victory also includes the corresponding consequences of the war, not only in social and demographic terms but also in foreign policy and foreign economic relations, B ____________________ and often decades. The price of victory for the Soviet Union in the Great Patriotic War is immense, C ____________________, devastated the living environment of the Soviet people, caused damage to nature and the national economy of our country, and left a negative memory for many years.
The aggressors completely or partially destroyed 1,710 cities and towns, more than 70,000 villages, D ____________________, leaving 25 million people homeless. They destroyed or incapacitated 32,000 large and medium-sized industrial enterprises, 65,000 kilometers of railway tracks, 40,000 healthcare facilities, 84,000 educational institutions, and 43,000 libraries. The occupiers looted and destroyed 98,000 collective farms, 1,876 state farms, and 2,890 machine-tractor stations. They slaughtered, seized, or transported to Germany 7 million horses, 17 million cattle, 20 million pigs, 27 million sheep and goats, and 110 million heads of poultry. The total cost of material losses incurred by the Soviet Union amounts to 679 billion rubles at 1941 state prices. The total damage inflicted E ____________________, along with military expenses and temporary loss of income from industry and agriculture in the occupied areas, amounted to 2 trillion 569 billion rubles. Overall, the total damage inflicted on the economy of the Soviet Union during the occupation, in monetary terms, was 20 times greater than the national income that the country had in 1940.
The Great Patriotic War crippled the fate of the Soviet people, abruptly changed their lives, brought them the agony of suffering, deprivation, bitterness and sadness. However, the main component of the price of the victory F ____________________.
",
null,
"match");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(110,13,"1. that estimates of the total demographic losses",null,1,null),
(111,13,"2. of the Soviet Union is human sacrifice",null,1,null),
(112,13,"3. as this war consumed significant material resources",null,1,null),
(113,13,"4. and other efforts of the state and the people",null,1,null),
(114,13,"5. on the national economy of the country",null,1,null),
(115,13,"6. which can have an impact for many years",null,1,null),
(116,13,"7. and over 6 million buildings",null,1,null);

INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(165,110,"A", "4", True),
(166,111,"B", "6", True),
(167,112,"C", "3", True),
(168,113,"D", "7", True),
(169,114,"E", "5", True),
(170,115,"F", "2", True);
-- 116 item_id не нужен

INSERT INTO task(id,section_id, hint, title, file_link, text, text_after_answer, type) VALUES
(14,7,
"Установите соответствие между заголовками 1–7 и текстами A–F
Запишите свои ответы в таблицу.
Используйте каждую цифру только один раз.
В задании есть один лишний заголовок",
null,
null,
"
A.	The anti-Hitler coalition, as a military-political alliance of states and nations fighting against the aggressive fascist bloc of Germany, Italy, Japan, and their allies, was ultimately formed not before, but during World War II. This fact reflects, on one hand, the complex relationships within this alliance, and on the other hand, it vividly demonstrates the increasing price humanity had to pay for the narrow self-serving policies of the leaders of the leading world powers in the latter half of the 1930s, including the refusal to cooperate with the USSR in the fight against the rising fascism.
B.	The attack by Germany on the USSR on June 22, 1941, marked the transition of World War II into a new phase. The leaders of Great Britain and the United States publicly expressed their support for the USSR in the war against fascist Germany. On June 22, 1941, British Prime Minister W. Churchill made such a declaration, followed by U.S. President F. Roosevelt on June 24, 1941. Thus, under the threat of deadly danger posed by fascism, an alliance began to form, uniting previously irreconcilable \"partners\" – the Soviet Union, Great Britain, and the United States.
C.	Despite the prevailing doubts in London and Washington about the imminent military defeat of the Soviet Union, the USSR began to receive military-technical and economic assistance from abroad in the early months of the war. On August 16, 1941, the USSR received a credit of 10 million pounds sterling from Great Britain for a term of five years, as well as a supply of British-made weapons against this credit. By October 1941, the first shipment of British-made weapons arrived at the ports of Arkhangelsk and Murmansk. The first joint military action of the USSR and Great Britain was the operation codenamed \"Operation Consent\" (August 25 – September 17, 1941), conducted with the aim of gaining control over Iran and preventing its rapprochement with Germany.
D.	Besides the rapprochement between Moscow and London, by the fall of 1941 there was a breakthrough in the rapprochement between the USSR and the USA. In September, the U.S. Congress recognized the defense of the USSR as vital to U.S. interests, and starting from October 1, 1941, the USSR was included in the lend-lease program.The legal basis for the creation of the Anti-Hitler Coalition was the Declaration of the United Nations, signed in Washington on January 1, 1942, by representatives of 26 nations. The governments of these countries committed to employing all their economic and military resources against the members of the aggressive Tripartite Pact and any states that joined it. The countries that signed the Declaration pledged to cooperate closely with one another and not to conclude a separate peace or armistice with common enemies.
E.	However, in addition to diplomatic, economic, and material-technical assistance, the USSR also needed military support from its allies. Such support would have been particularly relevant in 1941 and 1942. The issue of opening a second front in Europe was one of the most problematic points in the relationships between the main participants in the Anti-Hitler Coalition, the members of the \"Big Three\" – the USSR, the USA, and Great Britain – throughout the Great Patriotic War. The military actions of the Allies on peripheral theaters of World War II from 1941 to 1943 were met with numerous criticisms from the Soviet leadership, and serious objections were raised concerning the location from which active military operations in Europe should begin.
F.	The persistent requests of the Soviet leadership were heard by the Allies only by 1943, when a fundamental turning point occurred in the armed struggle on the Soviet-German front, shifting the strategic initiative into the hands of the Soviet command. Specific decisions regarding the opening of a second front in Europe were made only at the Tehran Conference of the \"Big Three\" from October 28 to November 1, 1943. At this conference in Iran, both the location for the landing of Allied troops—northern France—and the start date—May 1, 1944—were agreed upon. Thus, by the time the second front was opened in Europe, the outcome of the armed struggle between the USSR and Germany was, in fact, predetermined. By that time, few doubted that the Red Army could defeat the Wehrmacht independently.
",
null,
"match");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(117,14,"1. The Turning Point of World War II",null,1,null),
(118,14,"2. United Against Fascism",null,1,null),
(119,14,"3. Too Late to Matter?",null,1,null),
(120,14,"4. The Quest for a Second Front",null,1,null),
(121,14,"5. The Catastrophic Impact of Aggression",null,1,null),
(122,14,"6. Early Allied Support ",null,1,null),
(123,14,"7. Created through Confrontation",null,1,null);

INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(171,117,"A", "7", True),
(172,118,"B", "1", True),
(173,119,"C", "6", True),
(174,120,"D", "2", True),
(175,121,"E", "4", True),
(176,122,"F", "3", True);
-- 123 item_id не нужен

-- Test yourself
INSERT INTO task(id,section_id, hint, title, file_link, text, text_after_answer, type) VALUES
(15,8,
null,
null,
null,
null,
null,
"multiple_choice");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(124,15,"1. During the Great Patriotic War, the aggressors completely or partially destroyed",
"A. over 170 towns and settlements
B. over 1700 towns and settlements
C. more than 7 thousand villages
D. more than 70 thousand villages",1,null),

(125,15,"2. The final figure of demographic losses of the USSR, 26.549 million people, was announced",
"A. by the UN Human Rights Commission on May 8, 2015.
B. by the General Secretary of the CPSU M.S. Gorbachev on May 8, 1985.
C. by the President of the Russian Federation B.N. Yeltsin on May 8, 1995.
D. by the writer, public and political figure A.I. Solzhenitsyn on May 8, 2005.",1,null),

(126,15,"3. When discussing the losses of the armed forces of any state, it is essential to clarify what type of losses are being referred to. For example, in addition to irretrievable losses resulting from combat operations, we also distinguish",
"A. Acceptable losses – the percentage of personnel losses during combat operations that does not impact the combat readiness of the unit, subunit, or formation.
B. Sanitary losses – the number of servicemen temporarily rendered unfit for duty due to injuries, concussions, or illnesses.
C. Tolerable losses – the approximate percentage of expected losses among the personnel of a unit, subunit, or formation, which is used to assess the skill of commanders in battle.
D. Non-combat losses – the number of servicemen who died from illnesses, were killed in accidents and incidents, or were sentenced to execution.",1,null),

(127,15,"4. An important indicator for evaluating military art is the average daily losses over periods and campaigns of a particular war. The highest average daily losses of the Red Army were",
"A. in the summer-autumn campaign of 1941.
B. in the summer-autumn campaign of 1942.
C. in the summer-autumn campaign of 1943.
D. in the summer-autumn campaign of 1944.",1,null),

(128,15,"5. The dynamics of side losses on the Soviet-German front is revealed by the ratio of average monthly losses during different periods of the war. In this context, the losses of Soviet troops in the Great Patriotic War",
"A. exceeded the losses of the Wehrmacht in all periods of the war
B. exceeded the losses of the Wehrmacht in the first period of the war
C. exceeded the losses of the Wehrmacht in the second period of the war
D. exceeded the losses of the Wehrmacht in the third period of the war.",1,null),

(129,15,"6. The Red Army",
"A. never achieved technical superiority over the Wehrmacht
B. achieved it in the second half of the Great Patriotic War
C. achieved it by the spring of 1942
D. achieved it by 1945 with the inclusion of Eastern European countries into the anti-Hitler coalition",1,null),

(130,15,"7. Which award was not established in the USSR during the Great Patriotic War?",
"A. Order of Alexander Nevsky
B. Order of the Don
C. Order of Suvorov
D. Order of Kutuzov",1,null),

(131,15,"8. The anti-Hitler coalition as a military-political alliance of states and nations was ultimately formed",
"A. with the rise of Hitler to power in Germany - already by the end of 1933;
B. during World War II, after the onset of the Great Patriotic War, from July 1941;
C. after the final formation of the aggressive fascist bloc - Germany, Italy, Japan, and their allies - in the late 1930s;
D. during World War II, after the start of the Polish campaign and the declaration of war on Germany by France and Great Britain in early September 1939.",1,null),

(132,15,"9. The legal foundation for the creation of the Anti-Hitler Coalition was the Declaration of the United Nations, signed by representatives of 26 countries",
"A. in Paris on November 1, 1941
B. in Moscow on December 1, 1941
C. in Washington on January 1, 1942
D. in London on February 1, 1942",1,null),

(133,15,"10. The most pressing problematic issue in the relationships between the main participants of the Anti-Hitler Coalition during World War II was the question of:",
"A. the acceptance of the surrender by representatives of Germany
B. the opening of a second front in Europe
C. the supply of weapons and material resources under Lend-Lease
D. the locations of meetings of the leaders of the 'Big Three' - the USSR, the USA, and Great Britain",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(177,124,null, "bd", TRUE),
(178,125,null, "c", TRUE),
(179,126,null, "bc", TRUE),
(180,127,null, "c", TRUE),
(181,128,null, "bc", TRUE),
(182,129,null, "b", TRUE),
(183,130,null, "b", TRUE),
(184,131,null, "b", TRUE),
(185,132,null, "c", TRUE),
(186,133,null, "b", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(134,15,"11. The first Washington Conference of the heads of state and government of the USA and Great Britain (December 22, 1941 - January 14, 1942) decided to:",
"A. open a second front in Europe in 1942
B. open a second front in Europe in 1943
C. start delivering Lend-Lease supplies to the USSR
D. begin developing nuclear weapons",1,null),

(135,15,"12. The Moscow Conference of Foreign Ministers of the USSR, the USA, and Great Britain (October 19-30, 1943) did not discuss the issue of:",
"A. opening a second front in Europe
B. Germany's post-war structure
C. the USA's entry into the war against Japan
D. Japan's post-war structure",1,null),

(136,15,"13. The Tehran Conference of the heads of state and government of the USSR, the USA, and Great Britain (November 28 - December 1, 1943) resulted in:",
"A. a decision to open a second front in Western Europe in May 1944
B. the unconditional surrender of Germany
C. plans for Japan's occupation zones
D. the establishment of the United Nations",1,null),

(137,15,"14. The Crimean (Yalta) Conference of the heads of state and government of the USSR, the USA, and Great Britain (February 4-11, 1945) did not address the issue of:",
"A. the unconditional surrender of Germany
B. Japan's post-war structure
C. the creation of the United Nations
D. the USSR's entry into the war against Japan",1,null),

(138,15,"15. The Potsdam Conference of the heads of state and government of the USSR, the USA, and Great Britain (July 17 - August 2, 1945) resulted in:",
"A. a decision on Germany's four occupation zones
B. plans for nuclear disarmament
C. the Nuremberg Trials arrangements
D. the signing of Japan's surrender",1,null),

(139,15,"16. The main goal of the Nuremberg Trials was:",
"A. the complete liquidation of the Nazi Party
B. punishment of war criminals
C. returning occupied territories
D. creating a legal precedent for international justice",1,null),

(140,15,"17. The main verdict at the Nuremberg Trials was:",
"A. life imprisonment for all Nazi leaders
B. execution of the main war criminals
C. exile of Nazi officials
D. imprisonment with parole for good behavior",1,null),

(141,15,"18. The United Nations was officially established:",
"A. in Moscow in 1943
B. in Tehran in 1944
C. in San Francisco in 1945
D. in New York in 1946",1,null),

(142,15,"19. The first Secretary-General of the United Nations was:",
"A. Trygve Lie
B. Dag Hammarskjöld
C. U Thant
D. Kurt Waldheim",1,null),

(143,15,"20. The Soviet Union joined the war against Japan on:",
"A. August 6, 1945
B. August 8, 1945
C. August 9, 1945
D. August 15, 1945",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(187,134,null, "b", TRUE),
(188,135,null, "d", TRUE),
(189,136,null, "a", TRUE),
(190,137,null, "b", TRUE),
(191,138,null, "ac", TRUE),
(192,139,null, "b", TRUE),
(193,140,null, "b", TRUE),
(194,141,null, "c", TRUE),
(195,142,null, "a", TRUE),
(196,143,null, "b", TRUE);


-- The causes of the Second World War
-- Grammar and vocabulary
INSERT INTO task(id,section_id, hint, title, file_link, text, text_after_answer, type) VALUES
(16,9,
"Прочитайте приведённый ниже текст / приведённые ниже тексты.
Преобразуйте, если необходимо, слова, напечатанные заглавными буквами в конце строк, обозначенных номерами 1–6, так,
чтобы они грамматически соответствовали содержанию текстов.
Заполните пропуски полученными словами. ",
"The Soviet-German rapprochement",
null,
null,
null,
"fix_word"),
(17,9,
"буквами в конце строк, обозначенных номерами 7–11, однокоренные слова так,
чтобы они грамматически и лексически соответствовали содержанию текста.
Заполните пропуски полученными словами. ",
"Military operations in Manchuria",
null,
null,
null,
"fix_word"),
(18,9,
"Прочитайте текст с пропусками, обозначенными номерами 12–18.
Эти номера соответствуют заданиям 12–18, в которых представлены возможные варианты ответов.
Запишите в поле ответа цифру 1, 2, 3 или 4, соответствующую выбранному Вами варианту ответа.",
"The Civil War and the reflection of the German-Italian intervention in Spain",
null,
"The beginning of the hostilities of this war should be considered the military 12____________ of General Franco on July 17, 1936 in Spanish Morocco and the transfer of hostilities to the territory of Spain itself. The countries with fascist regimes, Germany and Italy, 13 ________ to the aid of the rebels, as a result of which the civil war turned into a national revolutionary one. For three years, up to 300,000 14 _________ soldiers (at least 50,000 Germans, 150,000 Italians, and 20,000 Portuguese) fought on Franco's side at various times. The fighting in Spain was accompanied by a policy of \"non-interference\" by the official circles of Britain, France and the United States and the growth of the solidarity movement to the Spanish people. More than 52,000 volunteers from 54 countries 15_________ in Spain, from which 6 international brigades and 3 separate battalions were formed, which became the core of the People's Army of the Republic.
The war in Spain was one of the bloodiest on the eve of the Second World War. In the spring of 1937, the Republicans had more than 460,000 men 16 _________ arms, while the Francoists had 258,000 men. In 1937-1938, about 1 million people were drafted into the army. The total length of the front line was up to 2,000 km, and the largest 17 _________ of armed forces on both sides reached 2 million people.
The war ended with the fall of the republican government and its subsequent agreement with the Francoists. Over the course of three years, 6 campaigns were 18 _________ out, four front-line and dozens of army operations were conducted (on both sides). More than 1 million people died in the course of military operations, bombing and repression. About 3,000 Soviet volunteers fought on the side of the republic, about 200 of them died bravely.
",
null,
"text_answer");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(144, 16, "SIGH",
"The Soviet-German rapprochement began in the early 1920s. Already on April 16, 1922, Germany and the RSFSR _________ an agreement during the Genoa Conference in Rapallo (Italy), providing for the immediate restoration of full diplomatic relations, the refusal to reimburse military expenses and non-military losses, and Germany's recognition of the results of the nationalization of German property in the Soviet Republic.",
1, "1"),
(145, 16, "JOIN",
"The Rappala Treaty, which allowed the countries to maintain and mutually develop the military-technical potential accumulated during the First World War, _________ by Soviet Belarus, Ukraine, Armenia and Azerbaijan.",
1, "2"),
(146, 16, "FACTORY",
"During military cooperation in the USSR, military _________ were reconstructed with the help of German specialists, and training schools for German specialists were organized at military schools and at aerochemical landfills near Moscow and in the Saratov region near Volsk. ",
1, "3"),
(147, 16, "THEY",
"The peculiarity of this stage of cooperation between Germany and the USSR was that the cooperation was paid for by the German side, since the facilities were provided by the Soviet side, however, German engineers and military specialists not only trained _________ own, but also Soviet wards, providing advanced technologies and samples of military weapons and equipment for research.",
1, "4"),
(148, 16, "BECOME",
"After 1925, the mutual exchange and dispatch of military delegations from the high command of the armies of both countries to maneuvers and large-scale exercises_________ regular",
1, "5"),
(149, 16, "GOOD",
"Thus, in the course of military-technical cooperation in 1922-1933, the Red Army gained access to the technical achievements of the German military industry and modern approaches to training specialists from various branches of the armed forces, while the Reichswehr had the opportunity to train groups of pilots, tankers and specialists in chemical weapons , as _________ as with the help of subsidiaries of the German military The industry should train its specialists in the manufacture of weapons and military equipment in the USSR.",
1, "6");


INSERT INTO item(id, task_id, title, text, points, number) VALUES
(150, 17, "EXPLODE",
"The Manchurian incident (the _________ of about 1.5 m of railway track near Mukden – today Shenyang), on September 18, 1931, served as the reason for the beginning of the seizure of Manchuria by the Kwantung Army of Japan.",
1, "7"),
(151, 17, "JAPAN",
"After the incident on September 19, the _________ captured the Mukden fortress during a 6-hour battle. ",
1, "8"),
(152, 17, "POOR",
"The Chinese lost about 500 people killed, and the _________ trained garrison of the fortress fled.",
1, "9"),
(153, 17, "RESOLVE",
"On October 24, the League of Nations adopted a _________ condemning Japan's aggression and proposing the withdrawal of troops from Manchuria within three weeks. Japan refused.",
1, "10"),
(154, 17, "INDEPENDENCE",
"The _________ state of Manchukuo was established on March 1, 1932, based on the decision of the All-Manchu Conference, which elected the former Chinese Emperor Pu Yi as its Supreme Ruler.",
1, "11");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(155,18,null,null,1,"12"),
(156,18,null,null,1,"13"),
(157,18,null,null,1,"14"),
(158,18,null,null,1,"15"),
(159,18,null,null,1,"16"),
(160,18,null,null,1,"17"),
(161,18,null,null,1,"18");

INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(197,144,null, "signed", True),
(198,145,null, "was joined", True),
(199, 146, NULL, "factories", TRUE),
(200, 147, NULL, "their", TRUE),
(201, 148, NULL, "became", TRUE),
(202, 149, NULL, "well", TRUE),
(203, 150, NULL, "explosion", TRUE),
(204, 151, NULL, "japanese", TRUE),
(205, 152, NULL, "poorly", TRUE),
(206, 153, NULL, "resolution", TRUE),
(207, 154, NULL, "independent", TRUE);

INSERT INTO answer_option(id, item_id,text, left_text, is_correct) VALUES
(208,155,'1',"1)	trouble", False),
(209,155,'2',"2)	rebellion", True),
(210,155,'3',"3)	wealth", False),
(211,155,'4',"4)	feast", False),

(212, 156, '1', "1)	came", True),
(213, 156, '2', "2)	arrived", False),
(214, 156, '3', "3)	gone", False),
(215, 156, '4', "4)	approached", False),

(216, 157, '1', "1)	native", False),
(217, 157, '2', "2)	local", false),
(218, 157, '3', "3)	strange", False),
(219, 157, '4', "4)	foreign", true),

(220, 158, '1', "1)	went", False),
(221, 158, '2', "2)	reached", False),
(222, 158, '3', "3)	arrived", True),
(223, 158, '4', "4)	determined", false),

(224, 159, '1', "1)	under", True),
(225, 159, '2', "2)	с", False),
(226, 159, '3', "3)	on", False),
(227, 159, '4', "4)	in", false),

(228, 160, '1', "1)	number", True),
(229, 160, '2', "2)	account", false),
(230, 160, '3', "3)	amount", False),
(231, 160, '4', "4)	plenty", False),

(232, 161, '1', "1)	worn", False),
(233, 161, '2', "2)	carried", True),
(234, 161, '3', "3)	brought", false),
(235, 161, '4', "1)	taken", False);

-- Listening
INSERT INTO task(id,section_id, hint, title, file_link, text, text_after_answer, type) VALUES
(19,10,
"Вы услышите монолог о планах агрессии нацисткой Германии, фашистской Италии и милитаристской Японии.
В заданиях 1 – 7 запишите в поле ответа цифру 1,2 или 3, соответствующую выбранному Вами варианту ответа.
Вы услышите запись дважды.",
null,
"Listening1.mp3",
"
1.	What was the stated goal of Germany, Italy and Japan, hiding their true intentions?
a)	Protection of small countries from aggression
b)	The establishment of democracy in Europe
c)	The struggle against the USSR

2.	When was the Imperial Defense Council established in Germany?
a)	In 1936
b)	In 1933
c)	In 1941

3.	Which ministry previously included the Gestapo?
a)	Ministry of Internal Affairs
b)	Ministry of Foreign Affairs
c)	Ministry of Propaganda

4.	What is the essence of the concept of total war?
a)	The war is fought between states using limited resources.
b)	The war is fought only on enemy territory.
c)	The war is waged between nations using all available resources and methods.

5.	What was the name of the military strategy based on a fast and lightning offensive used by Nazi Germany?
a)	Blitzkrieg
b)	Trench warfare
c)	Positional Warfare

6.	What happened to Poland by the end of September 1939?
a)	It ceased to exist as a state
b)	It retained her independence
c)	It became an ally of Germany

7.	What impact did the subjectivity of assessment and the priority of subordinate structures have on the conduct of military operations?
a)	Improved the planning of operations
b)	Negatively affected the planning and conduct of operations
c)	Increased the efficiency of operations
",
"
The main goal of Germany, Italy, and Japan was to rule the world. They hid it behind fighting against the USSR.
In Germany, the entire government system was adapted to the requirements of waging aggressive war. At the top of state and political power in Germany was the Imperial Cabinet, headed by the Fuhrer of the Nazi Party, Chancellor Adolf Hitler. The main link in the system of the fascist dictatorship and its ideological core was the National Socialist Party, which had a vertical structure. The members of the Nazi Party who were at the head of these structural units, as well as those who held responsible positions in the Imperial party leadership, were called political leaders. Assault and security detachments, National Socialist unions, and societies permeating the entire German society were also created on a party basis.
The restructuring of the German state apparatus to manage military operations was completed by the end of the 1930s. The beginning of these transformations can be considered the formation of the Imperial Defense Council in 1933, on the basis of a special secret state apparatus. In 1936, the commanders-in-chief of the armed forces were introduced into the Imperial Defense Council, who were equated with government ministers in the table of ranks and were given the right to participate in meetings of the latter. On August 30, 1939, two days before the outbreak of war, a Decree was issued on the organization of the Council of Ministers for the Defense of the Empire, and by Decree of September 1, 1939, the posts of Reich defense commissars were established, charged with coordinating the actions of military and civilian authorities across the country's districts. In 1939, the Main Directorate of Imperial Security was established, which included the Gestapo, which had previously been part of the German Ministry of the Interior, as the IV department.
 Along with structural transformations in the system of state and military administration in Germany, an important place in solving the main foreign policy goal of the Nazi leadership – the military conquest of world domination, was given to the development of military-political foundations in the field of military security, that is, the provisions of the Military Doctrine of the state.
The idea of total war, the concept of which was developed in 1935 by German General Erich Ludendorff, was taken as the basis for conducting military operations at the military-political level. According to this concept, modern warfare is not a war of armies, but of nations, in which the parties involved use all available resources and methods to defeat the enemy. Therefore, in order to win, it is necessary: on the one hand, the mobilization of all the resources of \"one\'s own\" nation, on the other – a comprehensive impact on a hostile nation, including methods such as propaganda and terror. The main task was to break her spirit and get her to demand that her government stop resisting.
The doctrinal positions of Nazi Germany at the military-strategic level were reduced to the provisions of the blitzkrieg, a short-lived or lightning war. The purpose of the first stage of the tank forces' action was to break into the enemy's rear to a great depth without getting involved in battles for heavily fortified positions in the tactical zone of his defense.
At the second stage of the offensive, when entering the operational space, the main tasks were to capture control centers and disrupt enemy supply lines.
Thus, the main enemy forces, which found themselves without control and supplies, quickly lost their combat capability, which created the conditions for the combat missions of the motorized infantry advancing from the front. In practice, the theoretical provisions of the Blitzkrieg were successfully implemented by German military strategists at the beginning of World War II during the capture of Poland and France. Thus, by the end of September 1939, the Polish state had ceased to exist, although more than a million people of draft age remained in Poland. When assessing the contribution of the armed forces to solving military tasks in a future war, the Supreme High Command of the Wehrmacht held views on the possibility of changing their importance in the course of a future war. So, in the early stages of the war, when the armed struggle would be waged against the continental European states, the main role was assigned to the ground forces. In the future, due to the changes that will occur during the war, it was assumed that the role of various types of armed forces would change and \"operations in the air or at sea would become crucial.\" At the same time, the leadership of the armed forces defended the opinion about the priority of their subordinate structures in a future war, which negatively affected the objectivity of this assessment and the planning and conduct of military operations in general. At the same time, mechanized and tank troops were considered the elite of the ground forces, bomber and fighter aircraft in the air force, and the submarine fleet in the navy.
Thus, by the end of the summer of 1939, the preparations for the great war, which had been carried out in Germany for several years with genuine German punctuality, had largely ended. The country began to occupy a central place in the fascist bloc in terms of the degree of preparation of the state for the war for world domination and in terms of the completeness and quality of the development of its doctrinal provisions.
",
"listen_answer");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(162,19,null,null,1,"1"),
(163,19,null,null,1,"2"),
(164,19,null,null,1,"3"),
(165,19,null,null,1,"4"),
(166,19,null,null,1,"5"),
(167,19,null,null,1,"6"),
(168,19,null,null,1,"7");

INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(236,162,null, "c", True),
(237,163,null, "b", True),
(238,164,null, "a", True),
(239,165,null, "c", True),
(240,166,null, "a", True),
(241,167,null, "a", True),
(242,168,null, "b", True);

-- Reading
INSERT INTO task(id,section_id, hint, title, file_link, text, text_after_answer, type) VALUES
(20,11,
"Прочитайте текст и заполните пропуски A–F частями предложений, обозначенными цифрами 1–7.
Одна из частей в списке 1–7 лишняя.
Занесите цифры, обозначающие соответствующие части предложений, в таблицу.",
"Russophobia",
null,
"Anti-Sovietism and A_____________________________ by the ruling circles of leading European countries and the United States led to a policy of isolation of young Soviet Russia and later the USSR in the 1920s. One of the manifestations of the policy of isolationism was the creation after the First World War of buffer countries east of the states of old Western Europe on the \"ruins\" of former empires. For this purpose,B_____________________________  of international relations was implemented - the right of nations to self–determination, which in practice meant not only the creation of separate states along national lines (Finns - Finland, Poles – Poland, Hungarians – Hungary), but also changing the borders of existing countries.
As a result, the independence of Hungary, the Baltic states C_____________________________   were internationally recognized (while the Lithuanian Vilna Region became part of Poland, and the German Klaipeda region was ceded to Lithuania), and the proclamation of Czechoslovakia, which D____________________. Poland was recreated, and some East German lands were transferred to it and a \"corridor\" to the Baltic Sea was allocated. Transylvania was transferred to Romania, and the Hungarian region of Vojvodina became part of the newly formed Kingdom of Serbs, Croats and Slovenes – the future Yugoslavia.
According to the winners, the buffer states, primarily Poland, Czechoslovakia and Lithuania, E_______________________________in the east and the USSR in the west. However, in fact, it turned out that the priority of political and military-strategic considerations of the victorious states, while ignoring the interests of the defeated and newly formed countries (Austria, Hungary, Yugoslavia, Czechoslovakia, Poland, Finland, Latvia, Lithuania, Estonia), F ________________________________and national problems in Europe. In addition, the attempt to use the new states that arose in Europe against both the Bolshevik revolution and German revanchism was clearly unsuccessful, which only increased the rapprochement between Germany, \"offended\" by the Versailles agreements, and the \"isolated\" USSR.
",
null,
"match");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(169,20,"1.	one of the most important principles ",null,1,null),
(170,20,"2.	the desire to limit the spread of communist ideas",null,1,null),
(171,20,"3.	had never existed before",null,1,null),
(172,20,"4.	that separated from Russia",null,1,null),
(173,20,"5.	using the armed forces of a nation",null,1,null),
(174,20,"6.	should be a constant source of tension for Germany",null,1,null),
(175,20,"7.	only gave rise to many territorial disputes",null,1,null);

INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(243,169,"A", "2", True),
(244,170,"B", "1", True),
(245,171,"C", "4", True),
(246,172,"D", "3", True),
(247,173,"E", "6", True),
(248,174,"F", "7", True);
-- 175 item_id не нужен

-- Test yourself
INSERT INTO task(id,section_id, hint, title, file_link, text, text_after_answer, type) VALUES
(21,12,
null,
null,
null,
null,
null,
"multiple_choice");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(176, 21, "1. What event can be considered the beginning of the transformation of the German state apparatus in the military sphere?",
"a) Formation of the Imperial Defense Council
b) Issuing a decree on the organization of the Council of Ministers of Defense of the Empire
c) Introducing the commanders of the Armed Forces to the Imperial Defense Council
d) Creation of the General Directorate of Imperial Security",
1, NULL),

(177, 21, "2. What was the task of the Imperial Defense Commissars?",
"a) Coordination of military and civilian authorities
b) Monitoring the activities of ministries
c) Development of military plans
d) Economic management",
1, NULL),

(178, 21, "3. By what time had the preparations for war largely ended in Germany?",
"a) By the middle of the spring of 1939.
b) By the beginning of autumn 1941.
c) By the end of the winter of 1940.
d) By the end of the summer of 1939.",
1, NULL),

(179, 21, "4. What impact did the protection of departmental interests have on the planning of military operations?",
"a) It made planning more objective.
b) It reduced the objectivity of planning.
c) It improved planning efficiency.
d) It had no effect.",
1, NULL),

(180, 21, "5. What was the policy pursued by the ruling circles of the leading European countries and the United States towards Soviet Russia in the 1920s?",
"a) Policy of financial support
b) Active cooperation policy
c) Policy of isolation
d) Policy of military intervention",
1, NULL),

(181, 21, "6. What was the goal of creating buffer states after the First World War?",
"a) The creation of a single European economic area
b) Ensuring cultural exchange between different peoples
c) Limiting the spread of Communist ideas and containing Germany
d) Strengthening economic ties between Eastern and Western Europe",
1, NULL),

(182, 21, "7. What was the result of the attempt to use the new states against the Bolshevik revolution and German revanchism?",
"a) Partially successful
b) Led to the immediate collapse of the USSR
c) Clearly unsuccessful
d) Completely successful",
1, NULL),

(183, 21, "8. What has increased as a result of the policy of isolating the USSR and Germany's dissatisfaction with the terms of the Treaty of Versailles?",
"a) Strengthening the position of the League of Nations
b) Rapprochement between Germany and the USSR
c) Deterioration of relations between Germany and the USSR
d) Britain's growing influence in Europe",
1, NULL),

(184, 21, "9. What did the Rapallo Treaty provide for?",
"a) Partition of Poland between Germany and the RSFSR.
b) The entry of the RSFSR into the League of Nations.
c) Immediate restoration of diplomatic relations, refusal to reimburse military expenses and recognition of the nationalization of German property.
d) Joint construction of the Berlin Wall.",
1, NULL),

(185, 21, "10. Where were the training schools for German specialists located in the USSR?",
"a) At military schools and airfield ranges near Moscow and in the Saratov region near Volsk
b) In Crimea and the Caucasus
c) In Siberia and the Far East
d) In Leningrad and Kiev",
1, NULL);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(249, 176, NULL, "a", TRUE),
(250, 177, NULL, "a", TRUE),
(251, 178, NULL, "d", TRUE),
(252, 179, NULL, "b", TRUE),
(253, 180, NULL, "c", TRUE),
(254, 181, NULL, "c", TRUE),
(255, 182, NULL, "c", TRUE),
(256, 183, NULL, "b", TRUE),
(257, 184, NULL, "c", TRUE),
(258, 185, NULL, "a", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(186, 21, "11. What did the Red Army get as a result of military-technical cooperation with Germany?",
"a) Access to the technical achievements of the German military industry and modern approaches to training specialists.
b) Control over German military factories.
c) The right to occupy a part of Germany.
d) Full control over the German army.",
1, NULL),

(187, 21, "12. In what period of time did military-technical cooperation between Germany and the USSR take place?",
"a) 1917-1921
b) 1939-1941
c) 1945-1991
d) 1922-1933",
1, NULL),

(188, 21, "13. What was the reason for the beginning of the seizure of Manchuria by the Kwantung Army of Japan?",
"a) Violation by China of trade agreements with Japan.
b) The attack of Chinese troops on Japanese territory.
c) Explosion of about 1.5 m of railway track near Mukden.
d) The assassination of a Japanese diplomat in Manchuria.",
1, NULL),

(189, 21, "14. When did the Manchurian Incident occur?",
"a) On October 24, 1931.
b) March 1, 1932.
c) Since September 18, 1931.
d) September 19, 1931.",
1, NULL),

(190, 21, "15. What resolution was adopted by the League of Nations in connection with Japan's actions in Manchuria?",
"a) It condemned Japan's aggression and offered to withdraw troops.
b) It provided financial assistance to Japan.
c) It approved Japan's actions.
d) It called for negotiations between Japan and China.",
1, NULL),

(191, 21, "16. How did Japan react to the League of Nations resolution?",
"a) It ignored the resolution.
b) It agreed to withdraw the troops.
c) It offered a compromise.
d) It refused.",
1, NULL),

(192, 21, "17. When should the outbreak of hostilities of the Spanish Civil War be considered?",
"a) Since the outbreak of hostilities in Spain.
b) Since the declaration of war by the Republicans.
c) Since Germany entered the war.
d) Since the military mutiny of General Franco in Spanish Morocco on July 17, 1936.",
1, NULL),

(193, 21, "18. Which countries provided assistance to the Franco-led rebels?",
"a) The United States and Portugal.
b) Great Britain and France.
c) Germany and Italy.
d) The USSR and Mexico.",
1, NULL),

(194, 21, "19. How many foreign soldiers fought on Franco's side?",
"a) About 3,000.
b) Is more than 1 million.
c) Up To 300,000.
d) About 52,000.",
1, NULL),

(195, 21, "20. What policies did the United Kingdom, France, and the United States pursue regarding the war in Spain?",
"a) They actively supported the Republicans.
b) Provided financial assistance to Franco.
c) Has deployed troops to protect its citizens.
d) Pursued a policy of 'non-interference'.",
1, NULL);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(259, 186, NULL, "a", TRUE),
(260, 187, NULL, "d", TRUE),
(261, 188, NULL, "c", TRUE),
(262, 189, NULL, "c", TRUE),
(263, 190, NULL, "a", TRUE),
(264, 191, NULL, "d", TRUE),
(265, 192, NULL, "d", TRUE),
(266, 193, NULL, "c", TRUE),
(267, 194, NULL, "c", TRUE),
(268, 195, NULL, "d", TRUE);

-- The main events of the Second World War
-- Grammar and vocabulary
INSERT INTO task(id,section_id, hint, title, file_link, text, text_after_answer, type) VALUES
(22,13,
"Прочитайте приведённый ниже текст.
Образуйте от слов, напечатанных заглавными буквами в конце строк, обозначенных номерами 1–6, однокоренные слова так,
чтобы они грамматически и лексически соответствовали содержанию текста.
Заполните пропуски полученными словами. ",
"The Soviet Union in World War II: A Pivotal Conflict",
null,
null,
null,
"fix_word"),
(23,13,
"Прочитайте приведённый ниже текст / приведённые ниже тексты.
Преобразуйте, если необходимо, слова, напечатанные заглавными буквами в конце строк, обозначенных номерами 7–12, так,
чтобы они грамматически соответствовали содержанию текстов.
Заполните пропуски полученными словами. ",
"The First Period of the Great Patriotic War",
null,
null,
null,
"fix_word"),
(24,13,
"Прочитайте текст с пропусками, обозначенными номерами 12–18.
Эти номера соответствуют заданиям 13–18, в которых представлены возможные варианты ответов.
Запишите в поле ответа цифру 1, 2, 3 или 4, соответствующую выбранному Вами варианту ответа.",
"Allied military actions",
null,
"
In the second period of the war, large-scale military operations 13. _____________ in the Pacific Theatre of Operations. A major event was the surprise attack by the Japanese fleet on the United States' main naval base in the Pacific, Pearl Harbor, on December 7, 1941.
14. _________________, the U.S. Pacific Fleet suffered significant losses. This marked the beginning of the war between Japan and the United States, drawing hundreds of millions of people into its orbit. On December 11, 1941, Germany, Italy, and their European allies declared war on the United States. In response, the United Kingdom, Australia, New Zealand, Canada, and several other countries declared war on Japan.
After seizing naval and air supremacy, Japan 15. ________________ a broad strategic offensive in Southeast Asia and the western Pacific region. In the first 5-6 months, its armed forces captured territories 10 times larger than Japan itself. The United States and the United Kingdom lost key strategic positions in Southeast Asia—Singapore, Hong Kong, Rangoon, Manila. The enemy's advance to the south and west created a threat to Australia and India; the landing on the Aleutian Islands 16. ___________________a risk to the maritime communications of the U.S., the U.K., and Canada in the northern Pacific.
In the North African Theatre of Operations, fighting happened with varying success from 1941 to 1942. Against the 8th British Army, between 9 to 15 Italian-German divisions were deployed at different times. Battles were fought along a narrow coastal strip, with much of the time spent in positional combat and operational pauses. The short-term active engagements were characterized by \"leaps\": three times from west to east and three times from east to west. During these \"leaps,\" the front line shifted 600-800 km each time (the so-called \"African quadrille\"). Neither side managed to achieve a decisive success. In the second half of 1942, after another Italian-German offensive, the front line stabilized at the El Alamein line in Egypt.
Combat actions on the Mediterranean Sea also saw varying success. 17. ____________, the numerical superiority in aviation and the better technical condition of the fleet allowed the Western Allies to gain control of the seas and the air. However, they were never able to fully disrupt the enemy's maritime communications until the conclusion of military operations in North Africa.
Thus, during the second period of World War II, the armed forces of the fascist-militarist alliance 18. ______________ significant successes in almost all theatres of war. It was only by the end of 1942 that the armed forces of the Allies managed to halt the further advance of the enemy and create the necessary conditions for starting offensive actions. The decisive role in creating these conditions belonged to the Soviet Armed Forces, which 19. ____________________ the overwhelming majority of German forces and aviation on the Soviet-German front, thereby ensuring freedom of movement for the armed forces of the Allies in other theatres of World War II.
",
null,
"text_answer");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(196, 22, "DECIDE",
"The Great Patriotic War of the Soviet people and the Soviet-Japanese War were the most important and __________ components of World War II. These conflicts lasted from June 22, 1941, to September 2, 1945 (a total of 1,418 days), accounting for 65% of the total duration of World War II. During the Great Patriotic War, eight campaigns were conducted in Europe, while the Soviet-Japanese War involved one campaign in the Far East. In total, more than 50 strategic operations were carried out.",
1, "1"),
(197, 22, "DANGER",
"In the first half of 1941, the Soviet Union faced an extremely unfavourable situation. Firstly, by June 1941, the front of World War II had come _________________ close to the borders of the Soviet Union. Military operations were ongoing in Europe, Asia, and Africa, with about 30 countries drawn into the war.",
1, "2"),
(198, 22, "POLITICS",
"Secondly, Germany had seized and maintained the initiative in conducting major __________ and military actions. By this time, it had completed the formation of a military alliance with an anti-Soviet orientation, which included Italy, Japan, Hungary, Romania, Finland, Bulgaria, Slovakia, and Croatia. Spain was also an ideological ally of this alliance. ",
1, "3"),
(199, 22, "CAPABLE",
"Thirdly, as a result of Germany’s conquest of European countries, its military and economic potential increased significantly, boosting the ______________ of its war industry. The Wehrmacht was reinforced with large amounts of captured weapons, military equipment, and transport from 11 occupied countries—enough to equip up to 150 divisions.",
1, "4"),
(200, 22, "SOUTH",
"A complex and tense situation also persisted in the Far East, where Japan, despite signing a neutrality pact with the USSR on April 13, 1941, was accelerating its military preparations. With the onset of German aggression, Japan's position remained ambiguous and contradictory. All of this forced the Soviet Union to divert significant military forces and resources to secure its __________ and eastern borders.",
1, "5"),
(201, 22, "BEGIN",
"Under these circumstances, on June 22, 1941, fascist Germany launched a treacherous attack on the Soviet Union, marking the ____________ of the Great Patriotic War of the Soviet people—an essential part of World War II. The German armed forces (the Wehrmacht) acted in accordance with Plan Barbarossa, a strategy for war against the USSR, which had been approved by Hitler on December 19, 1940, under Directive No. 21.",
1, "6");


INSERT INTO item(id, task_id, title, text, points, number) VALUES
(202, 23, "DIFFICULT",
"The summer-autumn campaign of 1941 was _________________ for our country and its Armed Forces—not only during this period but throughout the entire Great Patriotic War. During this campaign, the very existence of the Soviet state was at stake.",
1, "7"),
(203, 23, "ADVANCE",
"The unfavourable situation on the eve of the war, which led to failures in its initial phase, allowed the German-fascist troops _____________ deep into Soviet territory by early December 1941, covering distances between 850 and 1,200 km. The Soviet Armed Forces suffered enormous losses in manpower and military equipment. ",
1, "8"),
(204, 23, "BLOCADE",
"Leningrad ________________, enemy forces reached the outskirts of Moscow and Tula, and occupied Kharkov, a significant part of the Donbas region, and almost all of Crimea (except for Sevastopol).",
1, "9"),
(205, 23, "DEFEAT",
"During the winter campaign of 1941–1942, the initiative shifted to the Soviet command. After exhausting and bleeding the enemy in fierce defensive battles, Soviet troops launched a counteroffensive and then a full-scale offensive ____________ the Wehrmacht’s Army Group Centre at the approaches to Moscow.",
1, "10"),
(206, 23, "COLLAPSE",
"Simultaneously, Hitler’s forces suffered defeats near Tikhvin and Rostov. The crushing defeat of the German-fascist army shattered the myth of its invincibility worldwide and demonstrated the strength of the Soviet state. Hitler’s blitzkrieg strategy _________________.",
1, "11"),
(207, 23, "LOSS",
"At the end of June 1942, German-fascist troops launched a massive offensive toward the southeast. Despite suffering heavy __________, the Wehrmacht advanced 550–800 km, reaching the Volga River near Stalingrad and the Main Caucasus Range.",
1, "12");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(208,24,null,null,1,"13"),
(209,24,null,null,1,"14"),
(210,24,null,null,1,"15"),
(211,24,null,null,1,"16"),
(212,24,null,null,1,"17"),
(213,24,null,null,1,"18"),
(214,24,null,null,1,"19");

INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(269,196,null, "decision", True),
(270,197,null, "dangerously", True),
(271, 198, NULL, "political", TRUE),
(272, 199, NULL, "capabilities", TRUE),
(273, 200, NULL, "beginning", TRUE),
(274, 201, NULL, "the most difficult", TRUE),
(275, 202, NULL, "to advance", TRUE),
(276, 203, NULL, "was blockaded", TRUE),
(277, 204, NULL, "defeating", TRUE),
(278, 205, NULL, "collapsed", TRUE),
(279, 206, NULL, "losses", TRUE);

INSERT INTO answer_option(id, item_id,text, left_text, is_correct) VALUES
(280,208,'1',"1. took part", False),
(281,208,'2',"2. took place", True),
(282,208,'3',"3. participated", False),
(283,208,'4',"4. engaged  ", False),

(284, 209, '1', "1. caught off guard", True),
(285, 209, '2', "2. caught red-handed", False),
(286, 209, '3', "3. caught up in", False),
(287, 209, '4', "4. caught between a rock and a hard place", False),

(288, 210, '1', "1. commenced", False),
(289, 210, '2', "2. carried", false),
(291, 210, '3', "3. initiated", False),
(292, 210, '4', "4. launched", true),

(293, 211, '1', "1. caused", False),
(294, 211, '2', "2. posed ", True),
(295, 211, '3', "3. led", False),
(296, 211, '4', "4. resulted", false),

(297, 212, '1', "1. unfortunately", False),
(298, 212, '2', "2. consequently", False),
(299, 212, '3', "3. ultimately", True),
(290, 212, '4', "4. meanwhile", false),

(301, 213, '1', "1. reached", false),
(302, 213, '2', "2. earned", false),
(303, 213, '3', "3. achieved", True),
(304, 213, '4', "4. obtained", False),

(305, 161, '1', "1. tied up", False),
(306, 161, '2', "2. locked up", False),
(307, 161, '3', "3. pinned down", false),
(308, 161, '4', "4. tied down", True);


-- Listening
INSERT INTO task(id,section_id, hint, title, file_link, text, text_after_answer, type) VALUES
(25,14,
"Вы услышите текст о четвертом и пятом этапе Второй Мировой Войны. В заданиях 1 – 7 запишите в поле ответа цифру 1,2 или 3, соответствующую выбранному Вами варианту ответа. Вы услышите запись дважды. ",
null,
"audio1.mp3",
"
1. Why did the United States and Great Britain hasten the opening of the second front in 1944?

1) They wanted to avoid a long war with Germany.
2) They had promised to launch the invasion in 1942.
3) They wanted to prevent the complete liberation of Europe by Soviet troops.

2. What was the name of the operation for the Allied landing in Normandy?

1) Operation Overlord
2) Operation Torch
3) Operation Bagration

3. Why did the Allies request Soviet assistance during the Battle of the Ardennes?

1) The Red Army had already planned an offensive in Poland.
2) The Allies wanted to advance into Germany faster.
3) The German counteroffensive caused heavy Allied losses.

4. Which territories were captured by the Anglo-American forces in the Pacific by mid-1945?

1) Japan’s main islands
2) The Philippine Islands, Burma, and most of Indonesia
3) Korea and Manchuria

5. What was the main reason for Japan’s surrender in World War II?

1) The atomic bombings of Hiroshima and Nagasaki
2) The Soviet Union’s entry into the war and the defeat of the Kwantung Army
3) The loss of naval dominance in the Pacific

6. What was a key feature of the Soviet Manchurian Operation?

1) The large-scale redeployment of troops from west to east
2) The use of American air support
3) The long and drawn-out nature of the battle

7. Where was the Act of Unconditional Surrender signed by Japan?

1) In Tokyo
2) Aboard the USS Missouri
3) At the Yalta Conference
",
"
The key events of the fourth period of World War II unfolded in Western Europe. The collapse of Nazi Germany paved the way for the shift of Allied efforts to the Far East, with the goal of defeating Japan.
By the summer of 1944, the international and military situation had developed in such a way that any further delay in opening the second front would have led to the complete liberation of Europe by Soviet troops. This prospect was unacceptable to the ruling circles of the United States and Great Britain, prompting them to hasten their invasion of Western Europe through the English Channel.
The strategic offensive of the Red Army in the winter and spring of 1944 forced the German High Command to keep its main and most combat-ready forces on the Soviet-German front, creating favourable conditions for opening the second front in Europe. The operation to open the second front, Operation Overlord or “Supreme Ruler” began on June the 6th, 1944, after being planned since 1942.
After landing in Normandy, the Anglo-American armies, enjoying significant superiority over the enemy and encountering little serious resistance, liberated almost all of northwestern France by August the 25th. By mid-September, they had also freed southern France. However, the liberation of northeastern France and Belgium took three months, from late August to late November 1944.
Despite their overall numerical and material superiority, the Allied advance in Western Europe was extremely hesitant. Moreover, Nazi Germany launched a counteroffensive in the Ardennes. As a result, the Allies suffered heavy losses and found themselves in a critical situation.
The Allied military-political leadership turned to the Soviet Union for assistance. Staying true to its allied commitments, the Soviet Supreme Command launched a massive offensive in Poland eight days ahead of schedule—on January the 12th, 1945, instead of the originally planned January the 20th.
Red Army forces broke through the Soviet-German front, forcing the Wehrmacht command to withdraw several strike formations from the Western European front and urgently redeploy them to the east. The crisis in the Ardennes for the Allies was resolved, creating favourable conditions for the Anglo-American troops to continue their advance into the depths of Germany.
In the Pacific theatre, Anglo-American armed forces, through a series of successive operations in 1944 and the first half of 1945, seized the Mariana, Caroline, and Philippine Islands, pushed the Japanese back in New Guinea and Indonesia, and weakened their positions in the region. The fight against Japanese forces in Burma had been waged since early 1944 by multinational forces, including British, Indian, and Chinese troops.  In the central and southern provinces of China, Japanese troops were opposed on land by the Chinese armed forces, while Anglo-American naval forces attacked them from the sea.
During the fifth period of World War II, military operations unfolded in the Pacific Ocean, Southeast Asia, and the Far East. American and British forces completely captured the Philippine Islands, Burma, and most of the islands of Indonesia.
On August the 6th and the 9th, 1945, U.S. Air Force long-range bombers dropped atomic bombs with a yield of 20 kilotons on the Japanese cities of Hiroshima and Nagasaki, killing approximately 450,000 civilians. This barbaric act of nuclear bombing was not dictated by military necessity. The ruling circles of the United States sought to reinforce their claims to a leading role in postwar global affairs and assert their ambitions for world dominance through these atomic strikes. Japan’s armed forces did not surrender as a result of the atomic bombings, which primarily targeted the civilian population, but rather due to the entry of the Soviet Union into the war, which led to the defeat of Japan’s most powerful strategic land force – the Kwantung Army.
The Soviet Union's participation in the war against Japan was determined by allied obligations, and the timing of its involvement was agreed upon at the Crimean Conference of Soviet, U.S., and British leaders in Yalta in February, 1945.
The Manchurian Operation was the first campaign of the Soviet Union in the war against Japan. It was remarkable for its unprecedented large-scale redeployment of troops from the western to the eastern regions of the USSR, the secrecy in forming strike groupings, the rapid deep offensive through mountainous, taiga, and desert terrain, the use of a tank army and cavalry-mechanized groups in the first echelon, and the deployment of airborne landings.
With the defeat of the Kwantung Army and the loss of Japan’s military-economic bases in China and Korea, Japan was left without the real strength or capability to continue the war.
The defeat of the Kwantung Army by Soviet troops was the decisive factor in Japan’s withdrawal from the war. Simultaneously, Soviet forces launched offensives against Japanese positions in South Sakhalin, the Kuril Islands, and North Korea. Seizing the momentum of the Soviet Armed Forces' successes, the Chinese People's Liberation Army also intensified its military actions against the Japanese.
On September the 2nd, 1945, aboard the American battleship USS Missouri, the Japanese government signed the Act of Unconditional Surrender, officially marking the end of World War II.
",
"listen_answer");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(215,25,null,null,1,"1"),
(216,25,null,null,1,"2"),
(217,25,null,null,1,"3"),
(218,25,null,null,1,"4"),
(219,25,null,null,1,"5"),
(220,25,null,null,1,"6"),
(221,25,null,null,1,"7");

INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(310,215,null, "3", True),
(311,216,null, "1", True),
(312,217,null, "3", True),
(313,218,null, "2", True),
(314,219,null, "2", True),
(315,220,null, "1", True),
(316,221,null, "2", True);

-- Reading
INSERT INTO task(id,section_id, hint, title, file_link, text, text_after_answer, type) VALUES
(26,15,
"Прочитайте текст и выполните задания 1–7. В каждом задании запишите в поле ответа цифру 1, 2, 3 или 4, соответствующую выбранному Вами варианту ответа",
"The Third Period of World War II (the Second Period of the Great Patriotic War)",
null,
"
The Soviet-German front remained the main and decisive front during the third period of World War II. Between 66% and 72% of the divisions of Nazi Germany and its European allies were concentrated there.
During the second period of the Great Patriotic War, the Soviet Armed Forces carried out two offensive campaigns: the winter campaign of 1942–1943 and the summer-autumn campaign of 1943. The most significant military and political events of this period were the Stalingrad Strategic Offensive Operation, the Battle of Kursk, and the liberation of Left-Bank Ukraine.
The Stalingrad Strategic Offensive Operation was the main event of the winter campaign of 1942–1943. The counteroffensive at Stalingrad, launched under conditions of relative parity between the opposing forces, ended with the complete encirclement and destruction of a 330,000-strong enemy force. The strategic initiative firmly passed into the hands of the Soviet command, and the Soviet Armed Forces started a strategic offensive from Livny to the Caucasus along a front spanning 1,200–2,000 km. The enemy withdrew from the Demyansk bridgehead, abandoned the Rzhev-Vyazma salient, and created the so-called Kursk salient (bulge), which shaped the strategic plans of both sides for the summer of 1943.
The defeat at Stalingrad shocked Nazi Germany, undermining its military and political prestige. Dissension arose within the Axis alliance: Japan and Turkey abandoned plans to declare war on the USSR, and Italy, after the destruction of its 8th Army on the Middle Don, decided to withdraw the remaining troops from the Soviet-German front.
Thus, the victory of Soviet forces at Stalingrad during the winter campaign of 1942–1943 marked a decisive turning point in the war, changing the strategic situation not only on the Soviet-German front but also on other World War II fronts.
The main events of the summer-autumn campaign of 1943 were the Battle of Kursk and the liberation of Left-Bank Ukraine.
During the Battle of Kursk, which consisted of one strategic defensive operation and two strategic offensive operations, the Soviet Armed Forces inflicted another crushing defeat on the enemy. In fierce defensive battles, which the Soviet command initiated deliberately, the enemy was first exhausted and then routed in a powerful counteroffensive. Hitler’s leadership failed in its attempt to regain the strategic initiative, stabilize the military situation, restore Germany’s international prestige, and prevent the collapse of the Axis alliance. The defeat at Kursk forced Nazi Germany to transition to a strategic defence along the entire Soviet-German front.
Following the Battle of Kursk, the Red Army started a successful strategic offensive along the entire front. Pursuing the enemy, Soviet forces reached the Dnieper River by August 1943 and, by the end of the summer-autumn campaign, liberated the Donbas and Left-Bank Ukraine, isolating the enemy’s Crimean grouping. On the right bank of the Dnieper River, Soviet troops captured 23 bridgeheads, including two strategic ones: north of Kyiv and in the Dnipropetrovsk region.
By the end of the second period of the Great Patriotic War, the decisive turning point in favour of the Soviet command had been completed. Nazi Germany faced the real prospect of inevitable defeat.
The Red Army inflicted heavy losses on the enemy, destroying 218 enemy divisions, about 6,700 tanks, over 50,000 artillery pieces, and 14,300 aircraft. The German forces were pushed 500–1,300 km westward, and up to 1 million km² of Soviet territory was liberated.
",
null,
"multiple_choice");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(222,26,"1. What was the primary significance of the Soviet victory at Stalingrad?",
"
a) It led to the immediate surrender of Nazi Germany.
b) It marked a decisive turning point in the war and shifted strategic initiative to the Soviet Union.
c) It resulted in the complete destruction of the German army on the Eastern Front.
d) It allowed Soviet forces to launch an invasion of Germany in 1943.
",1,null),

(223,26,"2. How did the Battle of Kursk influence Germany's war strategy?",
"
a) It forced Germany to transition to a strategic defensive position on the Eastern Front.
b) It enabled Germany to regain strategic initiative and continue offensive operations.
c) It led to a successful German counteroffensive that recaptured Stalingrad.
d) It allowed Germany to shift significant forces to the Western Front.
",1,null),

(224,26,"3. Which of the following was a direct consequence of the Soviet counteroffensive at Stalingrad?",
"
a) The immediate opening of a second front in Europe by the Western Allies.
b) The destruction of the entire German Eastern Front.
c) The encirclement and destruction of a 330,000-strong German force.
d) The withdrawal of German forces from all occupied Soviet territories.
",1,null),

(225,26,"4. What role did the capture of bridgeheads on the Dnieper River play in Soviet strategy?",
"
a) It facilitated further Soviet advances into Western Europe.
b) It allowed Soviet forces to encircle and capture Berlin immediately.
c) It provided key strategic positions for future offensives and secured the liberation of Ukraine.
d) It led to the surrender of Germany’s remaining forces in Eastern Europe.
",1,null),

(226,26,"5. Which of the following was NOT a key factor in the Soviet victory during the second period of the Great Patriotic War?",
"
a) The strategic offensives at Stalingrad and Kursk.
b) The withdrawal of Italian forces from the Eastern Front.
c) The successful landing of Allied troops in France in 1943.
d) The liberation of Left-Bank Ukraine and the Donbas region.
",1,null),

(227,26,"6. What impact did the Soviet victories have on Germany’s political and military alliances?",
"
a) They led to the immediate dissolution of the Axis alliance.
b) They caused divisions within the Axis, with countries like Italy reconsidering their support.
c) They strengthened Germany’s alliances, leading to increased military aid from Japan and Turkey.
d) They forced Germany to negotiate a separate peace agreement with the Soviet Union.
",1,null),

(228,26,"7. Why was the creation of the Kursk bulge significant in 1943?",
"
a) It allowed Germany to plan a large-scale offensive to encircle Soviet forces.
b) It became a key location for Soviet defensive and counteroffensive operations
c) It provided a pathway for Germany to retreat toward Poland.
d) It was used by the Allies to land troops behind enemy lines.
",1,null);

-- ответов не было !!!!
INSERT INTO answer_option(id, item_id,left_text, text, is_correct) VALUES
(317,222,null, "b", TRUE),
(318,223,null, "a", TRUE),
(319,224,null, "c", TRUE),
(320,225,null, "c", TRUE),
(321,226,null, "c", TRUE),
(322,227,null, "b", TRUE),
(323,228,null, "b", TRUE);

-- Test yourself
INSERT INTO task(id,section_id, hint, title, file_link, text, text_after_answer, type) VALUES
(27,16,
null,
"The Main Events of the Second World War",
null,
null,
null,
"multiple_choice");

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(229,27,"1. The German Plan for War Against the USSR",
"a) was called \"Barbarossa\" and was approved by Hitler on December 19, 1940, in Directive No. 21
b) was called \"Barbarossa\" and was approved by Hitler on May 19, 1941, in Directive No. 21
c) was called \"Drang nach Osten\" (\"Drive to the East\") and was approved by Hitler on January 19, 1940, in Directive No. 21
d) was called \"Drang nach Osten\" (\"Drive to the East\") and was approved by Hitler on December 19, 1939, in Directive No. 21
",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(324,229,null, "a", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(230,27,"2. The German War Plan Against the USSR Provided For:",
"a) three strikes—on Leningrad, on Moscow (main), and on Odesa
b) three strikes—on Leningrad, on Moscow (main), and on Kyiv
c) three strikes—on Leningrad (main), on Moscow, and on Kyiv
d) three strikes—on Warsaw, on Moscow, and on Kyiv (main)
",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(325,230,null, "b", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(231,27,"3. According to the German War Plan Against the USSR, Military Actions Were Expected to Be Completed Within:",
"a) two to six months
b) one to two months
c) six to twelve months
d) two to six weeks
",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(326,231,null, "a", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(232,27,"4. The Main Outcome of the Summer-Autumn Defensive Campaign of 1941 Was:",
"a) the Soviet command seizing strategic initiative in the war
b) the failure of Hitler's \"Blitzkrieg\" plan
c) the turning point in the Great Patriotic War
d) the debunking of the myth of the invincibility of the German army
",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(327,232,null, "b", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(233,27,"5. The Main Outcome of the Winter Offensive Campaign of 1941–1942 (December 5 – April 20) Was:",
"a) the turning point in the Great Patriotic War
b) the Soviet command seizing strategic initiative in the war
c) the complete failure of Hitler's \"Blitzkrieg\" plan and the transition to a prolonged war
d) the debunking of the myth of the invincibility of the German army
",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(328,233,null, "c", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(234,27,"6. The Main Outcome of the Summer-Autumn Campaign of 1942 (April 21 – November 18) Was:",
"a) the disruption of the Nazi command’s plans to seize oil regions in the Caspian and to break through into the Caucasus
b) the failure of Hitler's \"Blitzkrieg\" plan
c) the turning point in the Great Patriotic War
d) the temporary loss of strategic initiative by the Soviet command
",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(329,234,null, "d", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(235,27,"7. The Main Outcome of the First Period of the Great Patriotic War (June 22, 1941 – November 18, 1942) Was:",
"a) the creation of conditions for a turning point in the Great Patriotic War and the entire Second World War
b) the Soviet command seizing strategic initiative in the war
c) the liberation of Left-Bank Ukraine
d) the lifting of the blockade of Leningrad
",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(330,235,null, "a", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(236,27,"8. During the Third Period of World War II, the Second Period of the Great Patriotic War, the Main Theater of Military Operations Was:",
"a) the continental territory of Western Europe
b) the Soviet-German Eastern European Front
c) North Africa
d) the Pacific Ocean basin
e) the Atlantic Ocean basin
",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(331,236,null, "b", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(237,27,"9. The Major Military-Political Events of the Second Period of the Great Patriotic War (November 19, 1942 – December 31, 1943) Were:",
"a) the Stalingrad strategic offensive operation, the Battle of Kursk, and the liberation of Left-Bank Ukraine
b) the Battle of Stalingrad and the Battle of Kursk
c) the Battle of Stalingrad, the Battle of Kursk, and the liberation of Left-Bank Ukraine
d) the Moscow strategic offensive operation, the Stalingrad strategic offensive operation, the Battle of Kursk, and the liberation of Left-Bank Ukraine
",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(332,237,null, "c", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(238,27,"10. The Chronological Boundaries of the Stalingrad Strategic Offensive Operation Were:",
"a) July 17 – November 18, 1942
b) November 19, 1942 – February 2, 1943
c) April 21 – November 18, 1942
d) July 5 – August 23, 1943
",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(333,238,null, "b", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(239,27,"11. The Main Outcome of the Winter Campaign of 1942–1943 (November 19, 1942 – May 1943) Was:",
"a) the opening of the second front by the Allies in Western Europe
b) the change in the strategic situation throughout World War II
c) the transfer of military actions to the territory of Crimea and the Luhansk People's Republic
d) the beginning of the turning point in the Great Patriotic War
",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(334,239,null, "d", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(240,27,"12. During the Second Period of the Great Patriotic War (November 19, 1942 – December 31, 1943):",
"a) Red Army troops liberated most of the USSR and reached the national border
b) a decisive turning point occurred in the entire Great Patriotic War
c) the blockade of Leningrad was lifted, and Crimea was liberated
d) the second front was opened by the Allies in Western Europe
",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(335,240,null, "b", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(241,27,"13. As a Result of the Successful Strategic Offensive of the Red Army After the Battle of Kursk:",
"a) the German-Fascist troops under the command of Field Marshal Paulus were surrounded and destroyed
b) the Donbas and Left-Bank Ukraine were liberated
c) the blockade of Leningrad was broken and fully lifted
d) the Crimean enemy grouping was isolated
",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(336,241,null, "b", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(242,27,"14. The Main Content of the Winter Campaign of 1944 (January – May) in the Fourth Period of World War II Was:",
"a) the defeat of Wehrmacht army groups near Leningrad and Novgorod, in the Caucasus, and in Crimea
b) the defeat of Wehrmacht army groups near Leningrad and Novgorod, in Right-Bank Ukraine, and in Crimea
c) the defeat of Wehrmacht army groups near Leningrad and Stalingrad, in Ukraine, and in Crimea
d) the defeat of Wehrmacht army groups near Leningrad and Novgorod, near Kursk, and in Left-Bank Ukraine
",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(337,242,null, "b", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(243,27,"15. In the Summer-Autumn Campaign of 1944 (June – December), Red Army Troops:",
"a) liberated significant parts of Bulgaria, Hungary, Poland, Romania, Czechoslovakia, Finland, Sweden, and Yugoslavia from Nazi occupation
b) completely freed the entire territory of the USSR from the occupiers (except for some areas of East Prussia)
c) assisted the Allied troops by landing an expeditionary corps in Normandy (\"Normandie-Niemen\" corps)
d) liberated significant parts of Bulgaria, Hungary, Poland, Romania, Czechoslovakia, and Yugoslavia from Nazi occupation
",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(338,243,null, "b", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(244,27,"16. The Final Act of the Surrender of Nazi Germany's Armed Forces Was Signed:",
"a) on the night of May 7 in Reims (France)
b) on the night of May 9 at 00:50 Moscow time in a railway carriage in the Compiegne Forest (France)
c) on the night of May 9 at 00:50 Moscow time in Karlshorst (Germany)
d) on the night of May 9 on the American battleship \"Missouri\"
",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(339,244,null, "a", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(245,27,"17. Why Was the Operation to Open the Second Front in Western Europe, Planned Since 1942, Only Launched in 1944?",
"a) The Allies needed to secure their rear by winning on other fronts, primarily gaining naval and air superiority
b) Opening the second front meant directly confronting the main forces of the Wehrmacht, requiring extensive preparation
c) Further delay in opening the second front would have resulted in the Soviet troops liberating all of Europe
d) Disagreements between U.S. and British military command regarding European strategy delayed the operation
",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(340,245,null, "c", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(246,27,"18. The Reason for the Atomic Bombing of Hiroshima and Nagasaki on August 6 and 9 by U.S. Aviation Was:",
"a) military necessity and the desire to avoid American casualties
b) a demonstration of U.S. power to assert dominance in post-war politics
c) the need to test the effectiveness of nuclear weapons in combat
d) an error by American pilots; the actual target was Japanese military forces
",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(341,246,null, "b", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(247,27,"19. The decisive contribution to Japan's withdrawal from the war was:",
"a) A U.S. military amphibious operation to capture the islands of the Japanese archipelago
b) The position of Japanese Emperor Hirohito, who was categorically against Japan continuing the war
c) The atomic bombing of the Japanese cities of Hiroshima and Nagasaki on August 6 and 9
d) The offensive operation of the Soviet Armed Forces to defeat the Kwantung Army in Manchuria
",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(342,247,null, "d", TRUE);

INSERT INTO item(id, task_id, title, text, points, number) VALUES
(248,27,"20. World War II ended after the Japanese government signed the act of unconditional surrender. The act was signed:",
"a) on August 14, 1945, on the American battleship \"Missouri\"
b) on September 2, 1945, on the American battleship \"Missouri\"
c) on September 1, 1945, on the U.S. battleship in Tokyo Bay
d) on September 2, 1945, at the government palace in Tokyo\"
",1,null);

INSERT INTO answer_option(id, item_id, left_text, text, is_correct) VALUES
(343,248,null, "b", TRUE);

