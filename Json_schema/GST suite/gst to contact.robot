*** Settings ***
Library    RequestsLibrary
Library    CSVLibrary
Library    Collections
Library    OperatingSystem
Library    String
Library    DatabaseLibrary
Library    DateTime
Library    JSONLibrary
Library    random


Suite Setup     Connect To Database     pymysql     ${DB_Name}      ${DB_user}      ${DB_pass}      ${DB_host}     ${DB_port}
Suite Teardown      Disconnect From Database

*** Variables ***
${DB_Name}        validation
${DB_user}        qa.aishwarya
${DB_pass}        PYvHHoNKAbhYUhF
${DB_host}        dev-db.chjy1zjdr74q.ap-south-1.rds.amazonaws.com
${DB_port}        3306
${base_url}=    https://svcdemo.digitap.work
${endpoint_url}=    /validation/kyb/v1/gst/gst_to_contacts
${file_path}=    C:\\Users\\Aishwarya\\PycharmProjects\\APIAutomation\\data\\GSTin.csv
${client-username}=    740513625625
${client-password}=    aQBBu5Gs36AuLrf9O1WKSxahinWjksTT
${MAX_RESPONSE_TIME}    5000  # in milliseconds
${MIN_RESPONSE_TIME}    3000    # in milliseconds
${json_schema_file}=    C:\\Users\\Aishwarya\\PycharmProjects\\APIAutomation\\Json_schema\\GST suite\\gst to contact json schema.json


*** Keywords ***
Read Test Data From CSV
    [Arguments]    ${file_path}
    ${test_data}=    Create List
    ${file_content}=    Get File    ${file_path}
    ${lines}=    Split To Lines    ${file_content}
    FOR    ${line}    IN    @{lines}[1:]    # Skip the header line
        ${columns}=    Split String    ${line}    separator=,
        ${data}=    Create Dictionary    gstin=${columns[1]}    client_ref_num=${columns[2]}     test_scenario=${columns[3]}
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
TC - MSME-T1557 (1.0)
    Log To Console    To verify valid gstin number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

TC - MSME-T1558 (1.0)
    log to console    To verify by entering in-valid GST
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    1
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case2


TC - MSME-T1559 (1.0)
    log to console    To verify by Leaving the GST as empty
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    2
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case3


TC - MSME-T1560 (1.0)
    log to console    To verify by giving empty space GST number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    3
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case4

TC - MSME-T1561 (1.0)
    log to console    To verify by giving the addtional space at the end of the GST number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    4
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case5

TC - MSME-T1562 (1.0)
    log to console    To verify by giving the addtional space at the middle of the GST number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    5
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case6


TC - MSME-T1563 (1.0)
    log to console    To verify by entering the GST numbers in small characters(alphabets)
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    6
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case7


TC - MSME-T1564 (1.0)
    log to console    To verify by entering the GST number as single numeric char
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    7
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case8


TC - MSME-T1565 (1.0)
    log to console    To verify by entering the GST number as single alpha char

    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    8
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case9


#TC - MSME-T1567 (1.0)
#    log to console    To verify no records GST number
#    ${auth}=    Create List    ${client-username}    ${client-password}
#    ${test_data}=    Read Test Data From CSV    ${file_path}
#    ${row}=    Get From List    ${test_data}    9
#    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
#    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case10


TC - MSME-T1568 (1.0)
    log to console    To verify by entering the GST number as special char
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    10
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case11


TC - MSME-T1569 (1.0)
    log to console    To verify by entering the GST number mixed of numeric special char
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    11
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case12


TC - MSME-T1570 (1.0)
    log to console    To verify by entering the GST number mixed of alpha special char
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    12
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case13

TC - MSME-T1571 (1.0)
    log to console    To verify by entering Valid client ref number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    13
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case14


TC - MSME-T1572 (1.0)
    log to console    To verify by entering invalid Client ref number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    14
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case15


TC - MSME-T1573 (1.0)
    log to console    To verify by leaving the client ref number as empty
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    15
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case16

TC - MSME-T1574 (1.0)
    log to console    To verify by entering client ref number more than 100 char
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    16
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case17


TC - MSME-T1575 (1.0)
    log to console    To verify by entering client ref number as 100 char
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    17
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case18

TC - MSME-T1576 (1.0)
    log to console    To verify by giving empty space in the client ref number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    18
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case19

