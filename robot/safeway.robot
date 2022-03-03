*** Settings ***
Documentation     Safeway Bot
Library           SeleniumLibrary
Library           Collections
Library           String
Resource          ./common.robot

*** Variables ***
${SAFEWAY_HOMEPAGE}     https://www.safeway.com
${SAFEWAY_BUY_IT_AGAIN_URL}   https://www.safeway.com/shop/purchases/buy-it-again.html
${SAFEWAY_SEARCH_URL}   https://www.safeway.com/shop/search-results.html?q=
${SAFEWAY_CART_URL}    https://www.safeway.com/erums/cart
${SAFEWAY_SIGN_IN_URL}    https://www.safeway.com/account/sign-in.html

*** Keywords ***

Log In Or Open Safeway
    [Arguments]    ${email}   ${password}
    Go To   ${SAFEWAY_HOMEPAGE}
    Wait Until Page Contains Element   xpath=//*[.='Account' or .='Sign In']   # Wait for page to settle
    ${logged_in}=    Run Keyword And Return Status   Page Should Contain Element   xpath=//*[.='Account']
    Run Keyword Unless    ${logged_in}    Log In To Safeway   ${email}   ${password}

Dismiss Continue Popup If Needed
    ${popup_displayed}=    Run Keyword And Return Status   Page Should Contain Element   xpath=//*[.='How would you like to continue?']
    IF    '${popup_displayed}'=='True'
        Click Element When Ready   Continue
    END

Dismiss Delivery Popup If Needed
    ${popup_displayed}=    Run Keyword And Return Status   Page Should Contain Element   xpath=//*[.='Please Select Delivery or Pickup to Continue Shopping']
    IF    '${popup_displayed}'=='True'
        #Click Element When Ready   //button[@id='closeFulfillmentModalButton']
        #Click Element When Ready   //button[@data-qa='hmpg-flfllmntmdl-glctricn']
        Wait Until Element Ready    //input[contains(@class, 'input-search fulfillment-content__search-wrapper__input')]
        Input Password    //input[contains(@class, 'input-search fulfillment-content__search-wrapper__input')]    ${ZIP_CODE}
        Click Element When Ready   //*[@data-qa='hmpg-flfllmntmdl-zipcode']
        Mouse Over    //*[@data-qa='hmpg-flfllmntmdl-shpdlivrybttn']
        Sleep    1
        Click Element When Ready   //*[@data-qa='hmpg-flfllmntmdl-shpdlivrybttn']
    END

Dismiss Popups If Needed
    Dismiss Continue Popup If Needed
    Dismiss Delivery Popup If Needed

Log In To Safeway
    [Arguments]    ${email}   ${password}
    # Click Link              xpath=//a[contains(@title, 'Shopping Cart')]
    Go To    ${SAFEWAY_SIGN_IN_URL}
    Wait Until Element Ready    label-email
    Wait Until Element Ready    label-password
    Wait Until Keyword Succeeds    5x    2 sec    Input Text              label-email                   ${email}
    Wait Until Keyword Succeeds    5x    2 sec    Input Password          label-password                ${password}
    Click Element           xpath=//input[@id='btnSignIn']
    Wait Until Page Contains Element   xpath=//*[.='Account']    timeout=10s    # Wait for page to settle
    Dismiss Popups If Needed

Capture List
    @{locators}=     Get WebElements    xpath=//product-item-v2
    ${items}=       Create List
    FOR   ${locator}    IN    @{locators}
        ${title}   Get Child WebElements   ${locator}    //*[contains(@class,'product-title')]
        ${name}=    Get Text    ${title}
        ${id}=    Get Element Attribute    ${title}   data-bpn
        ${url}=    Get Element Attribute    ${title}   href
        ${add_button}   Get Child WebElements   ${locator}    //*[@data-qa='addbutton']
        ${available}=    Run Keyword And Return Status   Page Should Contain Element   ${add_button}
        ${remove_button}   Get Child WebElements   ${locator}    //*[@data-qa='prdctdcrmntr']
        ${in_cart}=    Run Keyword And Return Status   Page Should Contain Element   ${remove_button}
        ${item}=    Create Dictionary   id=${id}    name=${name}    url=${url}    available=${available}    in_cart=${in_cart}
        Append To List    ${items}   ${item}
    END
    Log   ${items}
    [Return]      ${items}

Sort Buy It Again Items
    Click Element When Ready    //*[@data-qa='srt-ptns-dflt']
    Click Link    Frequently Purchased

