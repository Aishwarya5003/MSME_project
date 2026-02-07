*** Settings ***
Library    RequestsLibrary
Library    CSVLibrary
Library    Collections
Library    OperatingSystem
Library    String
Library    DatabaseLibrary
Library    DateTime
Library    JSONLibrary
Library    BuiltIn

Suite Setup     Connect To Database     pymysql     ${DB_Name}      ${DB_user}      ${DB_pass}      ${DB_host}     ${DB_port}
Suite Teardown      Disconnect From Database

*** Variables ***
${DB_Name}        validation
${DB_user}        qa.aishwarya
${DB_pass}        PYvHHoNKAbhYUhF
${DB_host}        dev-db.chjy1zjdr74q.ap-south-1.rds.amazonaws.com
${DB_port}        3306
${base_url}=    https://svcstage.digitap.work
${endpoint_url}=    /cv/v1/company_to_cin
${file_path}=   C:\\Users\\Aishwarya\\PycharmProjects\\APIAutomation\\data\\Company to CIN.csv
${client-username}=    526526315047
${client-password}=    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
${MAX_RESPONSE_TIME}    130000  # in milliseconds
${MIN_RESPONSE_TIME}    3000    # in milliseconds
${json_schema_file}=    C:\\Users\\Aishwarya\\PycharmProjects\\APIAutomation\\Json_schema\\COI services\\json_schema company name to cin.json


*** Keywords ***
Read Test Data From CSV
    [Arguments]    ${file_path}
    ${test_data}=    Create List
    ${file_content}=    Get File    ${file_path}
    ${lines}=    Split To Lines    ${file_content}
    FOR    ${line}    IN    @{lines}[1:]    # Skip the header line
        ${columns}=    Split String    ${line}    separator=,
        ${data}=    Create Dictionary    company_name=${columns[1]}    client_ref_num=${columns[2]}    output_count=${columns[3]}       test_scenario=${columns[4]}
        Append To List    ${test_data}    ${data}
    END
    [Return]    ${test_data}


Validate JSON Response
    [Arguments]    ${expected_json}    ${actual_json}
    ${expected_keys}=    Get Dictionary Keys    ${expected_json}
    ${actual_keys}=    Get Dictionary Keys    ${actual_json}

    # Remove ignored keys (like request_id)
    Remove Values From List    ${actual_keys}    request_id
    Remove Values From List    ${expected_keys}    request_id

    # Check for missing keys
    ${missing_keys}=    Copy List    ${expected_keys}
    Remove Values From List    ${missing_keys}    @{actual_keys}
    Run Keyword If    ${missing_keys}    Fail    Missing keys in response: ${missing_keys}

    # Check for extra keys
    ${extra_keys}=    Copy List    ${actual_keys}
    Remove Values From List    ${extra_keys}    @{expected_keys}
    Run Keyword If    ${extra_keys}    Fail    Unexpected extra keys in response: ${extra_keys}

    # Validate each key-value pair
    FOR    ${key}    IN    @{expected_keys}
        ${expected_value}=    Get From Dictionary    ${expected_json}    ${key}
        ${actual_value}=    Get From Dictionary    ${actual_json}    ${key}
        Should Be Equal As Strings    ${actual_value}    ${expected_value}    msg=Mismatch for key ${key}
    END

# Post Request and Validate
Send Post Request And Validate
    [Arguments]    ${auth}    ${body}    ${expected_schema_file}    ${case_key}
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true
    ${header}=    Create Dictionary    Content-Type=application/json
    # Print input payload EXACTLY as dictionary
    Log To Console    ${body}
     # Retry mechanism


    ${max_retries}=    Set Variable    2
    ${retry_limit}=    Evaluate    ${max_retries} + 1

    ${response}=    Set Variable    None

    FOR    ${i}    IN RANGE    ${retry_limit}
        ${response}=    POST On Session
        ...    mysession
        ...    ${endpoint_url}
        ...    json=${body}
        ...    headers=${header}
        ...    expected_status=any      # ← IMPORTANT FIX

        Log To Console    Attempt ${i} - Status: ${response.status_code}

        # ---- Retry ONLY for 503 ----
        Run Keyword If    ${response.status_code} != 503    Exit For Loop

        Log To Console    503 received → retrying...
        Sleep    3s
    END

    # If still 503 after retries → fail test
    Run Keyword If    ${response.status_code} == 503    Fail    API returned 503 after ${max_retries} retries

    Log To Console    Final Status Code: ${response.status_code}
    Log To Console    ${response.content}

    # Parse actual response JSON
    ${actual_json}=    Convert To Dictionary    ${response.json()}
    Log To Console    ${actual_json}

    # Load expected JSON schema
    ${expected_json}=    Load JSON From File    ${expected_schema_file}

    # Extract the relevant case from the JSON schema
    ${expected_case_json}=    Get From Dictionary    ${expected_json}    ${case_key}

    # Validate the JSON response
    Validate JSON Response    ${expected_case_json}    ${actual_json}


