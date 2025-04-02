import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from quiz_english.config import EMAIL_ADDRESS, EMAIL_PASSWORD

def send_mail(reset_link, recipients):
    try:
        server = 'smtp.mail.ru'
        user = EMAIL_ADDRESS
        password = EMAIL_PASSWORD

        recipients = recipients
        sender = EMAIL_ADDRESS
        subject = 'Сброс пароля'

        # Read the HTML content from the file
        with open('reset_password_template.html', 'r', encoding='utf-8') as file:
            html = file.read()

        # Replace the placeholder with the reset link
        html = html % (reset_link)

        msg = MIMEMultipart('alternative')
        msg['Subject'] = subject
        msg['From'] = 'Cinema support <' + sender + '>'
        msg['To'] = ', '.join(recipients)
        msg['Reply-To'] = sender
        msg['Return-Path'] = sender

        part_html = MIMEText(html, 'html')

        msg.attach(part_html)

        mail = smtplib.SMTP_SSL(server)
        mail.login(user, password)
        mail.sendmail(sender, recipients, msg.as_string())
        mail.quit()
    except Exception as err:
        import traceback
        print(traceback.format_exc())
        print(f'ошибка отправки письма {err}')
        return False


if __name__ == '__main__':
    recipients = ['for_progkids@mail.ru']
    send_mail(reset_link='http://127.0.0.1:5000/reset_password/WyJmb3JfcHJvZ2tpZHNAbWFpbC5ydSJd.Z4qMvQ.oWmcH_v9prZM2Vjv2pfqPj4GZVI', recipients=recipients)