Get Buy It Again Items
    [Arguments]   ${max_pages}
    Go To   ${SAFEWAY_BUY_IT_AGAIN_URL}
    Dismiss Popups If Needed
    Sort Buy It Again Items
    Load More Items   ${max_pages}
    ${items}=      Capture List
    [Return]    ${items}

Load More Items
    [Arguments]    ${max_pages}
    ${result}    ${condition}=    Run Keyword And Ignore Error    Wait Until Page Contains    Load more   error=false
    FOR   ${i}    IN RANGE    1   ${max_pages}
        Exit For Loop If    '${result}'=='FAIL'
        Click Button    Load more
        ${result}    ${condition}=    Run Keyword And Ignore Error    Wait Until Page Contains    Load more   error=false
    END

Add To Cart
    [Arguments]   ${item_id}

    ${available}=    Run Keyword And Return Status   Page Should Contain Element   //*[@id='addButton_${item_id}']

    # Is the item still available? We want to avoid a race condition where our last attempt
    # succeeded, but was just very slow and now we are retrying when the item is already in the
    # cart.
    IF    '${available}'=='True'

        Dismiss Popups If Needed

        Wait Until Element Ready    //*[@id='addButton_${item_id}']

        # Safeway requires a mouse over before the item can be added to the cart
        Set Focus To Element    //*[@id='addButton_${item_id}']
        Mouse Over    //*[@id='addButton_${item_id}']

        Click Element When Ready   //*[@id='addButton_${item_id}']

        # Wait for loading spinner to disappear
        Wait Until Page Does Not Contain Element    //*[@class='quantity-loading']

        # Wait enough time for cart addition to settle
        Wait Until Page Does Not Contain Element    //*[@id='addButton_${item_id}']
        Wait Until Element Ready    //*[@id='dec_qtyInfo_${item_id}']    timeout=10s

    END

Buy It Again
    [Arguments]   ${items_to_buy}   ${max_pages}
    ${buy_it_again_items}=    Get Buy It Again Items    ${max_pages}
    ${items_in_cart}=       Create List
    ${items_not_found}=       Create List
    FOR   ${item_to_buy}    IN    @{items_to_buy}
        Set Local Variable    ${added_to_cart}    False
        FOR   ${buy_it_again_item}    IN    @{buy_it_again_items}
            ${name_matches}=    Run Keyword And Return Status    Should Contain    ${buy_it_again_item.name}   ${item_to_buy.name}    ignore_case=True
            IF    '${name_matches}'=='True' and ('${buy_it_again_item.available}'=='True' or '${buy_it_again_item.in_cart}'=='True')
                # Look up the availability again as we may have just added the item to the cart so
                # we cannot use ${buy_it_again_item.available}
                ${available}=    Run Keyword And Return Status   Page Should Contain Element   //*[@id='addButton_${buy_it_again_item.id}']

                # If the item is already in the cart then we just ignore it as this allows us to
                # retry the script without it adding any additional items to the cart
                IF    '${available}'=='True'
                    Log To Console    Adding to cart: ${buy_it_again_item.name} (Todoist item name: ${item_to_buy.name})
                    Wait Until Keyword Succeeds    10x    2 sec    Add To Cart    ${buy_it_again_item.id}
                ELSE
                    Log To Console    Already in cart: ${buy_it_again_item.name} (Todoist item name: ${item_to_buy.name})
                END
                Set To Dictionary    ${item_to_buy}    name_in_store=${buy_it_again_item.name}
                Append To List    ${items_in_cart}    ${item_to_buy}
                Set Local Variable    ${added_to_cart}    True
                Exit For Loop
            END
        END
        IF    '${added_to_cart}'=='False'
            Append To List    ${items_not_found}   ${item_to_buy}
        END
    END

    [Return]   ${items_in_cart}   ${items_not_found}    ${buy_it_again_items}

Add Found Item To Cart
    [Arguments]    ${id}
    Set Local Variable    ${added_to_cart}    False
    Set Local Variable    ${name_in_store}    Unknown
    ${available}=    Run Keyword And Return Status   Page Should Contain Element   //*[@id='addButton_${id}']
    ${remove_button}=    Run Keyword And Return Status   Page Should Contain Element   //*[@id='dec_qtyInfo_${id}']
    IF    '${available}'=='True' or '${remove_button}'=='True'
        # If the item is already in the cart then we just ignore it as this allows us to retry
        # the script without it adding any additional items to the cart
        IF    '${available}'=='True'
            Add To Cart    ${id}
        END
        Set Local Variable    ${added_to_cart}    True
        ${name_in_store}=    Get Text    //*[contains(@class,'product-title') and @data-bpn='${id}']
    END
    [Return]    ${added_to_cart}    ${name_in_store}

