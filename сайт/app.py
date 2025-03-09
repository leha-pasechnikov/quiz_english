from flask import Flask, render_template, request, redirect, url_for, flash, session, jsonify, abort, make_response
from datetime import datetime, timedelta, date
import mysql.connector
from mysql.connector import IntegrityError
from flask import send_from_directory
from itsdangerous import URLSafeTimedSerializer
import os
from werkzeug.utils import secure_filename
from werkzeug.exceptions import RequestEntityTooLarge
import threading
import requests
import hashlib
from functools import wraps

from config import *
from почта.pochta import send_mail

app = Flask(__name__)

UPLOAD_FOLDER = 'static/audio'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

MAX_CONTENT_LENGTH = 10 * 1024 * 1024  # Максимальный размер файла 10 МБ

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = MAX_CONTENT_LENGTH
app.config['SESSION_COOKIE_SECURE'] = True  # Только HTTPS
app.config['SESSION_COOKIE_HTTPONLY'] = True  # Запрещаем доступ через JavaScript

app.config['JSON_AS_ASCII'] = False
app.config['SECRET_KEY'] = SECRET_KEY  # Установите секретный ключ для сессий
serializer = URLSafeTimedSerializer(app.config['SECRET_KEY'])
app.permanent_session_lifetime = timedelta(days=10)  # Установите время жизни сессии на 10 дней

app.config['PREFERRED_URL_SCHEME'] = 'https'  # Принудительное использование HTTPS
app.config[
    'SESSION_COOKIE_SAMESITE'] = 'Lax'  # Предотвращает CSRF при переходе с другого сайта (можно 'Strict' или 'None')
app.config['SESSION_REFRESH_EACH_REQUEST'] = False  # Не обновляет срок действия куки при каждом запросе

from functools import wraps


def is_admin(message='Администратор не может входить на эту страницу'):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            if 'is_admin' in session and session['is_admin']:
                return message
            result = func(*args, **kwargs)
            return result

        return wrapper

    return decorator


def is_id(message=''):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            if 'id' not in session:
                if message:
                    return message
                return redirect(url_for('login'))
            return func(*args, **kwargs)

        return wrapper

    return decorator


# Функция для отправки сообщения в Telegram админу
def send_telegram_notification(message):
    try:
        url = f"https://api.telegram.org/bot{TOKEN_TELEGRAMM}/sendMessage"
        data = {
            'chat_id': ADMIN_ID_TELEGRAMM,
            'text': message,
        }
        requests.post(url, data=data)
    except:
        pass


# Обертка для асинхронного вызова send_telegram_notification
def send_notification_async(message):
    try:
        thread = threading.Thread(target=send_telegram_notification, args=(message,))
        thread.start()
    except:
        pass


@app.after_request
def add_security_headers(response):
    response.headers['X-Frame-Options'] = 'DENY'  # Защита от Clickjacking
    response.headers['Content-Security-Policy'] = "frame-ancestors 'none';"  # Современная версия
    response.headers['X-Content-Type-Options'] = 'nosniff'  # Блокирует MIME-атаки
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'  # Безопасная передача заголовка Referer
    response.headers['Permissions-Policy'] = "geolocation=(), microphone=()"  # Отключает доступ к сенсорам
    return response


@app.errorhandler(403)
def forbidden_error(error):
    return render_template('403.html'), 403


# Роут для раздачи файлов
@app.route('/static/<path:filename>')
def serve_static(filename):
    return send_from_directory(app.static_folder, filename)


def connect_to_db():
    return mysql.connector.connect(
        host=MYSQL_HOST,  # Замените на ваш хост
        user=MYSQL_USER,  # Замените на ваше имя пользователя
        password=MYSQL_PASSWORD,  # Замените на ваш пароль
        database=MYSQL_DATABASE  # Название базы данных
    )


@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))