TC - MSME-T1593 (1.0)
    log to console    To verify by giving valid client username and client password
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case20

TC - MSME-T1594 (1.0)
    log to console    To verify by entering the invalid client user name
    ${auth}=    Create List     526526315^^    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case21


TC - MSME-T1595 (1.0)
    log to console    To verify by entering the invalid client password
    ${auth}=    Create List     526526315047     BI9WnuOcxLBKKgPEB4qtLdADGc9PH44
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case22

TC - MSME-T1596 (1.0)
    log to console    To verify by leaving client user name as empty
    ${auth}=    Create List    ${empty}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case23


TC - MSME-T1597 (1.0)
    log to console    To verify by leaving client password as empty
    ${auth}=    Create List    526526315047    ${empty}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case24


TC - MSME-T1598 (1.0)
    log to console    To verify by leaving client user name and password empty
    ${auth}=    Create List    ${empty}   ${empty}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case25


TC - MSME-T1599 (1.0)
    log to console    To verify by entering client id which dont have gstin service
    ${auth}=    Create List    21717999    XiNLt8vtsRXoKWkcelzHIAsBfZx7O9XB
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case26


TC - MSME-T1600 (1.0)
    log to console    giving request by Changing the type of reqeust. POST to GET
    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "gstin":"33AAZPN3164F1ZF", "client_ref_num":"${random_client_ref_num}"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Get Request    mysession     ${endpoint_url}    json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    #Validations

    Should Be Equal As Strings    ${response.json()['message']}    API RUNNING SUCCESSFULLY


TC - MSME-T1603 (1.0)
    log to console    success response is coming within 5 seconds or not
     ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}   client_ref_num=${row['client_ref_num']}
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

TC - MSME-T1604 (1.0)
    log to console    To verify that the failure response coming in 3 seconds
    ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    1
    ${body}=    Create Dictionary    gstin=${row['gstin']}   client_ref_num=${row['client_ref_num']}
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
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case2



TC - MSME-T1606 (1.0)
    log to console    To verify by Giving the client ref number in GST key
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    19
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case27


TC - MSME-T1607 (1.0)
    log to console    To verify by Giving the GST in client ref number key
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    20
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case28


TC - MSME-T1608 (1.0)
    log to console    To verify by Changing the GST key in invalid name
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    21
    ${body}=    Create Dictionary    gstin22=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case29

TC - MSME-T1609 (1.0)
    log to console    To verify by Changing the client ref number key in invalid name
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    22
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num44=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case30

TC - MSME-T1611 (1.0)
    log to console    To verify the http response code 200 is storing or not in the DB
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query}=    Set Variable    SELECT http_response_code FROM validation.kyb_gst_to_contacts_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
            Log To Console    http_response_code = ${row[0]}

    END

TC - MSME-T1612 (1.0)
    log to console    To verify the result code is storing or not in the DB
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query}=    Set Variable    SELECT result_code FROM validation.kyb_gst_to_contacts_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;
    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}

        Log To Console    result_code = ${row[0]}

    END


TC - MSME-T1613 (1.0)
    log to console    To verify the failure http_response_code is storing or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}     26
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}     test_scenario=${row['test_scenario']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true
    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${status_code}=    Set Variable    ${response.status_code}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case34

    # Prepare SQL Query
    ${sql_query}=    Set Variable    SELECT result_code FROM validation.kyb_gst_to_contacts_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;
    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}

        Log To Console    result_code = ${row[0]}

    END



TC - MSME-T1615 (1.0)
    log to console    To verify created on is updating properly or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query}=    Set Variable    SELECT created_on,updated_on FROM validation.kyb_gst_to_contacts_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;
    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}

        Log To Console    created_on = ${row[0]}
        Log To Console    updated_on = ${row[1]}

    END


TC - MSME-T1616 (1.0)
    log to console    To verify gstin storing or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query}=    Set Variable    SELECT gstin FROM validation.kyb_gst_to_contacts_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;
    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}

        Log To Console    gstin = ${row[0]}

    END


TC - MSME-T1617 (1.0)
    log to console    To verify client_ref_num is storing or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query}=    Set Variable    SELECT client_ref_num FROM validation.kyb_gst_to_contacts_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;
    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}

        Log To Console    client_ref_num = ${row[0]}

    END


