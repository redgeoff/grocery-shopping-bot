*** Settings ***
Documentation     Send Email
Library           DateTime
# Library           RPA.Email.ImapSmtp    smtp_server=smtp.gmail.com    smtp_port=587
Library           Email.py

*** Keywords ***

# Note: the RPA framework developed by Robocorp doesn't play nicely with the
# ppodgorsek/robot-framework Docker image so we instead use a custom Python script, Email.py, to
# send the email
#
# RPA Send Html Email
#     [Arguments]    ${smtp_username}    ${smtp_password}    ${smtp_server}    ${smtp_port}    ${email_recipient}    ${subject}    ${body}
#     Authorize    account=${smtp_username}    password=${smtp_password}   smtp_server=${smtp_server}    smtp_port=${smtp_port}
#     Send Message    sender=${smtp_username}
#     ...    recipients=${email_recipient}
#     ...    subject=${subject}
#     ...    html=True
#     ...    body=${body}

Send Email
    [Arguments]    ${smtp_username}    ${smtp_password}    ${smtp_server}    ${smtp_port}    ${email_recipient}    ${items_in_cart}
    ${date}=      Get Current Date      UTC      exclude_millis=yes
    ${converted_date}=      Convert Date      ${date}      result_format=%a %B %d %H:%M:%S UTC %Y

    Set Local Variable    ${i}    1
    Set Local Variable    ${body}    <table border="1"><tr><th>#</th><th>Todoist Item</th><th>Name in Safeway Cart</th></tr>
    FOR   ${item}    IN    @{items_in_cart}
        ${body}=    Catenate    ${body}    <tr><td>${i}</td><td>${item.name}</td><td>${item.name_in_store}</td></tr>
        ${i}    Evaluate    ${i}+1
    END
    ${body}=    Catenate    ${body}    </table>

    # RPA Send Html Email    ${smtp_username}    ${smtp_password}    ${smtp_server}    ${smtp_port}    ${email_recipient}    Grocery shopping bot ${converted_date}    ${body}
    Send Html Email    ${smtp_username}    ${smtp_password}    ${smtp_server}    ${smtp_port}    ${email_recipient}    Grocery shopping bot ${converted_date}    ${body}