Add Found Items With Buy It Again Badge
    # Some of the items that we bought before may be out of stock so let's see which one we can buy
    @{locators}=     Get WebElements    //*[contains(@class, 'buy-it-again__badge')]
    ${items}=       Create List
    Set Local Variable    ${added_to_cart}    False
    Set Local Variable    ${name_in_store}    Unknown
    FOR   ${locator}    IN    @{locators}
        ${a}   Get Following Sibling WebElement   ${locator}
        ${id}=    Get Element Attribute    ${a}   data-bpn
        ${added_to_cart}    ${name_in_store}=    Add Found Item To Cart    ${id}
        Exit For Loop If    '${added_to_cart}'=='True'
    END
    [Return]    ${added_to_cart}    ${name_in_store}

Add Found Items In Buy It Again List
    [Arguments]    ${buy_it_again_items}
    Set Local Variable    ${added_to_cart}    False
    Set Local Variable    ${name_in_store}    Unknown
    # Note: we iterate through buy_it_again_items and not search results as we want the order of
    # buy_it_again_items to take priority. FUTURE: if this is too slow then perhaps capture list of
    # search results first.
    FOR    ${buy_it_again_item}    IN    @{buy_it_again_items}
        ${added_to_cart}    ${name_in_store}=    Add Found Item To Cart    ${buy_it_again_item.id}
        Exit For Loop If    '${added_to_cart}'=='True'
    END
    [Return]    ${added_to_cart}    ${name_in_store}

Find Item And Buy It Again
    [Arguments]   ${item_name}    ${buy_it_again_items}
    Go To   https://www.safeway.com/shop/search-results.html?q=${item_name}
    Load More Items   2

    ${added_to_cart}    ${name_in_store}=    Add Found Items With Buy It Again Badge

    # NOTE: doesn't appear to be a bug anymore
    # IF  '${added_to_cart}'=='False'
    #     # There is a bug in the Safeway search that sometimes leads to results missing a Buy It
    #     # Again Badge. We can workaround this by doing a look up with the buy_it_again_items we
    #     # retrieved earlier.
    #     ${added_to_cart}    ${name_in_store}=    Add Found Items In Buy It Again List    ${buy_it_again_items}
    # END

    [Return]    ${added_to_cart}    ${name_in_store}

Find And Buy It Again
    [Arguments]   ${items_to_buy}    ${buy_it_again_items}
    ${items_in_cart}=       Create List
    ${items_not_found}=       Create List
    FOR   ${item_to_buy}    IN    @{items_to_buy}
        ${added_to_cart}    ${name_in_store}    Find Item And Buy It Again    ${item_to_buy.name}    ${buy_it_again_items}
        IF    '${added_to_cart}'=='True'
            Log To Console    Found and adding to cart: ${item_to_buy.name} (Name in store: ${name_in_store})
            Set To Dictionary    ${item_to_buy}    name_in_store=${name_in_store}
            Append To List    ${items_in_cart}   ${item_to_buy}
        ELSE
            Log To Console    Not found: ${item_to_buy.name}
            Append To List    ${items_not_found}   ${item_to_buy}
        END
    END
    [Return]   ${items_in_cart}   ${items_not_found}

Remove Next Item From Cart
    ${item}=    Get WebElement    //app-cart-item
    ${decrease_button}=    Get Child WebElements   ${item}    //*[@aria-label='Decrease quantity']
    ${id}=    Get Element Attribute    ${decrease_button}    id
    ${remove_button}=    Get Child WebElements   ${item}    //*[contains(@class, 'remove-button')]
    Click Element When Ready    ${remove_button}
    Wait Until Page Does Not Contain Element    //*[@id='${id}']

Clear Safeway Cart
    Go To    ${SAFEWAY_CART_URL}

    # Wait for page to settle
    Wait Until Page Contains Element   xpath=//*[contains(@class, 'remove-button') or .='My Cart (0)' or .='Your shopping cart is empty']    timeout=20s

    # Need get the element each time to avoid "element is not attached to the page document" errors
    # as it appears the list is rerendered every time an item is removed from it.
    FOR    ${i}    IN RANGE    999999
        ${has_items}=    Run Keyword And Return Status   Page Should Contain Element   //*[contains(@class, 'remove-button')]
        Exit For Loop If    '${has_items}'=='False'
        Remove Next Item From Cart
    END
