*** Settings ***
Documentation     Common Keywords

*** Variables ***
${USER_DATA_PATH}         ./output/user-data

*** Keywords ***

# As per https://www.formulatedautomation.com/post/staying-logged-in-with-robot-framework-rpaframework-browser allows us to resume the browser session
Open Browser Profiled
    [Arguments]    ${url}
    ${options}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver
    Call Method    ${options}    add_argument    --user-data-dir\=${USER_DATA_PATH}
    Create WebDriver    Chrome    chrome_options=${options}
    Go To    ${url}

# Source: https://stackoverflow.com/a/53763716/2831606
Get Child WebElements
    [Arguments]    ${locator}   ${child_xpath}

    ${element}    Get WebElement    ${locator}
    ${children}     Call Method
    ...                ${element}
    ...                find_elements
    ...                  by=xpath    value=.${child_xpath}

    [Return]      ${children}

Get Following Sibling WebElement
    [Arguments]    ${locator}

    ${element}    Get WebElement    ${locator}      
    ${sibling}     Call Method       
    ...                ${element}    
    ...                find_element    
    ...                  by=xpath    value=following-sibling::*

    [Return]    ${sibling}

Wait Until Element Ready Inner
    [Arguments]    ${locator}    ${timeout}=None
    Wait Until Page Contains Element    ${locator}    ${timeout}
    Wait Until Element Is Visible    ${locator}
    Wait Until Element Is Enabled    ${locator}
    Scroll Element Into View    ${locator}
    
    Wait Until Element Is Visible    ${locator}
    Wait Until Element Is Enabled    ${locator}
    # For some unknown reason a second "Scroll Element Into View" is actually needed before the
    # scroll occurs
    Scroll Element Into View    ${locator}

Wait Until Element Ready
    [Arguments]    ${locator}    ${timeout}=None
    Wait Until Keyword Succeeds    3   1s    Wait Until Element Ready Inner    ${locator}    ${timeout}

Click Element When Ready Inner
    [Arguments]    ${locator}
    Wait Until Element Ready    ${locator}
    ${element}=    Get WebElement     ${locator}
    Click Element    ${element}
    [Return]    ${element}

Click Element When Ready
    [Arguments]    ${locator}
    Wait Until Keyword Succeeds    3   1s    Click Element When Ready Inner    ${locator}

Get WebElements When Ready
    [Arguments]    ${locator}
    Wait Until Element Ready    ${locator}
    ${elements}=    Get WebElements    ${locator}
    [Return]    ${elements}