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
${endpoint_url}=    /cv/v1/coi
${file_path}=   C:\\Users\\Aishwarya\\PycharmProjects\\APIAutomation\\data\\COI_data.csv
${client-username}=    526526315047
${client-password}=    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
${MAX_RESPONSE_TIME}    15000  # in milliseconds
${MIN_RESPONSE_TIME}    3000    # in milliseconds
${json_schema_file}=   C:\\Users\\Aishwarya\\PycharmProjects\\APIAutomation\\Json_schema\\COI services\\Json_schema COI basic.json


*** Keywords ***
Read Test Data From CSV
    [Arguments]    ${file_path}
    ${test_data}=    Create List
    ${file_content}=    Get File    ${file_path}
    ${lines}=    Split To Lines    ${file_content}
    FOR    ${line}    IN    @{lines}[1:]    # Skip the header line
        ${columns}=    Split String    ${line}    separator=,
        ${data}=    Create Dictionary    cin=${columns[1]}    client_ref_num=${columns[2]}    company_id=${columns[3]}       test_scenario=${columns[4]}
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
    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    Log To Console    ${EMPTY}
    Log To Console    ${EMPTY}

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
MSME-T4562 (1.0)
    log to console    To verify by entering the valid CIN number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

MSME-T4563 (1.0)
    log to console    To verify by entering the valid CIN number which not found
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    1
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case2

MSME-T4564 (1.0)
    log to console    To verify by entering the invalid CIN number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    2
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case3

MSME-T4565 (1.0)
    log to console    To verify by entering other then CIN number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    3
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case4

MSME-T4566 (1.0)
    log to console   To verify by entering only special char in the CIN number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    4
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case5


MSME-T4567 (1.0)
    log to console     To verify by entering only numeric char in the CIN number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    5
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case6

MSME-T4568 (1.0)
    log to console    To verify by entering only alpha char in the CIN number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    6
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case7

MSME-T4569 (1.0)
    log to console    To verify by entering mixed of alpha, numeric, special char in the CIN number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    7
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case8


MSME-T4570 (1.0)
    log to console    To verify by leaving the COI field as empty
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    8
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case9

MSME-T4571 (1.0)
    log to console    To verify by leaving the COI field as empty space
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    9
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case10

MSME-T4572 (1.0)
    log to console    To verify by giving Additional space at the end of the params for cin num
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    10
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case11


MSME-T4573 (1.0)
    log to console    To verify by giving Additional space at the front of the params for cin ref num
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    11
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case12

MSME-T4574 (1.0)
    log to console    To verify by entering the deactivated company CIN number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    12
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case13


MSME-T4575 (1.0)
    log to console    To verify by entering Strike Off CIN number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    13
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case14


MSME-T4576 (1.0)
    log to console    To verify by entering Under Process of Striking Off CIN number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    14
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case15


MSME-T4577 (1.0)
    log to console    To verify by entering Converted to LLP CIN number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    15
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case16


MSME-T4578 (1.0)
    log to console    To verify entering a valid FCIN number in the company_id field.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    16
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}     company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case17


MSME-T4579 (1.0)
    log to console    To verify entering a valid FCRN number in the company_id field.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    17
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}     company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case18

MSME-T4580 (1.0)
    log to console    To verify entering a valid LLPIN number in the company_id field.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    18
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}        company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case19


MSME-T4581 (1.0)
    log to console    To verify entering an invalid FCIN number in the company_id field.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    19
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}      company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case20


MSME-T4582 (1.0)
    log to console    To verify entering an invalid FCRN number in the company_id field.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    20
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}     company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case21


MSME-T4583 (1.0)
    log to console    To verify entering an invalid LLPIN number in the company_id field.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    21
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}    company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case22

MSME-T4584 (1.0)
    log to console    To verify entering both a valid CIN and a valid company_id in the payload.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    22
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}    company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case23


MSME-T4585 (1.0)
    log to console    To verify entering both a invalid CIN and a invalid company_id in the payload.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    23
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}    company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case24


MSME-T4586 (1.0)
    log to console    To verify entering both a valid CIN and a invalid company_id in the payload.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    24
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}    company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case25

MSME-T4587 (1.0)
    log to console    To verify entering both a invalid CIN and a valid company_id in the payload.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    25
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}    company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case26


MSME-T4588 (1.0)
    log to console    To verify entering a valid CIN and leaving the company_id field empty.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    26
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}    company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case27

MSME-T4589 (1.0)
    log to console    To verify leaving the CIN field empty and entering a valid company_id.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    27
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}    company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case28


MSME-T4590 (1.0)
    log to console    To verify entering both company_id values in the CIN field.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    28
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}    company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case29

MSME-T4591 (1.0)
    log to console    To verify entering the CIN field in the company_id and leaving the company_id field empty.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    29
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}      company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case30