*** Test Cases ***
TC - MSME-T3551 (1.0)
    log to console    To verify by entering by entering valid company name
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

TC - MSME-T3552 (1.0)
    log to console    To verify by entering a company name that is not found
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    1
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case2


TC - MSME-T3553 (1.0)
    log to console    To verify by entering an invalid company name
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    2
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case3

TC - MSME-T3554 (1.0)
    log to console    To verify by entering only special characters in the company name
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    3
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case4


TC - MSME-T3555 (1.0)
    log to console    To verify by entering only numeric characters in the company name

    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    4
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case5


TC - MSME-T3556 (1.0)
    log to console    To verify by entering only alphabetic characters in the company name
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    5
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case6

TC - MSME-T3557 (1.0)

    log to console    To verify by entering a mix of alphabetic, numeric, and special characters in the company name
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    6
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case7

TC - MSME-T3558 (1.0)
    log to console    To verify by entering mixed of numeric and alpha char
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    7
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case8


TC - MSME-T3559 (1.0)
    log to console    To verify by entering mixed of alpha and special char
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    8
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case9

TC - MSME-T3560 (1.0)
    log to console    To verify by entering mixed of numeric and special char
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    9
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case10

TC - MSME-T3561 (1.0)
    log to console    To verify by entering company name is "XXXXXXX"
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    10
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case11


TC - MSME-T3562 (1.0)
    log to console    To verify by entering company name is "YYYYYYYYYY"
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    11
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case12

TC - MSME-T3563 (1.0)
    log to console    To verify by entering less than 3 characters for the company name
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    12
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case13


