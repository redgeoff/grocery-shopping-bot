*** Settings ***
Documentation     Shop
Library           SeleniumLibrary
Library           Collections
Resource          ./common.robot
Resource          ./todoist.robot
Resource          ./safeway.robot
Resource          ./email.robot

*** Test Cases ***
Shop
    Shop For Groceries
    # Clear Cart
    # [Teardown]    Close Browser

*** Keywords ***

Shop For Groceries
    ${items_to_buy}=   Get List From Todoist
    ${items_in_cart}=   Add To Safeway Cart   ${items_to_buy}
    Mark Todoist List Completed    ${items_in_cart}

    # TODO: remove
    # ${items_in_cart}=       Create List
    # ${item}=    Create Dictionary   name=pretzels    name_in_store=SuperPretzel Soft Pretzels Fully Baked Original - 13 Oz
    # Append To List    ${items_in_cart}   ${item}
    # ${item}=    Create Dictionary   name=salsa    name_in_store=Signature Cafe Salsa Fresca Hot - 16 Oz
    # Append To List    ${items_in_cart}   ${item}

    Send Email    ${SMTP_USERNAME}    ${SMTP_PASSWORD}    ${SMTP_SERVER}    ${SMTP_PORT}    ${EMAIL_RECIPIENT}    ${items_in_cart}

Get List From Todoist
    Log In Or Open Todoist    ${TODOIST_EMAIL}    ${TODOIST_PASSWORD}
    Select Todoist List   ${TODOIST_LIST_NAME}
    ${items_to_buy}=   Get Todoist List Items
    [Return]    ${items_to_buy}

Add To Safeway Cart
    [Arguments]   ${items_to_buy}
    Log In Or Open Safeway    ${SAFEWAY_EMAIL}    ${SAFEWAY_PASSWORD}
    ${items_added_cart1}    ${items_not_found1}    ${buy_it_again_items}=   Buy It Again    ${items_to_buy}   ${SAFEWAY_BUY_IT_AGAIN_PAGES}
    ${items_added_cart2}    ${items_not_found2}    Find And Buy It Again    ${items_not_found1}    ${buy_it_again_items}
    ${items_in_cart}    Combine Lists    ${items_added_cart1}    ${items_added_cart2}
    [Return]    ${items_in_cart}

Mark Todoist List Completed
    [Arguments]   ${items_in_cart}
    Go To Todoist Today Page
    Select Todoist List   ${TODOIST_LIST_NAME}
    Mark Todoist Items Completed    ${items_in_cart}

# For debugging
Clear Cart
    Open Browser Profiled    about:blank
    Log In Or Open Safeway    ${SAFEWAY_EMAIL}    ${SAFEWAY_PASSWORD}
    Clear Safeway Cart