MSME-T4592 (1.0)
    log to console    To verify leaving the CIN field empty and entering the CIN value in the company id field.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    30
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}     company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case31


MSME-T4593 (1.0)
    log to console    To verify leaving both the CIN and company_id fields as empty strings.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    31
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}      company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case32

MSME-T4594 (1.0)
    log to console    To verify entering a valid company_id and numeric characters in the CIN field.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    32
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}      company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case33


MSME-T4595 (1.0)
    log to console    To verify entering a valid company_id and special characters in the CIN field.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    33
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}      company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case34


MSME-T4596 (1.0)
    log to console    To verify entering a valid company_id and alphabetic characters in the CIN field.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    34
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}        company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case35


MSME-T4597 (1.0)
    log to console    To verify entering a valid company_id and a mix of special, alphabetic, and numeric characters in the CIN field.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    35
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}        company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case36

MSME-T4598 (1.0)
    log to console    To verify entering a valid CIN and numeric characters in the company_id field.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    36
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}        company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case37


MSME-T4599 (1.0)
    log to console    To verify entering a valid CIN and special characters in the company_id field.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    37
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}        company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case38

MSME-T4600 (1.0)
    log to console    To verify entering a valid CIN and alphabetic characters in the company_id field.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    38
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}        company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case39


MSME-T4601 (1.0)
    log to console    To verify entering a valid CIN and a mix of special, alphabetic, and numeric characters in the company_id field.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    39
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}        company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case40


