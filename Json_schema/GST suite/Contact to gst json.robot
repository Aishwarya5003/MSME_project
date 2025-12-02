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
${endpoint_url}=   /validation/kyb/v1/contact_to_gst
${file_path}=     C:\\Users\\Aishwarya\\PycharmProjects\\APIAutomation\\data\\Contact to gst.csv
${client-username}=    526526315047
${client-password}=    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
${MAX_RESPONSE_TIME}    5000  # in milliseconds
${MIN_RESPONSE_TIME}    3000    # in milliseconds
${json_schema_file}=    C:\\Users\\Aishwarya\\PycharmProjects\\APIAutomation\\Json_schema\\GST suite\\contact to gst json_schema.json


*** Keywords ***
Read Test Data From CSV
    [Arguments]    ${file_path}
    ${test_data}=    Create List
    ${file_content}=    Get File    ${file_path}
    ${lines}=    Split To Lines    ${file_content}
    FOR    ${line}    IN    @{lines}[1:]    # Skip the header line
        ${columns}=    Split String    ${line}    separator=,
        ${data}=    Create Dictionary    mobile=${columns[1]}    client_ref_num=${columns[2]}    test_scenario=${columns[3]}    email=${columns[4]}
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
TC - MSME-T3874 (1.0)
    log to console    To verify by entering by entering valid mobile number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

TC - MSME-T3875 (1.0)
    log to console    To verify by entering by entering no record found mobile number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    1
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case2


TC - MSME-T3876 (1.0)
    log to console   To verify by entering In-valid mobile number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    2
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case3


TC - MSME-T3877 (1.0)
    log to console    To verify by entering by entering valid mobile number starting with 9.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    3
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case4


TC - MSME-T3878 (1.0)
    log to console    To verify by entering valid mobile number starting with 7.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    4
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case5


TC - MSME-T3879 (1.0)
    log to console    To verify by entering valid mobile number starting with 6.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    5
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case6


TC - MSME-T3880 (1.0)
    log to console    To verify by entering valid mobile number starting with 8.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    6
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case7

TC - MSME-T3881 (1.0)
    log to console    To verify by entering invalid mobile number starting with 0.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    7
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case8


TC - MSME-T3882 (1.0)
    log to console    To verify by entering invalid mobile number starting with 1.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    8
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case9


TC - MSME-T3883 (1.0)
    log to console    To verify by entering mobile number with leass than 10 digits.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    9
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case10


TC - MSME-T3884 (1.0)
    log to console    To verify by entering mobile number with more than 10 digits
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    10
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case11


TC - MSME-T3885 (1.0)
    log to console    To verify by entering mobile number containing alphabetic characters.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    11
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case12

TC - MSME-T3886 (1.0)
    log to console    To verify by entering mobile number containing special characters.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    12
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case13


TC - MSME-T3887 (1.0)
    log to console    To verify by entering mobile number entry as empty.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    13
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case14

TC - MSME-T3888 (1.0)
    log to console    To verify by entering mobile number entry with empty spaces.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    14
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case15


TC - MSME-T3889 (1.0)
    log to console    To verify by entering mobile number with space at the beginning.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    15
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case16

TC - MSME-T3890 (1.0)
    log to console    To verify by entering mobile number with space at the end.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    16
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case17


TC - MSME-T3891 (1.0)
    log to console    To verify by entering mobile number with spaces between digits.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    17
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case18



TC - MSME-T3892 (1.0)
    log to console    To verify by entering mobile number from another country.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    18
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case19

TC - MSME-T3893 (1.0)
    log to console    To verify by entering Mobile number with +91
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    19
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case20


TC - MSME-T3894 (1.0)
    log to console    To verify by entering Mobile number with 91
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    20
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case21

TC - MSME-T3896 (1.0)
    log to console    To verify by entering mobile number entered as "0000000000."
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    21
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case22


TC - MSME-T3897 (1.0)
    log to console    To verify by entering mobile number entered as "1111111111."
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    22
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case23

