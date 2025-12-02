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
${endpoint_url}=    /validation/kyb/v1/fssai_validation
${file_path}=   C:\\Users\\Aishwarya\\PycharmProjects\\APIAutomation\\data\\fssai.csv
${client-username}=    526526315047
${client-password}=    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
${MAX_RESPONSE_TIME}    5000  # in milliseconds
${MIN_RESPONSE_TIME}    3000    # in milliseconds
${json_schema_file}=   C:\\Users\\Aishwarya\\PycharmProjects\\APIAutomation\\Json_schema\\FSSAI\\fssai.json


*** Keywords ***
Read Test Data From CSV
    [Arguments]    ${file_path}
    ${test_data}=    Create List
    ${file_content}=    Get File    ${file_path}
    ${lines}=    Split To Lines    ${file_content}
    FOR    ${line}    IN    @{lines}[1:]    # Skip the header line
        ${columns}=    Split String    ${line}    separator=,
        ${data}=    Create Dictionary    license_number=${columns[1]}    client_ref_num=${columns[2]}     test_scenario=${columns[3]}
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
MSME-T8548 (1.0)
    log to console    To verify entering valid  license_number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

MSME-T8549 (1.0)
    Log To Console   To verify entering invalid license_number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    1
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case2

MSME-T8550 (1.0)
    log to console    To verify by entering an license number that is not found
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    2
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case3

MSME-T8551 (1.0)
    Log To Console   To verify entering valid registration license_number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    3
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case4

MSME-T8552 (1.0)
    Log To Console   To verify entering valid State license_number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    4
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case5


MSME-T8553 (1.0)
    Log To Console   To verify entering valid Central license_number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    5
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case6

MSME-T8554 (1.0)
    log to console    To verify by entering less than 14 char license_number field
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    6
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case7

MSME-T8555 (1.0)
    log to console    To verify by entering more than 14 char license_number field
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    7
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case8


MSME-T8556 (1.0)
    log to console    To verify license_number field left empty
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    8
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case9

MSME-T8557 (1.0)
    log to console    To verify license_number with empty space within
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    9
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case10

MSME-T8558 (1.0)
    log to console    To verify additional space at the end of the license_number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    10
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case11


MSME-T8559 (1.0) 
    Log To Console   To verify additional space at the beginning of the license_number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    11
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case12

MSME-T8560 (1.0)
    log to console    To verify license_number containing special characters
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    12
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case13


MSME-T8561 (1.0)
    Log To Console    To verify by entering the license_number as mixed of all numeric, alpha and special char
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    13
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case14


MSME-T8562 (1.0)
    Log To Console    To verify license_number with only alphabetic characters
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    14
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case15


MSME-T8564 (1.0)
    Log To Console    To verify entering license_number for case 101
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    15
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case16


MSME-T8565 (1.0)
    Log To Console  To verify entering license_number for case 103
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    16
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case17


MSME-T8566 (1.0)
    Log To Console   To verify if the company_name key appears in the API response

    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    17
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case18


MSME-T8567 (1.0)
    Log To Console    To verify if the address key appears in the API response
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    18
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case19


MSME-T8568 (1.0)
    Log To Console    To verify that the input license number and the output license number in the API response are the same.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    19
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case20


MSME-T8569 (1.0)
    Log To Console    To verify if the vehicle validity_status key appears in the API response
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    20
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case21


MSME-T8570 (1.0)
    Log To Console    To verify if the vehicle products_sold key appears in the API response
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    21
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case22


MSME-T8571 (1.0)
    Log To Console    To verify changing the FSSAI key to an invalid name
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    22
    ${body}=    Create Dictionary   license_number11=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case23


MSME-T8572 (1.0)
    Log To Console    To verify using a different API payload for the FSAAI number API
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    23
    ${body}=    Create Dictionary   pan=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case24


MSME-T8573 (1.0)
    Log To Console   To verify by entering valid client reference number

    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    24
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case25

MSME-T8574 (1.0)
    Log To Console     To verify by entering entry of an invalid client reference number.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    25
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case26


MSME-T8575 (1.0)
    Log To Console     To verify by entering client reference number field left empty.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    26
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case27


MSME-T8576 (1.0)
    Log To Console   To verify by entering client reference number entry with empty space.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    27
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case28


MSME-T8577 (1.0)
    Log To Console   To verify by entering client reference number with additional spaces at the beginning
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    28
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case29

MSME-T8578 (1.0)
    Log To Console   To verify by entering client reference number with additional spaces at the end.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    29
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case30


MSME-T8579 (1.0)
    Log To Console   To verify by entering only "_", "-", and "." are accepted in the client reference number.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    30
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case31


MSME-T8580 (1.0)
    Log To Console  To verify by enetring client key as invalid name
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    31
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num123=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case32

MSME-T8581 (1.0)
    Log To Console  To verify by entering client reference number with more than 45 characters.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    32
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case33


MSME-T8582 (1.0)
    Log To Console   To verify by entering client reference number with exactly 45 characters.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    33
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case34


MSME-T8583 (1.0)
    Log To Console  To verify by entering both client reference number and license_number fields left empty.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    34
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case35


# ************************************** DB test cases ************************************