@app.route('/', methods=['GET'])
def index():
    try:
        conn = connect_to_db()
        cursor = conn.cursor(dictionary=True)

        # Получаем все темы с разделами через JOIN
        cursor.execute('''
            SELECT t.id AS topic_id, t.title AS topic_title, s.id AS section_id, s.title AS section_title
            FROM topic t
            LEFT JOIN section s ON t.id = s.topic_id
            ORDER BY t.id, s.id
        ''')

        rows = cursor.fetchall()

        # Структурируем данные: темы с разделами
        topics = []
        current_topic = None

        for row in rows:
            if current_topic is None or current_topic['id'] != row['topic_id']:
                current_topic = {
                    'id': row['topic_id'],
                    'title': row['topic_title'],
                    'sections': []
                }
                topics.append(current_topic)

            if row['section_id'] is not None:
                current_topic['sections'].append({
                    'id': row['section_id'],
                    'title': row['section_title']
                })

        print(topics)  # Для отладки
        return render_template('index.html', topics=topics)

    except Exception as e:
        return jsonify({'status': 'error', 'message': f'произошла ошибка {str(e)}'}), 500

    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.route('/leaderboard', methods=['GET'])
def leaderboard():
    try:
        conn = connect_to_db()
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
SELECT
    u.username AS username,
    COALESCE(SUM(i.points), 0) AS score,
    u.time_score AS time_score
FROM
    user u
LEFT JOIN
    answer_option_result aor ON aor.user_id = u.id
LEFT JOIN
    answer_option ao ON ao.id = aor.answer_option_id
LEFT JOIN
    item i ON i.id = ao.item_id AND ao.is_correct = TRUE AND aor.text = ao.text
GROUP BY
    u.id
ORDER BY
    score DESC, time_score ASC;
''')
        leaderboard = cursor.fetchall()

        return render_template('leaderboard.html', leaderboard=leaderboard)

    except Exception as e:
        return jsonify({'status': 'error', 'message': f'произошла ошибка {str(e)}'}), 500

    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        try:
            conn = connect_to_db()
            cursor = conn.cursor(dictionary=True)

            username = request.form['username']
            password = request.form['password']
            password = hashlib.sha256(password.encode('utf-8')).hexdigest()

            cursor.execute('SELECT * FROM user WHERE username = %s AND password = %s', (username, password))
            user = cursor.fetchone()
            cursor.execute('SELECT * FROM admin WHERE username = %s AND password = %s', (username, password))
            admin = cursor.fetchone()
            if admin:
                session['id'] = admin['id']  # Установить сессию пользователя
                session['is_admin'] = True
                return redirect(url_for('admin'))
            if user:
                session['id'] = user['id']  # Установить сессию пользователя
                session['is_admin'] = False
                return redirect(url_for('index'))  # Перенаправление на главную страницу

            return jsonify({'status': 'error', 'message': 'неверный логин или пароль'}), 401

        except Exception as e:
            return jsonify({'status': 'error', 'message': f'произошла ошибка {str(e)}'}), 500

        finally:
            if 'cursor' in locals() and cursor:
                cursor.close()
            if 'conn' in locals() and conn:
                conn.close()
    elif request.method == 'GET':
        return render_template('login.html')


@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        try:
            conn = connect_to_db()
            cursor = conn.cursor(dictionary=True)
            last_name = request.form['last_name']
            first_name = request.form['first_name']
            middle_name = request.form['middle_name']
            email = request.form['email']
            username = request.form['username']
            password = request.form['password']

            cursor.execute('''
            INSERT INTO user(last_name,first_name, middle_name, email,username,password,note)
            VALUES (%s,%s,%s,%s,%s,%s,%s);
             ''', (last_name, first_name, middle_name, email, username, password, ""))

            user_id = cursor.lastrowid
            conn.commit()

            return jsonify({'status': 'success', 'message': 'Участник зарегистрирован', "last_id": user_id}), 200

        except Exception as e:
            return jsonify({'status': 'error', 'message': f'произошла ошибка {str(e)}'}), 500

        finally:
            if 'cursor' in locals() and cursor:
                cursor.close()
            if 'conn' in locals() and conn:
                conn.close()
    elif request.method == 'GET':
        return render_template('login.html')


@app.route('/personal', methods=['GET'])
@is_id()
def personal():
    try:
        conn = connect_to_db()
        cursor = conn.cursor(dictionary=True)

        cursor.execute('''
        SELECT last_name,first_name, middle_name, email,username,note FROM user
        WHERE id=%s;
         ''', (session['id'],))
        user_information = cursor.fetchall()
        cursor.execute('''