TC - MSME-T3900 (1.0)
    log to console    To verify by entering entry of valid mobile number and valid email together.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    35
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}     email=${row['email']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case43


TC - MSME-T3915 (1.0)
    log to console    To verify by entering valid client reference number
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    23
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case24


TC - MSME-T3916 (1.0)
    log to console    To verify by entering entry of an invalid client reference number.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    24
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case25

TC - MSME-T3917 (1.0)
    log to console    To verify by entering client reference number field left empty.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    25
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case26


TC - MSME-T3918 (1.0)
    log to console    To verify by entering client reference number entry with empty space.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    26
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case27

TC - MSME-T3919 (1.0)
    log to console    To verify by entering client reference number with additional spaces at the beginning and end.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    27
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case28


TC - MSME-T3920 (1.0)
    log to console    To verify by entering only "_", and  "-", are accepted in the client reference number.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    28
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case29


TC - MSME-T3922 (1.0)
    log to console    To verify by entering client reference number with more than 100 characters.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    29
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case30


TC - MSME-T3923 (1.0)
    log to console    To verify by entering client reference number with exactly 100 characters.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    30
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case31

TC - MSME-T3924 (1.0)
    log to console    To verify by entering both client reference number and mobile fields left empty.
     ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    31
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case32


TC - MSME-T3925 (1.0)
    log to console    To verify by entering the test Scenarios with limit_reached
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    32
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}     test_scenario=${row['test_scenario']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case33

TC - MSME-T3927 (1.0)
    log to console    To verify by entering the test Scenarios with rpacpc_source_down
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    33
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}     test_scenario=${row['test_scenario']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case34

TC - MSME-T3928 (1.0)
    log to console    To verify by entering the test Scenarios with vendor_timeout
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    34
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}     test_scenario=${row['test_scenario']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case35


TC - MSME-T3932 (1.0)
    log to console    Verify the entid is stored or not
    ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT ent_id FROM kyb_validation.kyb_contact_to_gst_api where client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    ent_id = ${row[0]}

    END


TC - MSME-T3933 (1.0)
    log to console    Verify the mobile number is stored or not
    ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT mobile FROM kyb_validation.kyb_contact_to_gst_api where client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    mobile = ${row[0]}

    END


#TC - MSME-T3934 (1.0)
#    log to console    Verify the email id is stored or not
#     ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
#    ${test_data}=    Read Test Data From CSV    ${file_path}
#    ${row}=    Get From List    ${test_data}    0
#    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
#    ${header}=    Create Dictionary    Content-Type=application/json
#    Create Session    mysession    ${base_url}    auth=${auth}    verify=true
#
#    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
##    Log To Console    ${body}
#    Log To Console    ${response.status_code}
#    Log To Console    ${response.content}
#    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
#    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1
#
#    # Prepare SQL Query
#    ${sql_query1}=    Set Variable    SELECT mobile FROM kyb_validation.kyb_contact_to_gst_api where client_ref_num='${client_ref_num}' order by id desc limit 1;
#
#    # Execute SQL Query
#    ${query_result1}=    Query    ${sql_query1}
#    #Log To Console    ${query_result}
#
#    FOR    ${row}    IN    @{query_result1}
#        Log To Console    mobile = ${row[0]}
#
#    END
#

TC - MSME-T3935 (1.0)
    log to console    Verify the client_ref_num is stored or not
    ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT client_ref_num FROM kyb_validation.kyb_contact_to_gst_api where client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    client_ref_num = ${row[0]}

    END



TC - MSME-T3936 (1.0)
    log to console    Verify the request_payload is stored or not

    ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT request_payload FROM kyb_validation.kyb_contact_to_gst_api where client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    request_payload = ${row[0]}

    END


TC - MSME-T3937 (1.0)
    log to console    Verify the response_payload is stored or not

    ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT response_payload FROM kyb_validation.kyb_contact_to_gst_api where client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    response_payload = ${row[0]}

    END



TC - MSME-T3938 (1.0)
    log to console    Verify the Success http_response_code is stored or not
    ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT http_response_code FROM kyb_validation.kyb_contact_to_gst_api where client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    http_response_code = ${row[0]}

    END


TC - MSME-T3939 (1.0)
    log to console    Verify the failure http_response_code is stored or not
    ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    33
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}     test_scenario=${row['test_scenario']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case34

    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT http_response_code FROM kyb_validation.kyb_contact_to_gst_api where client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    http_response_code = ${row[0]}

    END


TC - MSME-T3940 (1.0)
    log to console    Verify the Success result_code is stored or not

   ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT result_code FROM kyb_validation.kyb_contact_to_gst_api where client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    result_code = ${row[0]}

    END



TC - MSME-T3941 (1.0)
    LOG TO CONSOLE    Verify the failure result_code is stored or not

     ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    1
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case2

    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT result_code FROM kyb_validation.kyb_contact_to_gst_api where client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    result_code = ${row[0]}

    END

TC - MSME-T3942 (1.0)
    log to console    Verify the tat is stored or not
     ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT tat FROM kyb_validation.kyb_contact_to_gst_api where client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    tat = ${row[0]}

    END



TC - MSME-T3943 (1.0)
    log to console    Verify that the created_on and updated_on are updated properly.
    ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    ${header}=    Create Dictionary    Content-Type=application/json
    Create Session    mysession    ${base_url}    auth=${auth}    verify=true

    ${response}=    Post Request    mysession    ${endpoint_url}    json=${body}    headers=${header}
#    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT created_on, updated_on FROM kyb_validation.kyb_contact_to_gst_api where client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    created_on = ${row[0]}
        Log To Console    updated_on = ${row[0]}

    END


TC - MSME-T3944 (1.0)
    log to console    Verify the contact_to_gst_request_log_id is stored or not
    ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT contact_to_gst_request_log_id FROM kyb_validation.kyb_contact_to_gst_provider_log where http_status_code='${status_code}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    contact_to_gst_request_log_id = ${row[0]}


    END


TC - MSME-T3945 (1.0)
    log to console    Verify the contact_to_gst_request_log_id and id (kyb_contact_to_gst_api) same or not.
     ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT contact_to_gst_request_log_id FROM kyb_validation.kyb_contact_to_gst_provider_log where http_status_code='${status_code}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    contact_to_gst_request_log_id = ${row[0]}


    END
    ${sql_query2}=    Set Variable    SELECT id FROM kyb_validation.kyb_contact_to_gst_api where client_ref_num='${client_ref_num}' order by id desc limit 1;


    ${query_result2}=    Query    ${sql_query2}
      #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result2}
        Log To Console    id = ${row[0]}

    END


TC - MSME-T3946 (1.0)
    log to console    Verify the request_payload is stored or not

    ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT request_payload FROM kyb_validation.kyb_contact_to_gst_provider_log where http_status_code='${status_code}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    request_payload = ${row[0]}


    END


TC - MSME-T3947 (1.0)
    log to console    Verify the response_payload is stored or not
    ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT response_payload FROM kyb_validation.kyb_contact_to_gst_provider_log where http_status_code='${status_code}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    response_payload = ${row[0]}


    END


TC - MSME-T3948 (1.0)
    log to console    Verify the http_status_code is stored or not
    ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT http_status_code FROM kyb_validation.kyb_contact_to_gst_provider_log where http_status_code='${status_code}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    http_status_code = ${row[0]}


    END

TC - MSME-T3949 (1.0)
    log to console    Verify the provider is stored or not
      ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT provider FROM kyb_validation.kyb_contact_to_gst_provider_log where http_status_code='${status_code}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    provider = ${row[0]}


    END

TC - MSME-T3950 (1.0)
    log to console    Verify the vendor tat is stored or not

     ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT vendor_tat FROM kyb_validation.kyb_contact_to_gst_provider_log where http_status_code='${status_code}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    vendor_tat = ${row[0]}


    END

TC - MSME-T3951 (1.0)
    log to console    Verify that the created_on and updated_on are updated properly.
      ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
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
    ${sql_query1}=    Set Variable    SELECT created_on, updated_on FROM kyb_validation.kyb_contact_to_gst_provider_log where http_status_code='${status_code}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    created_on = ${row[0]}
        Log To Console    updated_on = ${row[1]}


    END

TC - MSME-T3952 (1.0)
    log to console    Verify by entering valid authentication.
    ${auth}=    Create List    ${client-username}    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

TC - MSME-T3953 (1.0)
    log to console    Verify by entering invalid authentication
    ${auth}=    Create List    5265263150$$    ${client-password}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}   client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case36