TC - MSME-T1618 (1.0)
    log to console    To verify response_payload is stroing in json format or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query}=    Set Variable    SELECT response_payload FROM validation.kyb_gst_to_contacts_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;
    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}

        Log To Console    response_payload = ${row[0]}

    END


TC - MSME-T1619 (1.0)
    log to console    To verify tat is storing or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query}=    Set Variable    SELECT tat FROM validation.kyb_gst_to_contacts_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;
    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}

        Log To Console    tat = ${row[0]}

    END

TC - MSME-T1620 (1.0)
    log to console    To verify ent_id is storing or not
     ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query}=    Set Variable    SELECT ent_id FROM validation.kyb_gst_to_contacts_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;
    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}

        Log To Console    ent_id = ${row[0]}

    END

TC - MSME-T1621 (1.0)
    log to console    To verify error column is storing or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query}=    Set Variable    SELECT error FROM validation.kyb_gst_to_contacts_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;
    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}

        Log To Console    error = ${row[0]}

    END

TC - MSME-T1622 (1.0)
    log to console    To verify request_payload storing or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query}=    Set Variable    SELECT request_payload FROM validation.kyb_gst_to_contacts_provider_log where http_status_code='${status_code}' order by id desc limit 1;
    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}

        Log To Console    request_payload = ${row[0]}

    END

TC - MSME-T1623 (1.0)
    log to console    To verify vendor_tat storing or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query}=    Set Variable    SELECT vendor_tat FROM validation.kyb_gst_to_contacts_provider_log where http_status_code='${status_code}' order by id desc limit 1;
    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}

        Log To Console    vendor_tat = ${row[0]}

    END


TC - MSME-T1624 (1.0)
    log to console    To verify response_payload is stroing in json format or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query}=    Set Variable    SELECT response_payload FROM validation.kyb_gst_to_contacts_provider_log where http_status_code='${status_code}' order by id desc limit 1;
    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}

        Log To Console    response_payload = ${row[0]}

    END

TC - MSME-T1625 (1.0)
    log to console    To verify The http_status_code 200 is storing or not in the DB
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query}=    Set Variable    SELECT http_status_code FROM validation.kyb_gst_to_contacts_provider_log where http_status_code='${status_code}' order by id desc limit 1;
    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}

        Log To Console    http_status_code = ${row[0]}

    END

TC - MSME-T1626 (1.0)
    log to console    To verify provider storing or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query}=    Set Variable    SELECT provider FROM validation.kyb_gst_to_contacts_provider_log where http_status_code='${status_code}' order by id desc limit 1;
    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}

        Log To Console    provider = ${row[0]}

    END


TC - MSME-T1627 (1.0)
    log to console    To verify Created on is updating properly or not
    ${auth}=    create list    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query}=    Set Variable    SELECT created_on,updated_on FROM validation.kyb_gst_to_contacts_provider_log where http_status_code='${status_code}' order by id desc limit 1;
    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}

        Log To Console    created_on = ${row[0]}
        Log To Console    updated_on = ${row[1]}

    END


TC - MSME-T3831 (1.0)
    log to console    To verify by entering gstin no greater than 15 char
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    23
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case31



TC - MSME-T3832 (1.0)
    log to console    To verify by entering gstin no as 15 char
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    24
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case32


TC - MSME-T3833 (1.0)
    log to console    To verify by entering gstin no as less than 15 char
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    25
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case33


TC - MSME-T3835 (1.0)
    log to console    To verify by entering test scenario as both vendor source down(all_vendors_down)
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    26
    ${body}=    Create Dictionary    gstin=${row['gstin']}    client_ref_num=${row['client_ref_num']}     test_scenario=${row['test_scenario']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case34



TC - MSME-T3840 (1.0)
    log to console    Verify by changing from https to http
    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    http://svcstage.digitap.work    auth=${auth}    verify=true

    # Read test data from CSV file
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0    # Select the first row

    ${gstin}=    Get From Dictionary    ${row}    gstin
    ${client_ref_num}=    Get From Dictionary    ${row}    client_ref_num


    ${body}=    create dictionary    gstin=${gstin}    client_ref_num=${client_ref_num}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Get Request    mysession     ${endpoint_url}   json=${body}    headers=${header}

    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    # Validations
    Should Be Equal As Strings    ${response.status_code}    503

