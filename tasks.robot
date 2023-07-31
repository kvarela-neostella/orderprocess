*** Settings ***
Library     RPA.Browser.Selenium
Library     OperatingSystem
Library     RequestsLibrary
Library     RPA.HTTP
Library     RPA.Tables
Library     BuiltIn
Library     RPA.Desktop
Library     RPA.PDF
Library     RPA.Archive


*** Variables ***
${URL}              https://robotsparebinindustries.com/#/robot-order
${CSV_URL}          https://robotsparebinindustries.com/orders.csv
${OUTPUT_DIR}       ${EXECDIR}\\robocorp
${CSV_FILE}         ${OUTPUT_DIR}\\orders.csv


*** Tasks ***
Open Website
    Open the Website

Close Modal
    Close the Annoying Modal

Download Orders
    Download Orders CSV    ${CSV_URL}    ${CSV_FILE}

Files to Table
    Files to Table    ${CSV_FILE}

Create ZIP package from PDF files
    Create ZIP package from PDF files


*** Keywords ***
Wait for H2 Element
    Wait Until Page Contains Element    xpath=//h2[contains(text(), 'Build and order your robot!')]

Wait Until Order Another Button Appears
    Wait For Element    //button[@id="order-another"]

Fill the form
    [Arguments]    ${row}
    # Assuming the form field locators, update these according to your website
    Select From List By Value    id=head    ${row}[Head]
    Input Text    class=form-control    ${row}[Legs]
    Input Text    id=address    ${row}[Address]
    Click Element When Visible    xpath=//input[@type='radio'][@value='${row}[Body]']
    Click Element When Visible    //button[@id="preview"]
    Click Element When Visible    //button[@id="order"]

Open the Website
    Open Available Browser    ${URL}

Close the Annoying Modal
    Click Element    //button[@class="btn btn-dark"]

Download Orders CSV
    [Arguments]    ${url}    ${output_file}
    Create Directory    ${OUTPUT_DIR}
    RPA.HTTP.Download    ${url}    ${output_file}    overwrite=True

Click If Element Exists
    [Arguments]    ${locator}
    ${element_exists}=    Run Keyword And Return Status    Page Should Contain Element    ${locator}
    IF    ${element_exists}    Click Element    ${locator}

Files to Table
    [Arguments]    ${direc}

    ${table}=    Read table from CSV    ${direc}
    FOR    ${row}    IN    @{table}
        TRY
            Log many
            ...    Order number: ${row}[Order number]
            ...    Head: ${row}[Head]
            ...    Legs: ${row}[Legs]
            ...    Address ${row}[Address]
            ...    Body ${row}[Body] ...
            ...

            Fill the form    ${row}

            Capture Page Screenshot    ${OUTPUT_DIR}/${row}[Order number].png
            Wait Until Element Is Visible    id:order-completion
            ${sales_results_html}=    Get Element Attribute    id:order-completion    outerHTML
            Html To Pdf    ${sales_results_html}    ${OUTPUT_DIR}${/}PDF${/}${row}[Order number].pdf
            Open PDF    ${OUTPUT_DIR}${/}PDF${/}${row}[Order number].pdf
            ${files}=    Create List
            ...    ${OUTPUT_DIR}${/}${row}[Order number].png
            Add Files To PDF    ${files}    ${OUTPUT_DIR}${/}PDF${/}${row}[Order number].pdf    ${True}
            Close Pdf    ${OUTPUT_DIR}${/}PDF${/}${row}[Order number].pdf
            Click Element When Visible    //button[@id="order-another"]
            Close the Annoying Modal
        EXCEPT
            Log    Alert did not appear or could not be handled
            Open the Website    # Navigate to another webpage even if there was an exception
            Close the Annoying Modal
        END
    END

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}PDF${/}PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}PDF
    ...    ${zip_file_name}