SELECT
    COALESCE(SUM(i.points), 0) AS score,
    u.time_score AS time_score
FROM
    user u
LEFT JOIN
    answer_option_result aor ON aor.user_id = u.id
LEFT JOIN
    answer_option ao ON ao.id = aor.answer_option_id
LEFT JOIN
    item i ON i.id = ao.item_id AND ao.is_correct = TRUE AND aor.text = ao.text
WHERE
    u.id = %s  
GROUP BY
    u.id
ORDER BY
    score DESC, time_score ASC;
''', (session['id'],))
        score = cursor.fetchone()

        cursor.execute('''
        SELECT * FROM words
        WHERE user_id=%s;
         ''', (session['id'],))
        words_information = cursor.fetchall()

        return render_template('personal.html', user=user_information, words=words_information, score=score)

    except Exception as e:
        return jsonify({'status': 'error', 'message': f'произошла ошибка {str(e)}'}), 500

    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.route('/personal/note', methods=['PUT', 'DELETE'])
@is_id()
def edit_note():
    try:
        conn = connect_to_db()
        cursor = conn.cursor(dictionary=True)

        if request.method == 'DELETE':
            cursor.execute('''UPDATE user SET note="" where id=%s''', (session['id'],))
            conn.commit()
            return jsonify({'status': 'success', 'message': 'блокнот очищен'}), 200

        data = request.json
        new_note = data.get('note')

        if request.method == 'PUT':
            cursor.execute('''UPDATE user SET note=%s where id=%s''', (new_note, session['id']))
            conn.commit()
            return jsonify({'status': 'success', 'message': 'блокнот изменён'}), 200

    except Exception as e:
        return jsonify({'status': 'error', 'message': f'произошла ошибка {str(e)}'}), 500

    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.route('/personal/word/<int:id_word>', methods=['POST', 'PUT', 'DELETE'])
@is_id()
def edit_word(id_word):
    if id_word < 0 or (id_word == 0 and request.method != 'POST'):
        return jsonify({'status': 'error', 'message': 'некорректный id'}), 400
    try:
        conn = connect_to_db()
        cursor = conn.cursor(dictionary=True)

        cursor.execute('SELECT * FROM words where id=%s', (id_word,))
        word = cursor.fetchone()
        if word is None:
            return jsonify({'status': 'error', 'message': 'слово не найдено'}), 404
        if 'user_id' in word:
            if word['user_id'] != session['id']:
                return jsonify({'status': 'error', 'message': 'попытка изменить чужие данные'}), 403
        else:
            return jsonify({'status': 'error', 'message': 'не найден создатель слова'}), 404

        if request.method == 'DELETE':
            cursor.execute('DELETE FROM words where id=%s', (id_word,))
            conn.commit()
            return jsonify({'status': 'success', 'message': 'слово удалено'}), 200

        data = request.json
        new_word = data.get('word')
        new_transcription = data.get('transcription')

        if request.method == 'PUT':
            cursor.execute('''UPDATE words SET word= %s, transcription= %s where id= %s''',
                           (new_word, new_transcription, id_word))
            conn.commit()
            return jsonify({'status': 'success', 'message': 'слово обновлено'}), 200

        if request.method == 'POST':
            if id_word != 0:
                cursor.execute('INSERT INTO words(id,user_id,word,transcription) VALUES  (%s, %s, %s, %s)',
                               (id_word, new_word, new_transcription, id_word))
            else:
                cursor.execute('INSERT INTO words(user_id,word,transcription) VALUES  (%s, %s, %s)',
                               (new_word, new_transcription, id_word))
            last_id = cursor.lastrowid
            conn.commit()
            return jsonify({'status': 'success', 'message': 'слово добавлено', 'last_id': last_id}), 200

    except Exception as e:
        return jsonify({'status': 'error', 'message': f'произошла ошибка {str(e)}'}), 500

    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.route('/section/<int:id_section>/result', methods=['GET'])
@is_id()
def section_result(id_section):
    try:
        with connect_to_db() as conn:
            with conn.cursor(dictionary=True) as cursor:
                cursor.execute('''
                SELECT 
                    section.id AS section_id,
                    section.title AS section_title,
                    task.id AS task_id,
                    task.section_id,
                    task.hint,
                    task.title AS task_title,
                    task.text AS task_text,
                    task.text_after_answer,
                    task.file_link,
                    task.type,
                    item.id AS item_id,
                    item.task_id AS item_task_id,
                    item.title AS item_title,
                    item.number,
                    item.text AS item_text,
                    item.points,
                    answer_option.id AS answer_option_id,
                    answer_option.item_id AS answer_option_item_id,
                    answer_option.left_text,
                    answer_option.text AS answer_option_text,
                    answer_option.is_correct as is_correct,
                    answer_option_result.id as answer_option_result_id,
                    answer_option_result.answer_option_id as answer_option_result_answer_option_id,
                    answer_option_result.text as answer_option_result_text
                FROM 
                    task
                JOIN 
                    item ON task.id = item.task_id
                JOIN 
                    answer_option ON item.id = answer_option.item_id
                JOIN 
                    section ON task.section_id = section.id
                LEFT JOIN 
                    answer_option_result ON answer_option_result.answer_option_id = answer_option.id
                WHERE section.id = %s and answer_option_result.user_id = %s;
                ''', (id_section, session['id']))

                rows = cursor.fetchall()
                print('2iuol=', rows)

                if not rows:
                    return 'Ваше решение для этого задания не найдено'

                # Структурируем данные в нужный формат
                section_data = {"section": {"id": rows[0]["section_id"], "title": rows[0]["section_title"], "task": []}}
                task_map = {}

                for row in rows:
                    task_id = row["task_id"]
                    if task_id not in task_map:
                        task_map[task_id] = {
                            "id": task_id,
                            "section_id": row["section_id"],
                            "hint": row["hint"],
                            "title": row["task_title"],
                            "text": row["task_text"],
                            "text_after_answer": row["text_after_answer"],
                            "file_link": row["file_link"],
                            "type": row["type"],
                            "item": {}
                        }
                        section_data["section"]["task"].append(task_map[task_id])

                    item_id = row["item_id"]
                    if item_id not in task_map[task_id]["item"]:
                        task_map[task_id]["item"][item_id] = {
                            "id": item_id,
                            "task_id": row["item_task_id"],
                            "title": row["item_title"],
                            "number": row["number"],
                            "text": row["item_text"],
                            "points": row["points"],
                            "answer_option": []
                        }

                    answer_option = {
                        "id": row["answer_option_id"],
                        "item_id": row["answer_option_item_id"],
                        "left_text": row["left_text"],
                        "text": row["answer_option_text"],
                        "is_correct": row["is_correct"],
                        "result": {
                            "id": row["answer_option_result_id"],
                            "answer_option_id": row["answer_option_result_answer_option_id"],
                            "text": row["answer_option_result_text"]
                        }
                    }

                    task_map[task_id]["item"][item_id]["answer_option"].append(answer_option)

                # Преобразуем словарь items в список внутри каждой задачи
                for task in section_data["section"]["task"]:
                    task["item"] = list(task["item"].values())
                print(section_data)
                return render_template('section_result.html', section=section_data)

    except Exception as e:
        return jsonify({'status': 'error', 'message': f'Произошла ошибка: {str(e)}'}), 500


@app.route('/section/<int:id_section>', methods=['GET', 'POST'])
@is_id()
def section(id_section):
    try:
        conn = connect_to_db()
        cursor = conn.cursor(dictionary=True)

        if request.method == 'POST':
            answers = request.form
            print(answers)
            for i in answers:
                answer_option_result = i.replace('answer_', '')
                print(answer_option_result)
                if '_1' in str(answer_option_result):
                    cursor.execute('SELECT id FROM answer_option WHERE item_id = %s;',
                                   (answer_option_result.replace('_1', ''),))
                    answer_option_results = cursor.fetchall()
                    print(answer_option_result)
                    for option in answer_option_results:
                        answer_option_result = option['id']  # Используем id каждого варианта ответа

                        print(answer_option_result)
                        print(answers[i])

                        # Вставляем каждый вариант ответа в таблицу
                        cursor.execute(
                            'INSERT INTO answer_option_result (answer_option_id, user_id, text) VALUES (%s, %s, %s);',
                            (answer_option_result, session['id'], answers[i])
                        )
                else:
                    print(answer_option_result)
                    print(answers[i])
                    cursor.execute(
                        'INSERT INTO answer_option_result (answer_option_id, user_id, text) VALUES (%s, %s, %s);',
                        (answer_option_result, session['id'], answers[i]))
            conn.commit()
            print('переход')
            return redirect(url_for('section_result', id_section=id_section))


        cursor.execute('''
        SELECT 
            section.id AS section_id,
            section.title AS section_title,

            task.id AS task_id,
            task.section_id,
            task.hint,
            task.title AS task_title,
            task.text AS task_text,
            task.text_after_answer,
            task.file_link,
            task.type,

            item.id AS item_id,
            item.task_id AS item_task_id,
            item.title AS item_title,
            item.number,
            item.text AS item_text,
            item.points,

            answer_option.id AS answer_option_id,
            answer_option.item_id AS answer_option_item_id,
            answer_option.left_text,
            answer_option.text AS answer_option_text,
            
            answer_option_result.user_id as is_otvet
            
            
        FROM 
            task
        JOIN 
            item ON task.id = item.task_id
        JOIN 
            answer_option ON item.id = answer_option.item_id
        JOIN 
            section ON task.section_id = section.id
        LEFT JOIN 
            answer_option_result ON answer_option_result.answer_option_id = answer_option.id
            
        WHERE section.id = %s
        ''', (id_section,))

        rows = cursor.fetchall()
        print(rows)


        if not rows:
            return jsonify({'status': 'error', 'message': 'задания не найдены'}), 404

        # Структурируем данные в нужный формат
        section_data = {"section": {"id": rows[0]["section_id"], "title": rows[0]["section_title"], "task": []}}
        task_map = {}

        for row in rows:
            if row['is_otvet'] == session['id']:
                return redirect(url_for('section_result', id_section=id_section))
            task_id = row["task_id"]
            if task_id not in task_map:
                task_map[task_id] = {
                    "id": task_id,
                    "section_id": row["section_id"],
                    "hint": row["hint"],
                    "title": row["task_title"],
                    "text": row["task_text"],
                    "text_after_answer": row["text_after_answer"],
                    "file_link": row["file_link"],
                    "type": row["type"],
                    "item": {}
                }
                section_data["section"]["task"].append(task_map[task_id])

            item_id = row["item_id"]
            if item_id not in task_map[task_id]["item"]:
                task_map[task_id]["item"][item_id] = {
                    "id": item_id,
                    "task_id": row["item_task_id"],
                    "title": row["item_title"],
                    "number": row["number"],
                    "text": row["item_text"],
                    "points": row["points"],
                    "answer_option": []
                }

            answer_option = {
                "id": row["answer_option_id"],
                "item_id": row["answer_option_item_id"],
                "left_text": row["left_text"],
                "text": row["answer_option_text"]
            }

            task_map[task_id]["item"][item_id]["answer_option"].append(answer_option)

        # Преобразуем словарь items в список внутри каждой задачи
        for task in section_data["section"]["task"]:
            task["item"] = list(task["item"].values())
        print(section_data)
        return render_template('section.html', section=section_data)

    except Exception as e:
        return jsonify({'status': 'error', 'message': f'произошла ошибка {str(e)}'}), 500

    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.route('/reset_password', methods=['GET', 'POST'])
def reset_password():
    print('reset_password')

    if request.method == 'POST':
        try:
            conn = connect_to_db()
            cursor = conn.cursor()

            data = request.get_json()
            login = data.get('login')
            print(data, login)
            cursor.execute('select pochta from users where login = %s', (login,))

            result = cursor.fetchall()
            if result:
                email = result[0]
            else:
                return jsonify({'message': 'Пользователь %s не найден' % login})

            print('token')
            # Генерация токена
            token = serializer.dumps(email, salt=PASSWORD_SALT)
            reset_url = url_for('reset_password_token', token=token, _external=True)
            print(str(reset_url), email)
            if send_mail(str(reset_url), email) == False:
                return jsonify({'message': f'Ошибка отправки письма на почту', 'status': 'error'})

            print('отправка завершена')

            return jsonify({'message': f'Инструкции по восстановлению пароля были отправлены на {email[0]}'})

        except Exception as e:
            flash('Произошла ошибка: ' + str(e), 'error')
            return redirect(url_for('reset_password'))
        finally:
            if cursor:
                cursor.close()
            if conn:
                conn.close()
    return render_template('forget_password.html')


# Маршрут для проверки токена и сброса пароля
@app.route('/reset_password/<token>', methods=['GET', 'POST'])
def reset_password_token(token):
    print('reset_password_token')
    try:
        email = serializer.loads(token, salt=PASSWORD_SALT, max_age=600)[0]  # Токен действует 10 минут
    except:
        flash('Срок действия токена истёк', 'danger')
        return redirect(url_for('reset_password'))
    print(email)
    if request.method == 'POST':
        try:
            conn = connect_to_db()
            cursor = conn.cursor()

            data = request.get_json()  # Получить JSON-данные
            new_password = data.get('password')
            if not new_password:
                return jsonify({'message': 'Пароль отсутствует'}), 400
            print(new_password, email)
            # Здесь должна быть логика изменения пароля в базе данных
            cursor.execute('update users set password = %s where pochta = %s', (new_password, email,))
            conn.commit()

            return jsonify({'message': 'Пароль успешно изменён'}), 200
        except Exception as e:
            return redirect(url_for('reset_password'))
        finally:
            if cursor:
                cursor.close()
            if conn:
                conn.close()
    return render_template('new_password.html', token=token)


@app.route('/admin', methods=['GET', 'POST'])
def admin():
    print(session)
    if 'is_admin' in session:
        if session['is_admin'] == True:
            tables = []
            if request.method == 'GET':
                try:
                    conn = connect_to_db()
                    cursor = conn.cursor(dictionary=True)

                    cursor.execute(f'USE {MYSQL_DATABASE};')
                    cursor.execute('SHOW TABLES;')
                    tables = cursor.fetchall()
                    print('tables=', tables)

                except Exception as e:
                    flash('Произошла ошибка: ' + str(e), 'error')

                    return redirect(url_for('index'))
                finally:
                    if cursor:
                        cursor.close()
                    if conn:
                        conn.close()
            print(session['is_admin'])
            return render_template('admin.html', tables=tables)
    return abort(403)


@app.route('/admin/record/<string:table>', methods=['GET', 'POST'])
def table(table):
    if 'is_admin' in session:
        if session['is_admin'] == True:
            print(f'вызов {table}')
            try:
                conn = connect_to_db()
                cursor = conn.cursor(dictionary=True)

                # Получаем заголовки таблицы
                cursor.execute('''SELECT COLUMN_NAME AS Field
                                  FROM INFORMATION_SCHEMA.COLUMNS
                                  WHERE TABLE_NAME = %s AND TABLE_SCHEMA = %s;''', (table, MYSQL_DATABASE))
                table_head = [i['Field'] for i in cursor.fetchall()]


                print(table_head)

                if request.method == 'POST':
                    data = request.get_json()  # Получаем JSON данные
                    print('data= ', data)

                    for i in data:
                        if data[i] == '':
                            data[i] = None

                    if int(data['id']) <= 0:
                        return jsonify({'error': 'id должен быть больше 0'}), 400
                    if not data:
                        return jsonify({'error': 'Данные не предоставлены'}), 400

                    try:
                        cursor.execute(
                            f"INSERT INTO {table} ({','.join(table_head)}) VALUES ({','.join(['%s'] * len(table_head))})",
                            tuple(data.get(field, None) for field in table_head)
                        )
                        conn.commit()
                        new_record_id = cursor.lastrowid  # Получаем ID новой записи
                        return jsonify({'message': 'Данные успешно добавлены!', 'id': new_record_id}), 201
                    except Exception as e:
                        print('Ошибка при добавлении записи:', e)
                        return jsonify({'error': str(e)}), 500

                # Получаем данные таблицы
                cursor.execute(f'SELECT * FROM {table}')
                table_value = cursor.fetchall()
                print(table_value)
                for mas in table_value:
                    for i in mas:
                        if isinstance(mas[i], datetime):
                            mas[i] = mas[i].strftime('%Y-%m-%d %H:%M:%S')
                        elif isinstance(mas[i], date):
                            mas[i] = mas[i].strftime('%Y-%m-%d')
                        elif mas[i] is None:
                            mas[i] = ''

                return jsonify({
                    'table_head': table_head,
                    'table_value': table_value
                })

            except Exception as e:
                print('Ошибка:', e)
                flash('Произошла ошибка: ' + str(e), 'error')
                return jsonify({'error': str(e)}), 500
            finally:
                if cursor:
                    cursor.close()
                if conn:
                    conn.close()
    return abort(403)


@app.route('/admin/record/<string:table>/<int:id>', methods=['PUT', 'DELETE'])
def record_edit(table, id):
    if 'is_admin' in session:
        if session['is_admin'] == True:
            print(f'вызов {table}, {id}')
            try:
                conn = connect_to_db()
                cursor = conn.cursor(dictionary=True)

                if request.method == 'PUT':
                    data = request.get_json()
                    for i in data:
                        if data[i] == '':
                            data[i] = None

                    # Проверка на конфликт ID
                    if 'id' in data:
                        new_id = data['id']
                        cursor.execute(f'SELECT COUNT(*) AS count FROM {table} WHERE id = %s', (new_id,))
                        if cursor.fetchone()['count'] > 0 and new_id != id:
                            return jsonify({'error': 'ID уже существует в таблице.'}), 400

                    # Обновление данных
                    set_clause = ', '.join([f"{key} = %s" for key in data.keys()])
                    values = list(data.values()) + [id]
                    cursor.execute(f'UPDATE {table} SET {set_clause} WHERE id = %s', values)
                    conn.commit()
                    return jsonify({'message': 'Данные успешно обновлены!'}), 200


                elif request.method == 'DELETE':
                    print(f'DELETE FROM {table} WHERE id = %s' % id)
                    cursor.execute(f'DELETE FROM {table} WHERE id = %s', (id,))
                    conn.commit()
                    flash('Данные успешно удалены!', 'success')
                    return jsonify({'message': 'Данные успешно удалены!'}), 204

            except Exception as e:
                print('Ошибка:', e)
                flash('Произошла ошибка: ' + str(e), 'error')
                return jsonify({'error': str(e)}), 500
            finally:
                if cursor:
                    cursor.close()
                if conn:
                    conn.close()

    return abort(403)


@app.route('/poisk/<string:table>/<string:column>/<string:text>', methods=['GET'])
def poisk_record(table, column, text):
    print('poisk_record')
    if 'is_admin' in session:
        if session['is_admin'] == True:
            print(f'вызов ПОИСКА {table}, {column}, {text}')
            try:
                conn = connect_to_db()
                cursor = conn.cursor(dictionary=True)
                # Получаем заголовки таблицы
                cursor.execute('''SELECT COLUMN_NAME AS Field
                                  FROM INFORMATION_SCHEMA.COLUMNS
                                  WHERE TABLE_NAME = %s AND TABLE_SCHEMA = %s;''', (table, MYSQL_DATABASE))
                table_head = [i['Field'] for i in cursor.fetchall()]
                query = f"SELECT * FROM `{table}` WHERE `{column}` LIKE %s"
                cursor.execute(query, (f"%{text}%",))
                table_value = cursor.fetchall()

                for mas in table_value:
                    for i in mas:
                        if isinstance(mas[i], datetime):
                            mas[i] = mas[i].strftime('%Y-%m-%d %H:%M:%S')
                        if mas[i] is None:
                            mas[i] = ''
                return jsonify({
                    'table_head': table_head,
                    'table_value': table_value
                })

            except Exception as e:
                print('Ошибка:', e)
                flash('Произошла ошибка: ' + str(e), 'error')
                return jsonify({'error': str(e)}), 500
            finally:
                if cursor:
                    cursor.close()
                if conn:
                    conn.close()

    return abort(403)

@app.route('/admin/add_task', methods=['GET', 'POST','PUT','DELETE'])
def add_task():
    print('add_task')
    if 'is_admin' in session:
        if session['is_admin'] == True:
            print('реализовать логику')



    return abort(403)

def start():
    app.run(host='0.0.0.0', port=5000, debug=True)  # поставить порт 80, debug=False


if __name__ == '__main__':
    start()
