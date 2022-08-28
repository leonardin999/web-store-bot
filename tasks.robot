*** Settings ***
Documentation       Swag order robot. Places orders at https://www.saucedemo.com/
...                 by processing a spreadsheet of orders and ordering the
...                 specified products using browser automation. Uses local or
...                 cloud vault for credentials.

Library             RPA.Robocorp.Vault
Library             RPA.Browser.Selenium    auto_close=${False}
Library             OperatingSystem
Library             RPA.HTTP
Library             Orders


*** Variables ***
${EXCEL_FILE_NAME}      Data.xlsx
${EXCEL_FILE_URL}       https://github.com/robocorp/example-activities/raw/master/web-store-order-processor/devdata/${EXCEL_FILE_NAME}
${SWAG_LABS_URL}        https://www.saucedemo.com


*** Tasks ***
swag place orders
    ${USERNAME}    ${PASSWORD}=    init Settings
    open Swag Labs
    Wait Until Keyword Succeeds    3x    1s    login website    ${USERNAME}    ${PASSWORD}
    ${orders}=    Collect orders
    FOR    ${order}    IN    @{orders}
        Run Keyword And Continue On Failure    Process order    ${order}
    END
    [Teardown]    Close Browser


*** Keywords ***
init Settings
    [Documentation]    initialise configuration setting
    ${_SECRET_}=    Get Secret    swaglabs
    ${USERNAME}=    Set Variable    ${_SECRET_}[username]
    ${PASSWORD}=    Set Variable    ${_SECRET_}[password]
    RETURN    ${USERNAME}    ${PASSWORD}

open Swag Labs
    [Documentation]    insert notation here ...
    Open Available Browser    ${SWAG_LABS_URL}    maximized= True

login website
    [Documentation]    insert notation here ...
    [Arguments]    ${username}    ${password}
    Input Text    css:input#user-name    ${username}
    Input Password    css:input#password    ${password}
    Submit Form
    Assert logged in

Assert logged in
    Wait Until Page Contains Element    css:div#inventory_container
    Location Should Be    ${SWAG_LABS_URL}/inventory.html

Collect orders
    [Documentation]    get order excel files path
    Download    ${EXCEL_FILE_URL}    overwrite= True
    ${orders}=    Get Orders    ${EXCEL_FILE_NAME}
    RETURN    ${orders}

Process order
    [Documentation]    insert notation here ...
    [Arguments]    ${order}
    Reset Application State
    Open Product Page
    Assert Cart is Empty
    Wait Until Keyword Succeeds    3x    1s    Add Products to the Cart    ${order}
    Wait Until Keyword Succeeds    3x    1s    Open cart
    Assert one product in cart    ${order}
    Checkout    ${order}
    Open Product Page

Reset Application State
    [Documentation]    insert notion here ...
    Click Button    css:#react-burger-menu-btn
    Wait Until Element Is Visible    css:a#reset_sidebar_link
    Click Element    css:a#reset_sidebar_link

Open Product Page
    [Documentation]    Return the Main products Page
    Go To    ${SWAG_LABS_URL}/inventory.html
    Wait Until Page Contains Element    css:div#inventory_container

Assert Cart is Empty
    [Documentation]    Check for empty Shooping Cart
    Element Text Should Be    css:a.shopping_cart_link    ${EMPTY}
    Page Should Not Contain Element    css:.shopping_cart_badge

Add Products to the Cart
    [Documentation]    Add product to the list as required in downloaded files
    [Arguments]    ${orders}
    ${product_name}=    Set Variable    ${orders["item"]}
    ${locator}=    Set Variable
    ...    xpath://div[@class="inventory_item" and descendant::div[contains(text(),"${product_name}")]]
    ${product}=    Get WebElement    ${locator}
    ${add_to_cart_button}=    Set Variable    ${product.find_element_by_class_name("btn_primary")}
    Click Button    ${add_to_cart_button}
    Assert Cart is in Cart    1

Assert Cart is in Cart
    [Arguments]    ${quantity}
    Element Text Should Be    css:.shopping_cart_badge    ${quantity}

Open cart
    Click Link    css:.shopping_cart_link
    Assert cart page

Assert cart page
    Wait Until Page Contains Element    css:div#cart_contents_container
    Location Should Be    ${SWAG_LABS_URL}/cart.html

Assert One Product in cart
    [Arguments]    ${order}
    Element Text Should Be    css:.cart_quantity    1
    Element Text Should Be    css:.inventory_item_name    ${order["item"]}

Checkout
    [Arguments]    ${order}
    Click Button    css:#checkout
    Assert checkout information page
    Input Text    first-name    ${order["first_name"]}
    Input Text    last-name    ${order["last_name"]}
    Input Text    postal-code    ${order["zip"]}
    Submit Form
    Assert checkout confirmation page
    Click Element When Visible    css:#finish
    Assert checkout complete page

Assert checkout information page
    Wait Until Page Contains Element    checkout_info_container
    Location Should Be    ${SWAG_LABS_URL}/checkout-step-one.html

Assert checkout confirmation page
    Wait Until Page Contains Element    checkout_summary_container
    Location Should Be    ${SWAG_LABS_URL}/checkout-step-two.html

Assert checkout complete page
    Wait Until Page Contains Element    checkout_complete_container
    Location Should Be    ${SWAG_LABS_URL}/checkout-complete.html
