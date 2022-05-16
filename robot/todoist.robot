*** Settings ***
Documentation     Get Todoist Grocery list
Library           SeleniumLibrary
Library           Collections
Resource          ./common.robot

*** Variables ***
${TODOIST_TODAY}             https://todoist.com/app/today
${TODOIST_TODAY_TITLE}       Today: Todoist
${TODOIST_EMAIL_LABEL}       labeled-input-1
${TODOIST_EMAIL_PASSWORD}    labeled-input-3

*** Keywords ***

Log In To Todoist
    [Arguments]    ${email}   ${password}
    Wait Until Element Ready    ${TODOIST_EMAIL_LABEL}
    Wait Until Element Ready    ${TODOIST_EMAIL_PASSWORD}
    Input Text              ${TODOIST_EMAIL_LABEL}    ${email}
    Input Password          ${TODOIST_EMAIL_PASSWORD}    ${password}
    Click Button            Log in
    # Wait Until Location Is  ${TODOIST_TODAY}
    Wait Until Page Contains    Today    timeout=30s
    Update Settings If Needed

# When testing, we'll receive emails from Todoist about a login from a new
# device. To avoid raising the alarm we'll only log in when it is needed.
# Otherwise, we'll resume the previous browser session
Log In Or Open Todoist Inner
    [Arguments]    ${email}   ${password}
    Go To   ${TODOIST_TODAY}
    Wait Until Page Contains Element   xpath=//*[.='Log in' or .='Today']   # Wait for page to settle
    Acknowledge Session Expiration If Needed
    ${logged_in}=    Run Keyword And Return Status   Title Should Be   ${TODOIST_TODAY_TITLE}
    IF    not ${logged_in}
        Log In To Todoist   ${email}   ${password}
    END

Log In Or Open Todoist
    [Arguments]    ${email}   ${password}
    Wait Until Keyword Succeeds    5x    2 sec    Log In Or Open Todoist Inner    ${email}   ${password}

Update Settings If Needed
    ${timezone_setting_required}=    Run Keyword And Return Status   Page Should Contain Element   xpath=//*[.='Yes, update my settings']
    IF    '${timezone_setting_required}'=='True'
        Click Element When Ready   xpath=//*[.='Yes, update my settings']
    END

Acknowledge Session Expiration If Needed
    ${session_expired}=    Run Keyword And Return Status   Page Should Contain Element   xpath=//*[.='Please re-login']
    IF    '${session_expired}'=='True'
        Click Element When Ready   OK
    END

Select Todoist List
    [Arguments]    ${list_name}
    Update Settings If Needed
    Click Element When Ready   xpath:(.//span[contains(., '${list_name}')])[1]

Get Todoist List Items
    @{locators}=     Get WebElements    xpath=//li[contains(@class,'task_list_item')]
    ${items}=       Create List
    FOR   ${locator}    IN    @{locators}
        ${list_item}   Get Child WebElements   ${locator}    //div[contains(@class,'task_list_item__content')]
        ${name}=    Get Text    ${list_item}
        ${id}=    Get Element Attribute    ${locator}   data-item-id
        ${item}=    Create Dictionary   id=${id}    name=${name}
        Append To List    ${items}   ${item}
        #Log To Console    ${item}
    END
    [Return]      ${items}

Mark Todoist Item Completed
    [Arguments]    ${id}
    Click Element When Ready    //button[@aria-describedBy='task-${id}-content']

Mark Todoist Items Completed
    [Arguments]    ${items}
    Set Local Variable    ${i}    1
    FOR   ${item}    IN    @{items}
        Log To Console    Marking Todoist item #${i} as completed: ${item.name} (Name in Store: ${item.name_in_store})
        Wait Until Keyword Succeeds    10x    2 sec    Mark Todoist Item Completed   ${item.id}
        IF    ${i} % 10 == 0
            Sleep   10
        ELSE
            Sleep   2
        END
        ${i}    Evaluate    ${i}+1
    END

Go To Todoist Today Page
    Go To   ${TODOIST_TODAY}
    Wait Until Page Contains Element   xpath=//*[.='Today']   # Wait for page to settle