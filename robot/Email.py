import smtplib, ssl
from email.message import EmailMessage

def send_html_email(smtp_username, smtp_password, smtp_server, smtp_port, email_recipient, subject, body):
    msg = EmailMessage()
    msg['Subject'] = subject
    msg['From'] = smtp_username
    msg['To'] = email_recipient
    msg.add_alternative(body, subtype='html');

    context = ssl.create_default_context()
    with smtplib.SMTP_SSL(smtp_server, smtp_port, context=context) as server:
        server.login(smtp_username, smtp_password)
        server.send_message(msg);