MSME-T4602 (1.0)
    log to console    To verify by not including the cin key in the input payload.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    40
    ${body}=    Create Dictionary       client_ref_num=${row['client_ref_num']}        company_id=${row['company_id']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case41


MSME-T4603 (1.0)
    log to console    To verify by not including the company id key in the input payload.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    41
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case42

MSME-T4604 (1.0)
    log to console    To check the company_id key and value in the response.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    42
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case43

MSME-T4605 (1.0)
    log to console    To verify by entering an valid client reference number.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    43
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case44

MSME-T4606 (1.0)
    log to console    To verify by entering an invalid client reference number.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    44
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case45

MSME-T4607 (1.0)
    log to console    To verify by leaving the client reference number field empty.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    45
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case46

MSME-T4608 (1.0)
    log to console    To verify by giving an empty space in the client reference number field.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    46
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case47

MSME-T4609 (1.0)
    log to console    To verify by giving Additional space at the end of the params for client ref num
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    47
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case48

MSME-T4610 (1.0)
    log to console    To verify by giving Additional space at the front of the params for client ref num
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    48s
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case49


MSME-T4611 (1.0)
    log to console    To verify that only '_', '-', and '.' characters are accepted in the client reference number.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    49
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case50

MSME-T4612 (1.0)
    log to console    To verify by entering a client reference number with more than 45 characters.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    50
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case51

MSME-T4613 (1.0)
    log to console    To verify by entering a client ref num as 45 char
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    51
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case52


MSME-T4617 (1.0)
    log to console    Verify successful response received within 5 seconds.
    ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    cin=${row['cin']}   client_ref_num=${row['client_ref_num']}
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


MSME-T4618 (1.0)
    log to console    Verify failure response received within 3 seconds.
    ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    2
    ${body}=    Create Dictionary    cin=${row['cin']}   client_ref_num=${row['client_ref_num']}
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
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case3


MSME-T4619 (1.0)
    log to console    To verify by changing the type of request POST to GET

    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "cin":"U74999KA2016PTC098609", "client_ref_num":"${random_client_ref_num}"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Get Request    mysession     ${endpoint_url}    json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    #Validations

    Should Be Equal As Strings    ${response.json()['message']}    API running successfully!


MSME-T4622 (1.0)
    log to console    To verify by changing the https to http
    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    http://svcstage.digitap.work    auth=${auth}    verify=true

    # Read test data from CSV file
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0    # Select the first row

    ${cin}=    Get From Dictionary    ${row}    cin
    ${client_ref_num}=    Get From Dictionary    ${row}    client_ref_num


    ${body}=    create dictionary    cin=${cin}    client_ref_num=${client_ref_num}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Get Request    mysession     ${endpoint_url}   json=${body}    headers=${header}

    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    # Validations
    Should Be Equal As Strings    ${response.status_code}    503

MSME-T4623 (1.0)
    log to console    To verify by enterng valid client user name and password
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case53

MSME-T4624 (1.0)
    log to console    To verify by entering invalid client user name
    ${auth}=    Create List     526526315^^    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case54


MSME-T4625 (1.0)
    log to console    To verify by leaving client user name as empty
    ${auth}=    Create List     ${empty}    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case55


MSME-T4626 (1.0)
    log to console    To verify by entering invalid client password
    ${auth}=    Create List     ${client-username}    BI9WnuOcxLBKKgPEB4qtLdA$$$
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case56

MSME-T4627 (1.0)
    log to console    To verify by leaving client password as empty
    ${auth}=    Create List     ${client-username}    ${empty}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case57


MSME-T4628 (1.0)
    log to console    To verify by entering one client user name and other client password
    ${auth}=    Create List     52652631504    EA6F34B4B3B618A10CF5C22232290778
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case58


MSME-T4629 (1.0)
    log to console    To verify by entering client id which dont have COI service
    ${auth}=    Create List     21717999    XiNLt8vtsRXoKWkcelzHIAsBfZx7O9XB
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case59


MSME-T4630 (1.0)
    log to console    To verify by leaving both the username and password empty.
    ${auth}=    Create List     ${empty}    ${empty}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case60


MSME-T4631 (1.0)
    log to console    Verify the entid and client_id are stored or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT ent_id, client_id FROM kyb_validation.cv_coi_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    ent_id = ${row[0]}
        Log To Console    client_id = ${row[1]}

    END


MSME-T4632 (1.0)
    log to console    Verify the service id and company_id are stored or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    18
    ${body}=    Create Dictionary    company_id=${row['company_id']}    client_ref_num=${row['client_ref_num']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${status_code}=    Set Variable    ${response.status_code}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case19

    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT service_id, company_id FROM kyb_validation.cv_coi_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    service_id = ${row[0]}
        Log To Console    company_id = ${row[1]}

    END

MSME-T4633 (1.0)
    log to console    Verify the cin is stored or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT cin FROM kyb_validation.cv_coi_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    cin = ${row[0]}


    END


MSME-T4634 (1.0)
    log to console    Verify the client_ref_num is stored or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT client_ref_num FROM kyb_validation.cv_coi_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    client_ref_num = ${row[0]}


    END

MSME-T4635 (1.0)
    log to console    Verify the request_payload is stored or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT request_payload FROM kyb_validation.cv_coi_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    request_payload = ${row[0]}


    END

MSME-T4636 (1.0)
    log to console    Verify the response_payload is stored or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT response_payload FROM kyb_validation.cv_coi_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    response_payload = ${row[0]}


    END

MSME-T4637 (1.0)
    log to console    Verify the contacts_found is stored or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT contacts_found FROM kyb_validation.cv_coi_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    contacts_found = ${row[0]}


    END

MSME-T4638 (1.0)
    log to console    Verify the pan_found is stored or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT pan_found FROM kyb_validation.cv_coi_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    pan_found = ${row[0]}


    END


MSME-T4639 (1.0)
    log to console    Verify the website_response is stored or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT website_response FROM kyb_validation.cv_coi_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    website_response = ${row[0]}


    END


MSME-T4640 (1.0)
    log to console    Verify the request_uuid is stored or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT request_uuid FROM kyb_validation.cv_coi_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    request_uuid = ${row[0]}


    END


MSME-T4641 (1.0)
    log to console    Verify the Success http_status_code is stored or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT http_status_code FROM kyb_validation.cv_coi_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    http_status_code = ${row[0]}


    END


MSME-T4642 (1.0)
    log to console    Verify the failure http_response_code is stored or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    52
    ${body}=    Create Dictionary    cin=${row['cin']}    client_ref_num=${row['client_ref_num']}      test_scenario=${row['test_scenario']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${status_code}=    Set Variable    ${response.status_code}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case61

    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT http_status_code FROM kyb_validation.cv_coi_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    http_status_code = ${row[0]}

    END


MSME-T4643 (1.0)
    log to console    Verify the Success result_code is stored or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT result_code FROM kyb_validation.cv_coi_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    result_code = ${row[0]}

    END


MSME-T4644 (1.0)
    log to console    Verify the failure result_code is stored or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    1
    ${body}=    Create Dictionary    cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT result_code FROM kyb_validation.cv_coi_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    result_code = ${row[0]}

    END


MSME-T4645 (1.0)
    log to console    Verify the error is stored or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    1
    ${body}=    Create Dictionary    cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT error FROM kyb_validation.cv_coi_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    error = ${row[0]}

    END


MSME-T4646 (1.0)
    log to console    Verify the tat is stored or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT tat FROM kyb_validation.cv_coi_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    tat = ${row[0]}

    END


MSME-T4647 (1.0)
    log to console    Verify that the created_on and updated_on are updated properly.
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    cin=${row['cin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT created_on, updated_on FROM kyb_validation.cv_coi_api where http_status_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    created_on = ${row[0]}
        Log To Console    updated_on = ${row[0]}

    END


MSME-T4650 (1.0)
    log to console    To verify the test Scenarios with time out
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    52
    ${body}=    Create Dictionary   cin=${row['cin']}    client_ref_num=${row['client_ref_num']}      test_scenario=${row['test_scenario']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case61