TC - MSME-T3564 (1.0)
    log to console    To verify by entering 3 characters for the company name.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    13
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}      output_count=${row['output_count']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case14


TC - MSME-T3565 (1.0)
    log to console    To verify by entering company name as special char (.) is allowing or not
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    14
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case15



TC - MSME-T3566 (1.0)
    log to console    To verify by entering company name as special char (-) is allowing or not
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    15
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}      output_count=${row['output_count']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case16


TC - MSME-T3567 (1.0)
    log to console    To verify by leaving the company name field empty.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    16
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case17

TC - MSME-T3568 (1.0)
    log to console    To verify by leaving the company name field as an empty space.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    17
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case18

TC - MSME-T3569 (1.0)
    log to console    To verify by entering the output count as a multiple of 10.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    18
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}      output_count=${row['output_count']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case19

TC - MSME-T3570 (1.0)
    log to console    To verify by entering the output count as not a multiple of 10.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    19
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}      output_count=${row['output_count']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case20


TC - MSME-T3571 (1.0)
    log to console    To verify that the output count and results count are the same.

    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    20
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}      output_count=${row['output_count']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case21


TC - MSME-T3572 (1.0)
    log to console    To verify by entering a single numeric character in the company name.

     ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    21
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}      output_count=${row['output_count']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case22

TC - MSME-T3573 (1.0)
    log to console    To verify by entering a single alphabetic character in the company name.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    22
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}      output_count=${row['output_count']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case23


TC - MSME-T3574 (1.0)
    log to console    To verify by entering a special character in the company name.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    23
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}      output_count=${row['output_count']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case24

TC - MSME-T3575 (1.0)
    log to console    To verify by leaving the output count field empty.

    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    24
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}      output_count=${row['output_count']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case25

TC - MSME-T3576 (1.0)
    log to console    To verify by leaving the output count field as an empty space.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    25
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}      output_count=${row['output_count']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case26

TC - MSME-T3577 (1.0)
    log to console    To verify by entering the output count as 50.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    26
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}      output_count=${row['output_count']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case27


TC - MSME-T3578 (1.0)
    log to console    To verify by entering the output count as more than 51.

    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    27
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}      output_count=${row['output_count']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case28

TC - MSME-T3579 (1.0)
    log to console    To verify by not including the output count key in the input payload.

    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    28
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case29



TC - MSME-T3580 (1.0)
    log to console    To verify by entering an valid client reference number.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    29
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case30


TC - MSME-T3581 (1.0)
    log to console    To verify by entering an invalid client reference number.

    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    30
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}      output_count=${row['output_count']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case31


TC - MSME-T3582 (1.0)
    log to console    To verify by leaving the client reference number field empty.

    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    31
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case32

TC - MSME-T3583 (1.0)
    log to console     To verify by giving an empty space in the client reference number field.

    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    32
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case33


TC - MSME-T3584 (1.0)
    log to console    To verify by giving Additional space at the front and end of the params for client ref num

    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    33
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case34


TC - MSME-T3585 (1.0)
    log to console    To verify that only '_', '-', and '.' characters are accepted in the client reference number.

    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    34
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case35


TC - MSME-T3586 (1.0)
    log to console    To verify by entering a client reference number with more than 45 characters.

    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    35
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case36

TC - MSME-T3587 (1.0)
    log to console    To verify by entering a client ref num as 45 char

    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    36
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case37


TC - MSME-T3588 (1.0)
    log to console    To verify by leaving both the client reference number and company name fields empty.

    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    77
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case38

TC - MSME-T3592 (1.0)
    log to console    To verify with valid authentication.

    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case39


TC - MSME-T3593 (1.0)
    log to console    To verify with invalid authentication.

    ${auth}=    create list    526526315^^    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case40


TC - MSME-T3594 (1.0)
    log to console    To verify using one client's username and another client's password.

    ${auth}=    Create List   52652631504    EA6F34B4B3B618A10CF5C22232290778
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case41


TC - MSME-T3595 (1.0)
    log to console    To verify for a client not having company name validation service.

    ${auth}=    create list    21717999    XiNLt8vtsRXoKWkcelzHIAsBfZx7O9XB
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case41

TC - MSME-T3596 (1.0)
    log to console    To verify by leaving the username empty.
    ${auth}=    create list    ${EMPTY}    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case42


TC - MSME-T3597 (1.0)
    log to console    To verify by leaving the password empty.

    ${auth}=    create list    526526315047    ${EMPTY}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case43


TC - MSME-T3598 (1.0)
    log to console    To verify by leaving both the username and password empty.

    ${auth}=    create list    526526315047    ${EMPTY}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case44


TC - MSME-T3599 (1.0)
    log to console    giving request by Changing the type of reqeust. POST to GET

    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "company_name":"digitap", "client_ref_num":"${random_client_ref_num}"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Get Request    mysession     ${endpoint_url}    json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    #Validations

    Should Be Equal As Strings    ${response.json()['message']}    API running successfully!


TC - MSME-T3602 (1.0)
    log to console    To verify that the success response coming in 5 seconds
    ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    company_name=${row['company_name']}   client_ref_num=${row['client_ref_num']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${start_time}=    Get Time    epoch
    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
    ${end_time}=    Get Time    epoch

    ${elapsed_time_in_seconds}=    Evaluate    ${end_time} - ${start_time}
    ${elapsed_time_in_milliseconds}=    Evaluate    ${elapsed_time_in_seconds} * 1000

    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    Log To Console    Elapsed time: ${elapsed_time_in_milliseconds} ms

    Should Be True    ${elapsed_time_in_milliseconds} < ${MAX_RESPONSE_TIME}    Response time exceeded ${MAX_RESPONSE_TIME} ms
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

TC - MSME-T3603 (1.0)
    log to console    To verify that the failure response coming in 3 seconds
    ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    30
    ${body}=    Create Dictionary    company_name=${row['company_name']}   client_ref_num=${row['client_ref_num']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${start_time}=    Get Time    epoch
    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
    ${end_time}=    Get Time    epoch

    ${elapsed_time_in_seconds}=    Evaluate    ${end_time} - ${start_time}
    ${elapsed_time_in_milliseconds}=    Evaluate    ${elapsed_time_in_seconds} * 1000

    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    Log To Console    Elapsed time: ${elapsed_time_in_milliseconds} ms

    Should Be True    ${elapsed_time_in_milliseconds} < ${MIN_RESPONSE_TIME}    Response time exceeded ${MIN_RESPONSE_TIME} ms
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case31



TC - MSME-T3604 (1.0)
    log to console    To verify if the company name data is being stored correctly.

    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${status_code}=    Set Variable    ${response.status_code}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT company_name FROM kyb_validation.cv_company_name_to_cin_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    company_name = ${row[0]}

    END

TC - MSME-T3605 (1.0)
    log to console    To verify if the client reference number is being stored correctly.
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${status_code}=    Set Variable    ${response.status_code}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT company_name, client_ref_num, http_status_code FROM kyb_validation.cv_company_name_to_cin_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    company_name = ${row[0]}
        Log To Console    client_ref_num = ${row[1]}
    END


TC - MSME-T3607 (1.0)
    log to console    To verify if the total_records_fetched data is being stored correctly.

    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${status_code}=    Set Variable    ${response.status_code}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1
    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT company_name, client_ref_num, total_records_fetched FROM kyb_validation.cv_company_name_to_cin_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    company_name = ${row[0]}
        Log To Console    client_ref_num = ${row[1]}
        Log To Console    total_records_fetched = ${row[2]}

    END

TC - MSME-T3609 (1.0)
    log to console    To verify if the HTTP status code is being stored correctly.
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${status_code}=    Set Variable    ${response.status_code}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT company_name, client_ref_num, http_status_code FROM kyb_validation.cv_company_name_to_cin_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    company_name = ${row[0]}
        Log To Console    client_ref_num = ${row[1]}
        Log To Console    http_status_code = ${row[2]}

    END


TC - MSME-T3610 (1.0)
    LOG TO CONSOLE    To verify if the failure response is being stored correctly.
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    37
    ${body}=    Create Dictionary    company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}     test_scenario=${row['test_scenario']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#   Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${status_code}=    Set Variable    ${response.status_code}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case45

    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT company_name, client_ref_num, http_status_code FROM kyb_validation.cv_company_name_to_cin_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    company_name = ${row[0]}
        Log To Console    client_ref_num = ${row[1]}
        Log To Console    http_status_code = ${row[2]}

    END


TC - MSME-T3611 (1.0)
    LOG TO CONSOLE    To verify if the result code is being stored correctly in the database.

    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${status_code}=    Set Variable    ${response.status_code}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT company_name, client_ref_num, result_code FROM kyb_validation.cv_company_name_to_cin_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    company_name = ${row[0]}
        Log To Console    client_ref_num = ${row[1]}
        Log To Console    result_code = ${row[2]}

    END


TC - MSME-T3612 (1.0)
    log to console    To verify if the failure result code is being stored correctly.

    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    1
    ${body}=    Create Dictionary    company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${status_code}=    Set Variable    ${response.status_code}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case2

    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT company_name, client_ref_num, result_code FROM kyb_validation.cv_company_name_to_cin_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    company_name = ${row[0]}
        Log To Console    client_ref_num = ${row[1]}
        Log To Console    result_code = ${row[2]}

    END


TC - MSME-T3613 (1.0)
    log to console    To verify if the error column is being stored correctly in the database.

    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    37
    ${body}=    Create Dictionary    company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}     test_scenario=${row['test_scenario']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${status_code}=    Set Variable    ${response.status_code}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case45

    Log To Console    ${EMPTY}
    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT company_name, client_ref_num, http_status_code, error FROM kyb_validation.cv_company_name_to_cin_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    company_name = ${row[0]}
        Log To Console    client_ref_num = ${row[1]}
        Log To Console    http_status_code = ${row[2]}
         Log To Console    error = ${row[3]}


    END


TC - MSME-T3614 (1.0)
    log to console    To verify if the TAT is being stored correctly in the database.
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${status_code}=    Set Variable    ${response.status_code}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

     ${sql_query1}=    Set Variable    SELECT company_name, client_ref_num, tat FROM kyb_validation.cv_company_name_to_cin_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    company_name = ${row[0]}
        Log To Console    client_ref_num = ${row[1]}
        Log To Console    tat = ${row[2]}

    END

TC - MSME-T3615 (1.0)
    log to console    To verify that the created_on and updated_on timestamps are updated properly.
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${status_code}=    Set Variable    ${response.status_code}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

     ${sql_query1}=    Set Variable    SELECT company_name, client_ref_num, created_on, updated_on FROM kyb_validation.cv_company_name_to_cin_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    company_name = ${row[0]}
        Log To Console    client_ref_num = ${row[1]}
        Log To Console    created_on = ${row[2]}
        log to console    updated_on = ${row[3]}

    END


TC - MSME-T3616 (1.0)
    log to console    To verify test scenarios with a timeout.

    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    37
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}    test_scenario=${row['test_scenario']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case45

TC - MSME-T3624 (1.0)
     log    verify by entering company name as special char (@) is allowing or not
     ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    38
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case46

TC - MSME-T3625 (1.0)
     log    To verify by entering company name as special char (&) is allowing or not
     ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    39
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}     output_count=${row['output_count']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case47

TC - MSME-T3665 (1.0)
     log    To verify by entering company name start with private
     ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    40
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}     output_count=${row['output_count']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case48

TC - MSME-T3666 (1.0)
     log to console    To verify by entering company name start with pvt
     ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    41
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case49

TC - MSME-T3667 (1.0)
     log to console    To verify by entering company name start with pvt.
     ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    42
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case50

TC - MSME-T3668 (1.0)
     log to console    To verify by entering company name start with limited
     ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    43
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case51

TC - MSME-T3669 (1.0)
     log to console    To verify by entering company name start with ltd

     ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    44
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case52


TC - MSME-T3670 (1.0)
     LOG TO CONSOLE    To verify by entering company name start with ltd.
     ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    45
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case53

TC - MSME-T3671 (1.0)
     log to console    To verify by entering company name start with inc
     ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    46
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}     output_count=${row['output_count']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case54

TC - MSME-T3672 (1.0)
     log to console    To verify by entering company name start with llc
     ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    47
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case55

TC - MSME-T3673 (1.0)
    log to console    To verify by entering company name start with llp
     ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    48
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case56


TC -MSME-T3674 (1.0)
     log to console    To verify by entering company name start with corp.
     ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    49
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}     output_count=${row['output_count']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case57

TC - MSME-T3675 (1.0)
     log to console    To verify by entering company name start with Corporation
     ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    50
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case58

TC - MSME-T3805 (1.0)
     log to console    To verify by entering only special character (~) in the company name
     ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    51
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case59

TC - MSME-T3806 (1.0)
    log to console    To verify by entering only special character (`) in the company name
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    52
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case60

TC - MSME-T3807 (1.0)
    log to console    To verify by entering only special character (!) in the company name
    ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    53
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case61

TC - MSME-T3808 (1.0)
    log to console    To verify by entering only special character (@) in the company name

     ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    54
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case62

TC - MSME-T3809 (1.0)
     log to console    To verify by entering only special character (#) in the company name
     ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    55
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case63

TC - MSME-T3810 (1.0)
    log to console    To verify by entering only special character ($) in the company name
    ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    56
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case64


TC - MSME-T3811 (1.0)
    log to console    To verify by entering only special character (%) in the company name
    ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    57
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case65


TC - MSME-T3812 (1.0)
    log to console    To verify by entering only special character (^) in the company name
    ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    58
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case66



TC - MSME-T3813 (1.0)
     log to console    To verify by entering only special character (&) in the company name

     ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    59
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case67

TC - MSME-T3814 (1.0)
    log to console    To verify by entering only special character (*) in the company name

    ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    60
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case68


TC - MSME-T3815 (1.0)
    log to console    To verify by entering only special character (() in the company name

   ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    61
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case69


TC - MSME-T3816 (1.0)
    log to console    To verify by entering only special character ()) in the company name

    ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    62
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case70



TC - MSME-T3817 (1.0)
    log to console    To verify by entering only special character (-) in the company name

    ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    63
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case71


TC - MSME-T3818 (1.0)
    log to console    To verify by entering only special character (_) in the company name
    ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    64
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case72


TC - MSME-T3819 (1.0)
     log to console    To verify by entering mixed of alpha char and spcial char (~) in the company name
     ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    65
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case73


TC - MSME-T3820 (1.0)
    log to console    To verify by entering mixed of alpha char and spcial char (!) in the company name

     ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    66
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case74




TC - MSME-T3821 (1.0)
    log to console    To verify by entering mixed of alpha char and spcial char (#) in the company name

     ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    67
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case75



TC - MSME-T3822 (1.0)
    log to console    To verify by entering mixed of alpha char and spcial char ($) in the company name

     ${auth}=    Create List    ${client-username}    ${client-password}
     ${test_data}=    Read Test Data From CSV    ${file_path}
     ${row}=    Get From List    ${test_data}    68
     ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
     Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case76



TC - MSME-T3823 (1.0)
    log to console    To verify by entering mixed of alpha char and spcial char (%) in the company name

    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    69
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case77



TC - MSME-T3824 (1.0)
    log to console    To verify by entering mixed of alpha char and spcial char (^) in the company name

    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    70
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case78



TC - MSME-T3825 (1.0)
    log to console    To verify by entering mixed of alpha char and spcial char (*) in the company name

    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    71
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case79


TC - MSME-T3826 (1.0)
    log to console    To verify by entering mixed of alpha char and spcial char (() in the company name
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    72
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case80


TC - MSME-T3827 (1.0)
    log to console    To verify by entering mixed of alpha char and spcial char ()) in the company name
     ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    73
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case81


TC - MSME-T3828 (1.0)
    log to console    To verify by entering mixed of alpha char and spcial char (_) in the company name
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    74
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case82



TC - MSME-T3829 (1.0)
    log to console    To verify by entering mixed of alpha char and all the spcial char (~!@#$%^&*()) in the company name
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    75
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case83



TC - MSME-T3830 (1.0)
    log to console    To verify by entering multiple words as the company name.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    76
    ${body}=    Create Dictionary   company_name=${row['company_name']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case84