TC - MSME-T3955 (1.0)
    log to console    Verify by entering one client username and another client’s password
    ${auth}=    Create List    526526315047   EA6F34B4B3B618A10CF5C22232290778
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case37


TC - MSME-T3956 (1.0)
    log to console    Verify by entering a client that doesn’t have conatct to gst validation service
    ${auth}=    Create List    526526315047   EA6F34B4B3B618A10CF5C22232290778
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case38


TC - MSME-T3957 (1.0)
    log to console    Verify by entering an empty username.
    ${auth}=    Create List    ${EMPTY}   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}   client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case39

TC - MSME-T3958 (1.0)
    log to console    Verify by entering an empty password
    ${auth}=    Create List    526526315047   ${EMPTY}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}   client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case40

TC - MSME-T3959 (1.0)
    log to console    Verify by entering both username and password as empty
    ${auth}=    Create List    ${EMPTY}   ${EMPTY}
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary   mobile=${row['mobile']}   client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case41

TC - MSME-T3960 (1.0)
    log to console    To verify by entering by giving request by Changing the type of reqeust. POST to GET

    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true

    # Read test data from CSV file
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    31    # Select the first row

    ${mobile}=    Get From Dictionary    ${row}    mobile
    ${client_ref_num}=    Get From Dictionary    ${row}    client_ref_num

    ${body}=    create dictionary    mobile=${mobile}    client_ref_num=${client_ref_num}
    ${header}=    create dictionary    Content-Type=application/json

    ${response}=    Get Request    mysession     ${endpoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
   # Validations
   Should Be Equal As Strings    ${response.json()['message']}    API running successfully


TC - MSME-T3963 (1.0)
    log to console    Verify by changing from HTTPS to HTTP

     ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    http://svcstage.digitap.work    auth=${auth}    verify=true

    # Read test data from CSV file
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    31    # Select the first row

    ${mobile}=    Get From Dictionary    ${row}    mobile
    ${client_ref_num}=    Get From Dictionary    ${row}    client_ref_num



    ${body}=    create dictionary    mobile=${mobile}    client_ref_num=${client_ref_num}
    ${header}=    create dictionary    Content-Type=application/json

    ${response}=    Get Request    mysession     ${endpoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}
   # Validations
    Should Be Equal As Strings    ${response.status_code}    503


TC - MSME-T3965 (1.0)
    log to console    Verify successful response received within 5 seconds.

    ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0
    ${body}=    Create Dictionary    mobile=${row['mobile']}   client_ref_num=${row['client_ref_num']}
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

TC - MSME-T3966 (1.0)
    log to console    Verify failure response received within 3 seconds.

    ${auth}=    Create List    526526315047   BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    1
    ${body}=    Create Dictionary    mobile=${row['mobile']}   client_ref_num=${row['client_ref_num']}
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




