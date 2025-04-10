import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from PIL import Image, ImageDraw, ImageFont
from datetime import datetime
import os
from pathlib import Path

from config import EMAIL_ADDRESS, EMAIL_PASSWORD


def create_certificate(name, output_path):
    current_dir = Path(__file__).parent

    def calculate_y(x):
        points = [
            (45, 2.7),
            (40, 2.65),
            (30, 2.6),
            (20, 2.5),
            (10, 2.45)
        ]

        points.sort(reverse=True)

        if x > points[0][0] or x < points[-1][0]:
            raise ValueError(f"x должен быть в диапазоне [{points[-1][0]}, {points[0][0]}]")

        for i in range(len(points) - 1):
            x1, y1 = points[i]
            x2, y2 = points[i + 1]
            if x1 >= x >= x2:
                y = y1 + (x - x1) * (y2 - y1) / (x2 - x1)
                return round(y, 3)

        raise ValueError("Ошибка при интерполяции")

    # Загрузка шаблона сертификата
    file_path = current_dir / "certificat.jpg"
    if not file_path.exists():
        raise FileNotFoundError(f"Файл не найден: {file_path}")

    certificate_template = Image.open(file_path)
    draw = ImageDraw.Draw(certificate_template)

    # Размеры изображения
    image_width, image_height = certificate_template.size

    # Цвет текста
    text_color = (0, 0, 0)

    # Максимальная ширина текста
    max_text_width = int(image_width * 0.8)

    # Размер шрифта для имени
    font_size_name = 38
    font_path = current_dir / "arial.ttf"

    while True:
        font_name = ImageFont.truetype(str(font_path), size=font_size_name)
        text_bbox = draw.textbbox((0, 0), name, font=font_name)
        text_width = text_bbox[2] - text_bbox[0]

        if text_width <= max_text_width:
            break

        font_size_name -= 1
        if font_size_name < 10:
            raise ValueError("Текст слишком длинный для размещения на сертификате.")

    # Расположение текста имени
    text_position_x = (image_width - text_width) // 2
    text_position_y = image_height // calculate_y(font_size_name)

    # Добавление текста (ФИО участника)
    draw.text((text_position_x, text_position_y), name, fill=text_color, font=font_name)

    # Добавление даты
    date = datetime.now().strftime("%d.%m.%Y")
    font_size_date = 32
    font_date = ImageFont.truetype(str(font_path), size=font_size_date)

    date_bbox = draw.textbbox((0, 0), date, font=font_date)
    date_width = date_bbox[2] - date_bbox[0]
    date_height = date_bbox[3] - date_bbox[1]

    date_position_x = date_width + 170
    date_position_y = image_height - date_height - 230

    draw.text((date_position_x, date_position_y), date, fill=text_color, font=font_date)

    # Сохранение готового сертификата
    certificate_template.save(output_path)
    print(f"Сертификат сохранен: {output_path}")
    return True


def send_mail_with_image(image_path, recipients, familia, ima, otchestvo):
    current_dir = Path(__file__).parent

    try:
        output_file = current_dir / 'certificate_output.jpg'
        res = create_certificate(f'{familia} {ima} {otchestvo}', output_file)
        if not res:
            return False

        # SMTP server configuration
        server = 'smtp.mail.ru'
        user = EMAIL_ADDRESS
        password = EMAIL_PASSWORD

        sender = EMAIL_ADDRESS
        subject = 'Изображение'

        html_template_path = current_dir / "image_template.html"
        if not html_template_path.exists():
            raise FileNotFoundError(f"Файл не найден: {html_template_path}")

        with open(html_template_path, 'r', encoding='utf-8') as file:
            html = file.read()

        # Создаем multipart сообщение
        msg = MIMEMultipart('related')
        msg['Subject'] = subject
        msg['From'] = f'MSVU support <{sender}>'.encode('utf-8').decode('utf-8')  # Кодируем в UTF-8
        msg['To'] = ', '.join(recipients).encode('utf-8').decode('utf-8')  # Кодируем в UTF-8
        msg['Reply-To'] = sender
        msg['Return-Path'] = sender

        # Attach the image to the email
        with open(output_file, 'rb') as img_file:
            mime_image = MIMEBase('image', 'jpeg')
            mime_image.set_payload(img_file.read())
            encoders.encode_base64(mime_image)
            mime_image.add_header('Content-Disposition', 'attachment', filename=output_file.name)
            mime_image.add_header('Content-ID', '<image>')
            msg.attach(mime_image)

        # Replace the placeholder in the HTML template with the correct Content-ID
        html = html.replace('{{IMAGE_CID}}', 'cid:image')

        # Attach the HTML part
        part_html = MIMEText(html, 'html', 'utf-8')  # Явно указываем кодировку UTF-8
        msg.attach(part_html)

        # Send the email
        mail = smtplib.SMTP_SSL(server)
        mail.login(user, password)
        mail.sendmail(sender, recipients, msg.as_string().encode('utf-8'))  # Кодируем в UTF-8
        mail.quit()

        try:
            os.remove(output_file)
        except Exception as err:
            print(f'Ошибка удаления файла: {err}')

        return True

    except Exception as err:
        import traceback
        print(traceback.format_exc())
        print(f'Ошибка отправки письма: {err}')
        return False


if __name__ == "__main__":
    r = send_mail_with_image(
        'certificate_output.jpg',
        ['pasechnikov.leha@inbox.ru'],
        'Фамилия',
        'Имя',
        'Отчество'
    )
    print('Успех:', r)