MSME-T8584 (1.0),MSME-T8585 (1.0),MSME-T8586 (1.0),MSME-T8587 (1.0),MSME-T8588 (1.0),MSME-T8589 (1.0),MSME-T8590 (1.0), MSME-T8591 (1.0), MSME-T8592 (1.0),MSME-T8594 (1.0),MSME-T8596 (1.0),MSME-T8597 (1.0),MSME-T8598 (1.0),MSME-T8599 (1.0)
     Log To Console   Verify the entid,client_id,service_id,request payload,license_number,client_ref_num,company_details,products_details,http_response_code,result_code,response payload,tat,error,created_on and updated_on is stored or not

    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT ent_id, client_id, service_id, request_payload, license_number, client_ref_num, company_details, products_details, response_payload, http_response_code, result_code, error, tat, created_on, updated_on FROM kyb_validation.kyb_fssai_validation_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    ent_id = ${row[0]}
        Log To Console    client_id = ${row[1]}
        Log To Console    service_id = ${row[2]}
        Log To Console    request_payload = ${row[3]}
        Log To Console    license_number = ${row[4]}
        Log To Console    client_ref_num = ${row[5]}
        Log To Console    company_details = ${row[6]}
        Log To Console    products_details = ${row[7]}
        Log To Console    response_payload = ${row[8]}
        Log To Console    http_response_code = ${row[9]}
        Log To Console    result_code = ${row[10]}
        Log To Console    error = ${row[11]}
        Log To Console    tat = ${row[12]}
        Log To Console    created_on = ${row[13]}
        Log To Console    updated_on = ${row[14]}

    END

MSME-T8593 (1.0)
     Log To Console  Verify the failure http_response_code is stored or not
     ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    35
    ${body}=    Create Dictionary    license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}     test_scenario=${row['test_scenario']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${status_code}=    Set Variable    ${response.status_code}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case36

    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT http_response_code FROM kyb_validation.kyb_fssai_validation_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    http_response_code = ${row[0]}


    END


MSME-T8595 (1.0)
    Log To Console  Verify the failure result_code is stored or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    2
    ${body}=    Create Dictionary    license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${status_code}=    Set Variable    ${response.status_code}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case3

    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT result_code FROM kyb_validation.kyb_fssai_validation_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    result_code = ${row[0]}

    END
# *********************************************************************************************************************

MSME-T8611 (1.0)
    log to console    Verify successful response received within 5 seconds.
    ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    license_number=${row['license_number']}   client_ref_num=${row['client_ref_num']}
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


MSME-T8612 (1.0)
    log to console    Verify failure response received within 3 seconds.
    ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    2
    ${body}=    Create Dictionary    license_number=${row['license_number']}   client_ref_num=${row['client_ref_num']}
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

MSME-T8613 (1.0)
    Log To Console  To verify by entering the test Scenarios with timeout
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    35
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}      test_scenario=${row['test_scenario']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case36


MSME-T8630 (1.0)
    log to console    To verify by changing the type of request POST to GET

    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "license_number":"22418545000561", "client_ref_num":"${random_client_ref_num}"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Get Request    mysession     ${endpoint_url}    json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    #Validations

    Should Be Equal As Strings    ${response.json()['message']}    API running successfully



MSME-T8633 (1.0)
    log to console    To verify by changing the https to http
    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    http://svcstage.digitap.work    auth=${auth}    verify=true

    # Read test data from CSV file
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0    # Select the first row

    ${license_number}=    Get From Dictionary    ${row}    license_number
    ${client_ref_num}=    Get From Dictionary    ${row}    client_ref_num


    ${body}=    create dictionary    license_number=${license_number}    client_ref_num=${client_ref_num}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Get Request    mysession     ${endpoint_url}   json=${body}    headers=${header}

    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    # Validations
    Should Be Equal As Strings    ${response.status_code}    503

MSME-T8658 (1.0)
    log to console    To verify by enterng valid client user name and password
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

MSME-T8659 (1.0)
    log to console    To verify by entering invalid client user name
    ${auth}=    Create List     526526315^^    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case37


MSME-T8660 (1.0)
    log to console    To verify by leaving client user name as empty
    ${auth}=    Create List     ${empty}    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case38


MSME-T8661 (1.0)
    log to console    To verify by entering invalid client password
    ${auth}=    Create List     ${client-username}    BI9WnuOcxLBKKgPEB4qtLdA$$$
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case39

MSME-T8662 (1.0)
    log to console    To verify by leaving client password as empty
    ${auth}=    Create List     ${client-username}    ${empty}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case40


MSME-T8663 (1.0)
    log to console    To verify by entering one client user name and other client password
    ${auth}=    Create List     52652631504    EA6F34B4B3B618A10CF5C22232290778
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case41


MSME-T8664 (1.0)
    log to console    To verify by entering client id which dont have FSSAI service
    ${auth}=    Create List     21717999    XiNLt8vtsRXoKWkcelzHIAsBfZx7O9XB
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case42

MSME-T8665 (1.0)
    log to console    To verify by leaving both the username and password empty.
    ${auth}=    Create List     ${empty}    ${empty}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   license_number=${row['license_number']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case43





