*** Settings ***
Library    RequestsLibrary
Library    CSVLibrary
Library    Collections
Library    OperatingSystem
Library    String
Library    DatabaseLibrary
Library    urllib3
Library    random
Library    DateTime
Library    JSONLibrary

Suite Setup     Connect To Database     pymysql     ${DBName}   ${DBUser}   ${DBPass}   ${DBHost}   ${DBPort}
Suite Teardown      Disconnect From Database

*** Variables ***
${DBName}   validation
${DBUser}   qa.abi.nanthana
${DBPass}   nOu0XNreRyDMEmr
${DBHost}   dev-db.chjy1zjdr74q.ap-south-1.rds.amazonaws.com
${DBPort}   3306
${base_url}=    https://svcstage.digitap.work
${file_path}=   C:\\Users\\Aishwarya\\PycharmProjects\\APIAutomation\\data\\E-challan.csv
${json_schema_file}=   C:\\Users\\Aishwarya\\PycharmProjects\\APIAutomation\\Json_schema\\E-challan\\echallan_schema.json
${endpoint_url}=   /validation/kyc/v1/echallan
${client-username}=    526526315047
${client-password}=    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5
${MAX_RESPONSE_TIME}    5000  # in milliseconds
${MIN_RESPONSE_TIME}    5000    # in milliseconds

*** Keywords ***
Read Test Data From CSV
    [Arguments]    ${file_path}
    ${test_data}=    Create List
    ${file_content}=    Get File    ${file_path}
    ${lines}=    Split To Lines    ${file_content}
    FOR    ${line}    IN    @{lines}[1:]    # Skip the header line
        ${columns}=    Split String    ${line}    separator=,
        ${data}=    Create Dictionary    client_ref_num=${columns[2]}    reg_no=${columns[1]}
        Append To List    ${test_data}    ${data}
    END
   RETURN    ${test_data}

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
    ${response}=    Post Request    mysession    /validation/kyc/v1/echallan    json=${body}    headers=${header}
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
TC - MSME-T3676:
    Log To Console    Verify by entering a valid RC number
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case1

TC - MSME-T3677:
    Log To Console    Verify by entering an invalid RC number
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    1

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case2

TC - MSME-T3678:
    Log To Console    Verify by leaving the RC number field empty
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    2

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case3

TC - MSME-T3679:
    Log To Console    Verify by entering only spaces in the RC number
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    3

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case4

TC - MSME-T3680:
    Log To Console    Verify by entering spaces in both the RC number and client reference number
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    4

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case5

TC - MSME-T3681:
    Log To Console    Verify by entering special characters in the RC number
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    5

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case6

TC - MSME-T3682:
    Log To Console    Verify by entering all numeric characters in the RC number
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    6

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case7

TC - MSME-T3683:
    Log To Console    Verify by entering all alphabetic characters in the RC number
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    7

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case8

TC - MSME-T3684:
    Log To Console    Verify by entering the RC number in lowercase
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    8

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case9

TC - MSME-T3685:
    Log To Console    Verify by entering a new format RC number
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    9

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case10

TC - MSME-T3686:
    Log To Console    Verify by entering an RC number that is not found
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    10

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case11

TC - MSME-T3687:
    Log To Console    Verify by entering an RC number for a two-wheeler
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    11

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case12

TC - MSME-T3688:
    Log To Console    Verify by entering an RC number for a three-wheeler
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    12

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case13

TC - MSME-T3689:
    Log To Console    Verify by entering an RC number for a car
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    13

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case14

TC - MSME-T3690:
    Log To Console    Verify by entering an RC number for a lorry
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    14

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case15

TC - MSME-T3691:
    Log To Console    Verify by entering an RC number for a tractor
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    15

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case16

TC - MSME-T3692:
    Log To Console    Verify by entering an RC number for a government vehicle
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    16

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case17

TC - MSME-T3693:
    Log To Console    Verify by entering an RC number for a private bus vehicle
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    17

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case18

TC - MSME-T3694:
    Log To Console    Verify by entering multiple registered RTO RC numbers
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    18

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case19

TC - MSME-T3695:
    Log To Console    Verify by entering spaces at the front of the RC number
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    19

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case20

TC - MSME-T3696:
    Log To Console    Verify by entering spaces at the end of the RC number
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    20

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case21

TC - MSME-T3698:
    Log To Console    Verify by changing the reg no key
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    21

    ${body}=    Create Dictionary    reg_no1=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case22

TC - MSME-T3699:
    Log To Console    Verify by entering a valid client reference number
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    22

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case23

TC - MSME-T3700:
    Log To Console    Verify by entering an invalid client reference number
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    23

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case24

TC - MSME-T3701:
    Log To Console    Verify by leaving the client reference number field empty
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    24

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case25

TC - MSME-T3702:
    Log To Console     Verify by entering only spaces in the client reference number field
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    25

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case26

TC - MSME-T3703:
    Log To Console     Verify by entering a client reference number with more than 45 characters
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    26

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case27

TC - MSME-T3704:
    Log To Console     Verify by entering a client reference number exactly 45 characters long
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    27

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case28

TC - MSME-T3705:
    Log To Console     Verify by adding spaces at the front and end of the client reference number
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    28

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case29

TC - MSME-T3707:
    Log To Console     Verify that only '_', '-', and '.' characters are accepted in the client reference number
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    29

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case30

TC - MSME-T3711:
    Log To Console     Verify the response for a 101 case
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    30

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case31



TC - MSME-T3713:
    Log To Console     Verify the response for a 103 case
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    32

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case33


TC - MSME-T3714 (1.0)
    log to console    Verify the entid is stored or not
    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "reg_no":"TN54M7497", "client_ref_num":"${random_client_ref_num}"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Post Request    mysession     ${endpoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${response_content}=    Set Variable    ${response.content}
    ${status_code}=    Set Variable    ${response.status_code}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${rc_number}=    Set Variable    ${response.json()['result']['rc_number']}

   # Validations
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    200
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}
    Should Be Equal As Strings  ${response.json()['result_code']}    101
    Should Be Equal As Strings  ${response.json()['result']['echallan_count']}    1
    Should Be Equal As Strings  ${response.json()['result']['rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_for']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['accused_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_name']}    DEVARAJAN K
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_father_name']}    KUPPAIYER G R
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_contact_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dl_rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_no']}    TN107563221009124224
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['state']}    TN
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_date']}    2022-10-09 00:00:00
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['offence']}    Driving a motor cycle without a protective headgear (helmet)/ Driving a motor cycle or causing or allowing a motor cycle to be driven in contravention of the provisions of section 129 of the Motor vehicles Act1988 ( u/s 194D ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['offence']}    Not producing. Driving Licence. Conductors Licence. Registration Certificate. permit. fitness certificate and insurance certificate on demand ( u/s 177 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['offence']}    Pillion Rider riding in a motor cycle without a protective headgear (helmet) Sec / Under 129 M V act 1988 ( U/Sec 129 MV Act 1988 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['investigate_under']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['long_lat']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_location']}    GH Bus Stop, Shevapet, Salem, Tamil Nadu 636001, India
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_remark']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['form_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_1']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_2']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_3']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_images']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV1_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV2_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_number']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_details']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['suspend_ISDL']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_father_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_age']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_gender']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_validity']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issue_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issued_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_amount']}    300
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['status']}    Paid
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_source']}    Card
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_date']}    2022-10-09 12:42:24
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['transaction_ID']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no_offline']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['offline_receipt']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['mobile_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ac_fIS']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_amount']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['RTO_name']}    Salem City
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_document']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_vehicle']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_class']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['permit_upto']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['chassis_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['engine_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_owner_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['father_owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_related_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['order_release_img']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['release_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_court_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['action_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dispatch_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['user_charges']}    ${EMPTY}

    Log To Console    ${EMPTY}
    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT ent_id FROM kyc_echallan_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    ent_id = ${row[0]}

    END


TC - MSME-T3715 (1.0)
    log to console    Verify the request_payload is stored or not
     log to console    Verify the entid is stored or not
    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "reg_no":"TN54M7497", "client_ref_num":"${random_client_ref_num}"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Post Request    mysession     ${endpoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${response_content}=    Set Variable    ${response.content}
    ${status_code}=    Set Variable    ${response.status_code}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${rc_number}=    Set Variable    ${response.json()['result']['rc_number']}

   # Validations
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    200
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}
    Should Be Equal As Strings  ${response.json()['result_code']}    101
    Should Be Equal As Strings  ${response.json()['result']['echallan_count']}    1
    Should Be Equal As Strings  ${response.json()['result']['rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_for']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['accused_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_name']}    DEVARAJAN K
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_father_name']}    KUPPAIYER G R
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_contact_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dl_rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_no']}    TN107563221009124224
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['state']}    TN
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_date']}    2022-10-09 00:00:00
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['offence']}    Driving a motor cycle without a protective headgear (helmet)/ Driving a motor cycle or causing or allowing a motor cycle to be driven in contravention of the provisions of section 129 of the Motor vehicles Act1988 ( u/s 194D ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['offence']}    Not producing. Driving Licence. Conductors Licence. Registration Certificate. permit. fitness certificate and insurance certificate on demand ( u/s 177 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['offence']}    Pillion Rider riding in a motor cycle without a protective headgear (helmet) Sec / Under 129 M V act 1988 ( U/Sec 129 MV Act 1988 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['investigate_under']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['long_lat']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_location']}    GH Bus Stop, Shevapet, Salem, Tamil Nadu 636001, India
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_remark']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['form_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_1']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_2']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_3']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_images']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV1_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV2_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_number']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_details']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['suspend_ISDL']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_father_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_age']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_gender']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_validity']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issue_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issued_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_amount']}    300
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['status']}    Paid
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_source']}    Card
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_date']}    2022-10-09 12:42:24
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['transaction_ID']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no_offline']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['offline_receipt']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['mobile_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ac_fIS']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_amount']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['RTO_name']}    Salem City
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_document']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_vehicle']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_class']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['permit_upto']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['chassis_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['engine_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_owner_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['father_owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_related_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['order_release_img']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['release_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_court_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['action_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dispatch_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['user_charges']}    ${EMPTY}

    Log To Console    ${EMPTY}
    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT request_payload FROM kyc_echallan_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    request_payload = ${row[0]}

    END

TC - MSME-T3716 (1.0)
    log to console    Verify the reg_no is stored or not

    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "reg_no":"TN54M7497", "client_ref_num":"${random_client_ref_num}"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Post Request    mysession     ${endpoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${response_content}=    Set Variable    ${response.content}
    ${status_code}=    Set Variable    ${response.status_code}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${rc_number}=    Set Variable    ${response.json()['result']['rc_number']}

   # Validations
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    200
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}
    Should Be Equal As Strings  ${response.json()['result_code']}    101
    Should Be Equal As Strings  ${response.json()['result']['echallan_count']}    1
    Should Be Equal As Strings  ${response.json()['result']['rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_for']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['accused_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_name']}    DEVARAJAN K
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_father_name']}    KUPPAIYER G R
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_contact_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dl_rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_no']}    TN107563221009124224
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['state']}    TN
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_date']}    2022-10-09 00:00:00
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['offence']}    Driving a motor cycle without a protective headgear (helmet)/ Driving a motor cycle or causing or allowing a motor cycle to be driven in contravention of the provisions of section 129 of the Motor vehicles Act1988 ( u/s 194D ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['offence']}    Not producing. Driving Licence. Conductors Licence. Registration Certificate. permit. fitness certificate and insurance certificate on demand ( u/s 177 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['offence']}    Pillion Rider riding in a motor cycle without a protective headgear (helmet) Sec / Under 129 M V act 1988 ( U/Sec 129 MV Act 1988 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['investigate_under']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['long_lat']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_location']}    GH Bus Stop, Shevapet, Salem, Tamil Nadu 636001, India
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_remark']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['form_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_1']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_2']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_3']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_images']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV1_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV2_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_number']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_details']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['suspend_ISDL']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_father_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_age']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_gender']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_validity']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issue_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issued_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_amount']}    300
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['status']}    Paid
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_source']}    Card
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_date']}    2022-10-09 12:42:24
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['transaction_ID']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no_offline']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['offline_receipt']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['mobile_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ac_fIS']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_amount']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['RTO_name']}    Salem City
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_document']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_vehicle']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_class']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['permit_upto']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['chassis_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['engine_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_owner_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['father_owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_related_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['order_release_img']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['release_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_court_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['action_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dispatch_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['user_charges']}    ${EMPTY}

    Log To Console    ${EMPTY}
    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT reg_no FROM kyc_echallan_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    reg_no = ${row[0]}

    END


TC - MSME-T3717 (1.0)
    log to console    Verify the client_ref_num is stored or not


    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "reg_no":"TN54M7497", "client_ref_num":"${random_client_ref_num}"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Post Request    mysession     ${endpoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${response_content}=    Set Variable    ${response.content}
    ${status_code}=    Set Variable    ${response.status_code}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${rc_number}=    Set Variable    ${response.json()['result']['rc_number']}

   # Validations
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    200
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}
    Should Be Equal As Strings  ${response.json()['result_code']}    101
    Should Be Equal As Strings  ${response.json()['result']['echallan_count']}    1
    Should Be Equal As Strings  ${response.json()['result']['rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_for']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['accused_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_name']}    DEVARAJAN K
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_father_name']}    KUPPAIYER G R
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_contact_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dl_rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_no']}    TN107563221009124224
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['state']}    TN
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_date']}    2022-10-09 00:00:00
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['offence']}    Driving a motor cycle without a protective headgear (helmet)/ Driving a motor cycle or causing or allowing a motor cycle to be driven in contravention of the provisions of section 129 of the Motor vehicles Act1988 ( u/s 194D ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['offence']}    Not producing. Driving Licence. Conductors Licence. Registration Certificate. permit. fitness certificate and insurance certificate on demand ( u/s 177 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['offence']}    Pillion Rider riding in a motor cycle without a protective headgear (helmet) Sec / Under 129 M V act 1988 ( U/Sec 129 MV Act 1988 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['investigate_under']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['long_lat']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_location']}    GH Bus Stop, Shevapet, Salem, Tamil Nadu 636001, India
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_remark']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['form_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_1']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_2']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_3']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_images']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV1_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV2_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_number']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_details']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['suspend_ISDL']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_father_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_age']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_gender']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_validity']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issue_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issued_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_amount']}    300
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['status']}    Paid
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_source']}    Card
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_date']}    2022-10-09 12:42:24
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['transaction_ID']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no_offline']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['offline_receipt']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['mobile_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ac_fIS']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_amount']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['RTO_name']}    Salem City
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_document']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_vehicle']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_class']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['permit_upto']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['chassis_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['engine_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_owner_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['father_owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_related_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['order_release_img']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['release_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_court_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['action_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dispatch_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['user_charges']}    ${EMPTY}

    Log To Console    ${EMPTY}
    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT client_ref_num FROM kyc_echallan_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    client_ref_num = ${row[0]}

    END


TC - MSME-T3718 (1.0)
    log to console    Verify the Success http_response_code is stored or not

    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "reg_no":"TN54M7497", "client_ref_num":"${random_client_ref_num}"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Post Request    mysession     ${endpoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${response_content}=    Set Variable    ${response.content}
    ${status_code}=    Set Variable    ${response.status_code}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${rc_number}=    Set Variable    ${response.json()['result']['rc_number']}

   # Validations
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    200
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}
    Should Be Equal As Strings  ${response.json()['result_code']}    101
    Should Be Equal As Strings  ${response.json()['result']['echallan_count']}    1
    Should Be Equal As Strings  ${response.json()['result']['rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_for']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['accused_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_name']}    DEVARAJAN K
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_father_name']}    KUPPAIYER G R
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_contact_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dl_rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_no']}    TN107563221009124224
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['state']}    TN
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_date']}    2022-10-09 00:00:00
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['offence']}    Driving a motor cycle without a protective headgear (helmet)/ Driving a motor cycle or causing or allowing a motor cycle to be driven in contravention of the provisions of section 129 of the Motor vehicles Act1988 ( u/s 194D ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['offence']}    Not producing. Driving Licence. Conductors Licence. Registration Certificate. permit. fitness certificate and insurance certificate on demand ( u/s 177 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['offence']}    Pillion Rider riding in a motor cycle without a protective headgear (helmet) Sec / Under 129 M V act 1988 ( U/Sec 129 MV Act 1988 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['investigate_under']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['long_lat']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_location']}    GH Bus Stop, Shevapet, Salem, Tamil Nadu 636001, India
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_remark']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['form_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_1']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_2']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_3']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_images']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV1_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV2_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_number']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_details']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['suspend_ISDL']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_father_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_age']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_gender']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_validity']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issue_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issued_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_amount']}    300
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['status']}    Paid
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_source']}    Card
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_date']}    2022-10-09 12:42:24
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['transaction_ID']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no_offline']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['offline_receipt']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['mobile_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ac_fIS']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_amount']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['RTO_name']}    Salem City
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_document']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_vehicle']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_class']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['permit_upto']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['chassis_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['engine_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_owner_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['father_owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_related_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['order_release_img']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['release_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_court_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['action_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dispatch_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['user_charges']}    ${EMPTY}

    Log To Console    ${EMPTY}
    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT http_response_code FROM kyc_echallan_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    http_response_code = ${row[0]}

    END

TC - MSME-T3719 (1.0)
    LOG TO CONSOLE    To verify if the failure response is being stored correctly.
    ${auth}=    create list    ${client-username}    ${cLient-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "reg_no":"TN07CL5988", "client_ref_num":"${random_client_ref_num}", "test_scenario":"timeout"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Post Request    mysession     ${endPoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${response_content}=    Set Variable    ${response.content}
    ${status_code}=    Set Variable    ${response.status_code}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}


   #validation
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    503
    Should Be Equal As Strings  ${response.json()['error']}      Source is busy or unavailable. Try again later
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}

    Log To Console    ${EMPTY}
    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT reg_no, client_ref_num, http_response_code,error FROM kyc_echallan_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    reg_no = ${row[0]}
        Log To Console    client_ref_num = ${row[1]}
        Log To Console    http_response_code = ${row[2]}
        Log To Console    error=${row[3]}

    END

TC - MSME-T3720 (1.0)
    LOG TO CONSOLE    Verify the Success result_code is stored or not

    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "reg_no":"TN54M7497", "client_ref_num":"${random_client_ref_num}"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Post Request    mysession     ${endpoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${response_content}=    Set Variable    ${response.content}
    ${status_code}=    Set Variable    ${response.status_code}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${rc_number}=    Set Variable    ${response.json()['result']['rc_number']}

   # Validations
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    200
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}
    Should Be Equal As Strings  ${response.json()['result_code']}    101
    Should Be Equal As Strings  ${response.json()['result']['echallan_count']}    1
    Should Be Equal As Strings  ${response.json()['result']['rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_for']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['accused_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_name']}    DEVARAJAN K
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_father_name']}    KUPPAIYER G R
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_contact_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dl_rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_no']}    TN107563221009124224
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['state']}    TN
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_date']}    2022-10-09 00:00:00
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['offence']}    Driving a motor cycle without a protective headgear (helmet)/ Driving a motor cycle or causing or allowing a motor cycle to be driven in contravention of the provisions of section 129 of the Motor vehicles Act1988 ( u/s 194D ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['offence']}    Not producing. Driving Licence. Conductors Licence. Registration Certificate. permit. fitness certificate and insurance certificate on demand ( u/s 177 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['offence']}    Pillion Rider riding in a motor cycle without a protective headgear (helmet) Sec / Under 129 M V act 1988 ( U/Sec 129 MV Act 1988 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['investigate_under']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['long_lat']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_location']}    GH Bus Stop, Shevapet, Salem, Tamil Nadu 636001, India
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_remark']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['form_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_1']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_2']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_3']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_images']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV1_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV2_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_number']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_details']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['suspend_ISDL']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_father_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_age']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_gender']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_validity']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issue_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issued_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_amount']}    300
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['status']}    Paid
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_source']}    Card
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_date']}    2022-10-09 12:42:24
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['transaction_ID']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no_offline']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['offline_receipt']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['mobile_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ac_fIS']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_amount']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['RTO_name']}    Salem City
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_document']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_vehicle']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_class']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['permit_upto']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['chassis_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['engine_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_owner_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['father_owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_related_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['order_release_img']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['release_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_court_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['action_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dispatch_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['user_charges']}    ${EMPTY}

    Log To Console    ${EMPTY}
    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT result_code FROM kyc_echallan_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    result_code = ${row[0]}

    END


TC - MSME-T3721 (1.0)
    log to console    Verify the failure result_code is stored or not
    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true

    # Read test data from CSV file
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    10    # Select the first row

    ${reg_no}=    Get From Dictionary    ${row}    reg_no
    ${client_ref_num}=    Get From Dictionary    ${row}    client_ref_num


    ${body}=    create dictionary    reg_no=${reg_no}    client_ref_num=${client_ref_num}
    ${header}=    create dictionary    Content-Type=application/json

    ${response}=    Post Request    mysession     ${endpoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${status_code}=    Set Variable    ${response.status_code}

    # Validations
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    200
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    Almond
    Should Be Equal As Strings  ${response.json()['result_code']}    103
    Should Be Equal As Strings  ${response.json()['message']}    No record found for the given input
    Log To Console    ${EMPTY}
    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT result_code FROM kyc_echallan_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    result_code = ${row[0]}

    END


TC - MSME-T3722 (1.0)
    log to console    Verify the response_payload is stored or not

    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "reg_no":"TN54M7497", "client_ref_num":"${random_client_ref_num}"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Post Request    mysession     ${endpoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${response_content}=    Set Variable    ${response.content}
    ${status_code}=    Set Variable    ${response.status_code}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${rc_number}=    Set Variable    ${response.json()['result']['rc_number']}

   # Validations
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    200
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}
    Should Be Equal As Strings  ${response.json()['result_code']}    101
    Should Be Equal As Strings  ${response.json()['result']['echallan_count']}    1
    Should Be Equal As Strings  ${response.json()['result']['rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_for']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['accused_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_name']}    DEVARAJAN K
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_father_name']}    KUPPAIYER G R
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_contact_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dl_rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_no']}    TN107563221009124224
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['state']}    TN
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_date']}    2022-10-09 00:00:00
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['offence']}    Driving a motor cycle without a protective headgear (helmet)/ Driving a motor cycle or causing or allowing a motor cycle to be driven in contravention of the provisions of section 129 of the Motor vehicles Act1988 ( u/s 194D ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['offence']}    Not producing. Driving Licence. Conductors Licence. Registration Certificate. permit. fitness certificate and insurance certificate on demand ( u/s 177 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['offence']}    Pillion Rider riding in a motor cycle without a protective headgear (helmet) Sec / Under 129 M V act 1988 ( U/Sec 129 MV Act 1988 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['investigate_under']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['long_lat']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_location']}    GH Bus Stop, Shevapet, Salem, Tamil Nadu 636001, India
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_remark']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['form_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_1']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_2']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_3']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_images']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV1_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV2_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_number']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_details']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['suspend_ISDL']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_father_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_age']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_gender']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_validity']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issue_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issued_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_amount']}    300
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['status']}    Paid
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_source']}    Card
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_date']}    2022-10-09 12:42:24
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['transaction_ID']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no_offline']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['offline_receipt']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['mobile_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ac_fIS']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_amount']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['RTO_name']}    Salem City
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_document']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_vehicle']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_class']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['permit_upto']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['chassis_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['engine_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_owner_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['father_owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_related_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['order_release_img']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['release_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_court_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['action_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dispatch_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['user_charges']}    ${EMPTY}

    Log To Console    ${EMPTY}
    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT response_payload FROM kyc_echallan_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    response_payload = ${row[0]}

    END


TC - MSME-T3723 (1.0)
    log to console    Verify the tat is stored or not

    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "reg_no":"TN54M7497", "client_ref_num":"${random_client_ref_num}"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Post Request    mysession     ${endpoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${response_content}=    Set Variable    ${response.content}
    ${status_code}=    Set Variable    ${response.status_code}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${rc_number}=    Set Variable    ${response.json()['result']['rc_number']}

   # Validations
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    200
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}
    Should Be Equal As Strings  ${response.json()['result_code']}    101
    Should Be Equal As Strings  ${response.json()['result']['echallan_count']}    1
    Should Be Equal As Strings  ${response.json()['result']['rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_for']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['accused_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_name']}    DEVARAJAN K
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_father_name']}    KUPPAIYER G R
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_contact_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dl_rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_no']}    TN107563221009124224
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['state']}    TN
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_date']}    2022-10-09 00:00:00
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['offence']}    Driving a motor cycle without a protective headgear (helmet)/ Driving a motor cycle or causing or allowing a motor cycle to be driven in contravention of the provisions of section 129 of the Motor vehicles Act1988 ( u/s 194D ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['offence']}    Not producing. Driving Licence. Conductors Licence. Registration Certificate. permit. fitness certificate and insurance certificate on demand ( u/s 177 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['offence']}    Pillion Rider riding in a motor cycle without a protective headgear (helmet) Sec / Under 129 M V act 1988 ( U/Sec 129 MV Act 1988 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['investigate_under']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['long_lat']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_location']}    GH Bus Stop, Shevapet, Salem, Tamil Nadu 636001, India
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_remark']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['form_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_1']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_2']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_3']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_images']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV1_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV2_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_number']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_details']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['suspend_ISDL']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_father_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_age']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_gender']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_validity']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issue_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issued_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_amount']}    300
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['status']}    Paid
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_source']}    Card
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_date']}    2022-10-09 12:42:24
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['transaction_ID']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no_offline']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['offline_receipt']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['mobile_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ac_fIS']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_amount']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['RTO_name']}    Salem City
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_document']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_vehicle']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_class']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['permit_upto']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['chassis_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['engine_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_owner_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['father_owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_related_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['order_release_img']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['release_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_court_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['action_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dispatch_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['user_charges']}    ${EMPTY}

    Log To Console    ${EMPTY}
    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT tat FROM kyc_echallan_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    tat = ${row[0]}

    END


TC - MSME-T3724 (1.0)
    log to console    Verify the error is stored or not
     ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true

    # Read test data from CSV file
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    10    # Select the first row

    ${reg_no}=    Get From Dictionary    ${row}    reg_no
    ${client_ref_num}=    Get From Dictionary    ${row}    client_ref_num


    ${body}=    create dictionary    reg_no=${reg_no}    client_ref_num=${client_ref_num}
    ${header}=    create dictionary    Content-Type=application/json

    ${response}=    Post Request    mysession     ${endpoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${status_code}=    Set Variable    ${response.status_code}

    # Validations
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    200
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    Almond
    Should Be Equal As Strings  ${response.json()['result_code']}    103
    Should Be Equal As Strings  ${response.json()['message']}    No record found for the given input
    Log To Console    ${EMPTY}
    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT error FROM kyc_echallan_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    error = ${row[0]}

    END


TC - MSME-T3725 (1.0)
    log to console    To verify that the created_on and updated_on are updated properly.

    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "reg_no":"TN54M7497", "client_ref_num":"${random_client_ref_num}"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Post Request    mysession     ${endpoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${response_content}=    Set Variable    ${response.content}
    ${status_code}=    Set Variable    ${response.status_code}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${rc_number}=    Set Variable    ${response.json()['result']['rc_number']}

   # Validations
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    200
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}
    Should Be Equal As Strings  ${response.json()['result_code']}    101
    Should Be Equal As Strings  ${response.json()['result']['echallan_count']}    1
    Should Be Equal As Strings  ${response.json()['result']['rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_for']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['accused_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_name']}    DEVARAJAN K
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_father_name']}    KUPPAIYER G R
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_contact_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dl_rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_no']}    TN107563221009124224
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['state']}    TN
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_date']}    2022-10-09 00:00:00
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['offence']}    Driving a motor cycle without a protective headgear (helmet)/ Driving a motor cycle or causing or allowing a motor cycle to be driven in contravention of the provisions of section 129 of the Motor vehicles Act1988 ( u/s 194D ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['offence']}    Not producing. Driving Licence. Conductors Licence. Registration Certificate. permit. fitness certificate and insurance certificate on demand ( u/s 177 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['offence']}    Pillion Rider riding in a motor cycle without a protective headgear (helmet) Sec / Under 129 M V act 1988 ( U/Sec 129 MV Act 1988 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['investigate_under']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['long_lat']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_location']}    GH Bus Stop, Shevapet, Salem, Tamil Nadu 636001, India
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_remark']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['form_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_1']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_2']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_3']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_images']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV1_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV2_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_number']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_details']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['suspend_ISDL']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_father_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_age']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_gender']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_validity']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issue_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issued_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_amount']}    300
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['status']}    Paid
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_source']}    Card
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_date']}    2022-10-09 12:42:24
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['transaction_ID']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no_offline']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['offline_receipt']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['mobile_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ac_fIS']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_amount']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['RTO_name']}    Salem City
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_document']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_vehicle']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_class']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['permit_upto']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['chassis_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['engine_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_owner_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['father_owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_related_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['order_release_img']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['release_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_court_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['action_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dispatch_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['user_charges']}    ${EMPTY}

    Log To Console    ${EMPTY}
    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT created_on, updated_on FROM kyc_echallan_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    created_on = ${row[0]}
        Log To Console    updated_on = ${row[1]}

    END


TC - MSME-T3726 (1.0)
    log to console    Verify the echallan_request_log_id is stored or not

    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "reg_no":"TN54M7497", "client_ref_num":"${random_client_ref_num}"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Post Request    mysession     ${endpoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${response_content}=    Set Variable    ${response.content}
    ${status_code}=    Set Variable    ${response.status_code}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${rc_number}=    Set Variable    ${response.json()['result']['rc_number']}

   # Validations
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    200
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}
    Should Be Equal As Strings  ${response.json()['result_code']}    101
    Should Be Equal As Strings  ${response.json()['result']['echallan_count']}    1
    Should Be Equal As Strings  ${response.json()['result']['rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_for']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['accused_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_name']}    DEVARAJAN K
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_father_name']}    KUPPAIYER G R
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_contact_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dl_rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_no']}    TN107563221009124224
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['state']}    TN
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_date']}    2022-10-09 00:00:00
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['offence']}    Driving a motor cycle without a protective headgear (helmet)/ Driving a motor cycle or causing or allowing a motor cycle to be driven in contravention of the provisions of section 129 of the Motor vehicles Act1988 ( u/s 194D ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['offence']}    Not producing. Driving Licence. Conductors Licence. Registration Certificate. permit. fitness certificate and insurance certificate on demand ( u/s 177 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['offence']}    Pillion Rider riding in a motor cycle without a protective headgear (helmet) Sec / Under 129 M V act 1988 ( U/Sec 129 MV Act 1988 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['investigate_under']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['long_lat']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_location']}    GH Bus Stop, Shevapet, Salem, Tamil Nadu 636001, India
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_remark']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['form_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_1']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_2']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_3']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_images']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV1_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV2_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_number']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_details']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['suspend_ISDL']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_father_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_age']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_gender']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_validity']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issue_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issued_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_amount']}    300
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['status']}    Paid
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_source']}    Card
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_date']}    2022-10-09 12:42:24
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['transaction_ID']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no_offline']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['offline_receipt']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['mobile_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ac_fIS']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_amount']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['RTO_name']}    Salem City
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_document']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_vehicle']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_class']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['permit_upto']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['chassis_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['engine_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_owner_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['father_owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_related_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['order_release_img']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['release_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_court_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['action_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dispatch_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['user_charges']}    ${EMPTY}

    Log To Console    ${EMPTY}
    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT echallan_request_log_id FROM kyc_echallan_provider_log where http_status_code='${status_code}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    echallan_request_log_id = ${row[0]}

    END


TC - MSME-T3727 (1.0)
    log to console    Verify the echallan_request_log_id and id (kyc_echallan_api) same or not

    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "reg_no":"TN54M7497", "client_ref_num":"${random_client_ref_num}"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Post Request    mysession     ${endpoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${response_content}=    Set Variable    ${response.content}
    ${status_code}=    Set Variable    ${response.status_code}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${rc_number}=    Set Variable    ${response.json()['result']['rc_number']}

   # Validations
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    200
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}
    Should Be Equal As Strings  ${response.json()['result_code']}    101
    Should Be Equal As Strings  ${response.json()['result']['echallan_count']}    1
    Should Be Equal As Strings  ${response.json()['result']['rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_for']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['accused_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_name']}    DEVARAJAN K
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_father_name']}    KUPPAIYER G R
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_contact_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dl_rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_no']}    TN107563221009124224
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['state']}    TN
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_date']}    2022-10-09 00:00:00
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['offence']}    Driving a motor cycle without a protective headgear (helmet)/ Driving a motor cycle or causing or allowing a motor cycle to be driven in contravention of the provisions of section 129 of the Motor vehicles Act1988 ( u/s 194D ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['offence']}    Not producing. Driving Licence. Conductors Licence. Registration Certificate. permit. fitness certificate and insurance certificate on demand ( u/s 177 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['offence']}    Pillion Rider riding in a motor cycle without a protective headgear (helmet) Sec / Under 129 M V act 1988 ( U/Sec 129 MV Act 1988 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['investigate_under']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['long_lat']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_location']}    GH Bus Stop, Shevapet, Salem, Tamil Nadu 636001, India
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_remark']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['form_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_1']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_2']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_3']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_images']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV1_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV2_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_number']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_details']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['suspend_ISDL']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_father_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_age']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_gender']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_validity']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issue_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issued_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_amount']}    300
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['status']}    Paid
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_source']}    Card
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_date']}    2022-10-09 12:42:24
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['transaction_ID']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no_offline']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['offline_receipt']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['mobile_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ac_fIS']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_amount']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['RTO_name']}    Salem City
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_document']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_vehicle']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_class']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['permit_upto']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['chassis_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['engine_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_owner_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['father_owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_related_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['order_release_img']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['release_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_court_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['action_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dispatch_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['user_charges']}    ${EMPTY}

    Log To Console    ${EMPTY}
    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT id FROM kyc_echallan_api where http_response_code='${status_code}' AND client_ref_num='${client_ref_num}' order by id desc limit 1;
    ${sql_query2}=    Set Variable    SELECT echallan_request_log_id FROM kyc_echallan_provider_log where http_status_code='${status_code}' order by id desc limit 1;

    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    id = ${row[0]}


    END

    ${query_result2}=    Query    ${sql_query2}
      #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result2}
        Log To Console    echallan_request_log_id = ${row[0]}

    END


TC - MSME-T3728 (1.0)
    log to console    Verify the request_payload is stored or not

    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "reg_no":"TN54M7497", "client_ref_num":"${random_client_ref_num}"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Post Request    mysession     ${endpoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${response_content}=    Set Variable    ${response.content}
    ${status_code}=    Set Variable    ${response.status_code}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${rc_number}=    Set Variable    ${response.json()['result']['rc_number']}

   # Validations
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    200
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}
    Should Be Equal As Strings  ${response.json()['result_code']}    101
    Should Be Equal As Strings  ${response.json()['result']['echallan_count']}    1
    Should Be Equal As Strings  ${response.json()['result']['rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_for']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['accused_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_name']}    DEVARAJAN K
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_father_name']}    KUPPAIYER G R
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_contact_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dl_rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_no']}    TN107563221009124224
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['state']}    TN
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_date']}    2022-10-09 00:00:00
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['offence']}    Driving a motor cycle without a protective headgear (helmet)/ Driving a motor cycle or causing or allowing a motor cycle to be driven in contravention of the provisions of section 129 of the Motor vehicles Act1988 ( u/s 194D ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['offence']}    Not producing. Driving Licence. Conductors Licence. Registration Certificate. permit. fitness certificate and insurance certificate on demand ( u/s 177 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['offence']}    Pillion Rider riding in a motor cycle without a protective headgear (helmet) Sec / Under 129 M V act 1988 ( U/Sec 129 MV Act 1988 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['investigate_under']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['long_lat']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_location']}    GH Bus Stop, Shevapet, Salem, Tamil Nadu 636001, India
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_remark']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['form_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_1']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_2']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_3']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_images']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV1_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV2_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_number']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_details']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['suspend_ISDL']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_father_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_age']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_gender']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_validity']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issue_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issued_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_amount']}    300
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['status']}    Paid
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_source']}    Card
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_date']}    2022-10-09 12:42:24
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['transaction_ID']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no_offline']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['offline_receipt']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['mobile_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ac_fIS']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_amount']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['RTO_name']}    Salem City
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_document']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_vehicle']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_class']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['permit_upto']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['chassis_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['engine_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_owner_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['father_owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_related_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['order_release_img']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['release_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_court_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['action_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dispatch_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['user_charges']}    ${EMPTY}

    Log To Console    ${EMPTY}
    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT request_payload FROM kyc_echallan_provider_log where http_status_code='${status_code}' order by id desc limit 1;


    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    request_payload = ${row[0]}

    END


TC - MSME-T3729 (1.0)
    log to console    Verify the response_payload is stored or not

    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "reg_no":"TN54M7497", "client_ref_num":"${random_client_ref_num}"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Post Request    mysession     ${endpoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${response_content}=    Set Variable    ${response.content}
    ${status_code}=    Set Variable    ${response.status_code}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${rc_number}=    Set Variable    ${response.json()['result']['rc_number']}

   # Validations
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    200
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}
    Should Be Equal As Strings  ${response.json()['result_code']}    101
    Should Be Equal As Strings  ${response.json()['result']['echallan_count']}    1
    Should Be Equal As Strings  ${response.json()['result']['rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_for']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['accused_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_name']}    DEVARAJAN K
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_father_name']}    KUPPAIYER G R
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_contact_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dl_rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_no']}    TN107563221009124224
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['state']}    TN
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_date']}    2022-10-09 00:00:00
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['offence']}    Driving a motor cycle without a protective headgear (helmet)/ Driving a motor cycle or causing or allowing a motor cycle to be driven in contravention of the provisions of section 129 of the Motor vehicles Act1988 ( u/s 194D ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['offence']}    Not producing. Driving Licence. Conductors Licence. Registration Certificate. permit. fitness certificate and insurance certificate on demand ( u/s 177 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['offence']}    Pillion Rider riding in a motor cycle without a protective headgear (helmet) Sec / Under 129 M V act 1988 ( U/Sec 129 MV Act 1988 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['investigate_under']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['long_lat']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_location']}    GH Bus Stop, Shevapet, Salem, Tamil Nadu 636001, India
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_remark']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['form_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_1']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_2']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_3']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_images']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV1_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV2_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_number']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_details']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['suspend_ISDL']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_father_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_age']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_gender']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_validity']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issue_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issued_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_amount']}    300
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['status']}    Paid
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_source']}    Card
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_date']}    2022-10-09 12:42:24
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['transaction_ID']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no_offline']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['offline_receipt']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['mobile_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ac_fIS']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_amount']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['RTO_name']}    Salem City
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_document']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_vehicle']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_class']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['permit_upto']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['chassis_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['engine_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_owner_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['father_owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_related_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['order_release_img']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['release_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_court_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['action_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dispatch_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['user_charges']}    ${EMPTY}

    Log To Console    ${EMPTY}
    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT response_payload FROM kyc_echallan_provider_log where http_status_code='${status_code}' order by id desc limit 1;


    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    response_payload = ${row[0]}

    END

TC - MSME-T3730 (1.0)
    log to console    Verify the http_response_code is stored or not


    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "reg_no":"TN54M7497", "client_ref_num":"${random_client_ref_num}"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Post Request    mysession     ${endpoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${response_content}=    Set Variable    ${response.content}
    ${status_code}=    Set Variable    ${response.status_code}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${rc_number}=    Set Variable    ${response.json()['result']['rc_number']}

   # Validations
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    200
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}
    Should Be Equal As Strings  ${response.json()['result_code']}    101
    Should Be Equal As Strings  ${response.json()['result']['echallan_count']}    1
    Should Be Equal As Strings  ${response.json()['result']['rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_for']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['accused_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_name']}    DEVARAJAN K
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_father_name']}    KUPPAIYER G R
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_contact_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dl_rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_no']}    TN107563221009124224
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['state']}    TN
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_date']}    2022-10-09 00:00:00
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['offence']}    Driving a motor cycle without a protective headgear (helmet)/ Driving a motor cycle or causing or allowing a motor cycle to be driven in contravention of the provisions of section 129 of the Motor vehicles Act1988 ( u/s 194D ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['offence']}    Not producing. Driving Licence. Conductors Licence. Registration Certificate. permit. fitness certificate and insurance certificate on demand ( u/s 177 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['offence']}    Pillion Rider riding in a motor cycle without a protective headgear (helmet) Sec / Under 129 M V act 1988 ( U/Sec 129 MV Act 1988 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['investigate_under']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['long_lat']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_location']}    GH Bus Stop, Shevapet, Salem, Tamil Nadu 636001, India
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_remark']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['form_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_1']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_2']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_3']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_images']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV1_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV2_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_number']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_details']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['suspend_ISDL']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_father_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_age']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_gender']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_validity']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issue_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issued_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_amount']}    300
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['status']}    Paid
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_source']}    Card
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_date']}    2022-10-09 12:42:24
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['transaction_ID']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no_offline']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['offline_receipt']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['mobile_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ac_fIS']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_amount']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['RTO_name']}    Salem City
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_document']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_vehicle']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_class']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['permit_upto']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['chassis_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['engine_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_owner_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['father_owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_related_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['order_release_img']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['release_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_court_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['action_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dispatch_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['user_charges']}    ${EMPTY}

    Log To Console    ${EMPTY}
    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT http_status_code FROM kyc_echallan_provider_log where http_status_code='${status_code}' order by id desc limit 1;


    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    http_status_code = ${row[0]}

    END

TC - MSME-T3731 (1.0)
    log to console    verify the provider data is stored or not

    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "reg_no":"TN54M7497", "client_ref_num":"${random_client_ref_num}"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Post Request    mysession     ${endpoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${response_content}=    Set Variable    ${response.content}
    ${status_code}=    Set Variable    ${response.status_code}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${rc_number}=    Set Variable    ${response.json()['result']['rc_number']}

   # Validations
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    200
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}
    Should Be Equal As Strings  ${response.json()['result_code']}    101
    Should Be Equal As Strings  ${response.json()['result']['echallan_count']}    1
    Should Be Equal As Strings  ${response.json()['result']['rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_for']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['accused_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_name']}    DEVARAJAN K
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_father_name']}    KUPPAIYER G R
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_contact_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dl_rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_no']}    TN107563221009124224
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['state']}    TN
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_date']}    2022-10-09 00:00:00
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['offence']}    Driving a motor cycle without a protective headgear (helmet)/ Driving a motor cycle or causing or allowing a motor cycle to be driven in contravention of the provisions of section 129 of the Motor vehicles Act1988 ( u/s 194D ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['offence']}    Not producing. Driving Licence. Conductors Licence. Registration Certificate. permit. fitness certificate and insurance certificate on demand ( u/s 177 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['offence']}    Pillion Rider riding in a motor cycle without a protective headgear (helmet) Sec / Under 129 M V act 1988 ( U/Sec 129 MV Act 1988 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['investigate_under']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['long_lat']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_location']}    GH Bus Stop, Shevapet, Salem, Tamil Nadu 636001, India
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_remark']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['form_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_1']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_2']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_3']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_images']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV1_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV2_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_number']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_details']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['suspend_ISDL']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_father_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_age']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_gender']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_validity']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issue_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issued_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_amount']}    300
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['status']}    Paid
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_source']}    Card
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_date']}    2022-10-09 12:42:24
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['transaction_ID']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no_offline']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['offline_receipt']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['mobile_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ac_fIS']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_amount']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['RTO_name']}    Salem City
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_document']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_vehicle']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_class']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['permit_upto']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['chassis_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['engine_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_owner_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['father_owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_related_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['order_release_img']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['release_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_court_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['action_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dispatch_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['user_charges']}    ${EMPTY}

    Log To Console    ${EMPTY}
    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT provider FROM kyc_echallan_provider_log where http_status_code='${status_code}' order by id desc limit 1;


    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    provider = ${row[0]}

    END


TC - MSME-T3732 (1.0)
    log to console    To verify that the created_on and updated_on are updated properly

    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "reg_no":"TN54M7497", "client_ref_num":"${random_client_ref_num}"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Post Request    mysession     ${endpoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${response_content}=    Set Variable    ${response.content}
    ${status_code}=    Set Variable    ${response.status_code}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}
    ${rc_number}=    Set Variable    ${response.json()['result']['rc_number']}

   # Validations
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    200
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}
    Should Be Equal As Strings  ${response.json()['result_code']}    101
    Should Be Equal As Strings  ${response.json()['result']['echallan_count']}    1
    Should Be Equal As Strings  ${response.json()['result']['rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_for']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['accused_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_name']}    DEVARAJAN K
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_father_name']}    KUPPAIYER G R
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_contact_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dl_rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_no']}    TN107563221009124224
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['state']}    TN
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_date']}    2022-10-09 00:00:00
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['offence']}    Driving a motor cycle without a protective headgear (helmet)/ Driving a motor cycle or causing or allowing a motor cycle to be driven in contravention of the provisions of section 129 of the Motor vehicles Act1988 ( u/s 194D ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['offence']}    Not producing. Driving Licence. Conductors Licence. Registration Certificate. permit. fitness certificate and insurance certificate on demand ( u/s 177 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['offence']}    Pillion Rider riding in a motor cycle without a protective headgear (helmet) Sec / Under 129 M V act 1988 ( U/Sec 129 MV Act 1988 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['investigate_under']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['long_lat']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_location']}    GH Bus Stop, Shevapet, Salem, Tamil Nadu 636001, India
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_remark']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['form_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_1']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_2']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_3']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_images']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV1_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV2_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_number']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_details']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['suspend_ISDL']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_father_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_age']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_gender']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_validity']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issue_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issued_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_amount']}    300
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['status']}    Paid
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_source']}    Card
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_date']}    2022-10-09 12:42:24
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['transaction_ID']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no_offline']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['offline_receipt']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['mobile_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ac_fIS']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_amount']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['RTO_name']}    Salem City
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_document']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_vehicle']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_class']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['permit_upto']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['chassis_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['engine_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_owner_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['father_owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_related_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['order_release_img']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['release_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_court_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['action_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dispatch_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['user_charges']}    ${EMPTY}

    Log To Console    ${EMPTY}
    # Prepare SQL Query
    ${sql_query1}=    Set Variable    SELECT created_on, updated_on FROM kyc_echallan_provider_log where http_status_code='${status_code}' order by id desc limit 1;


    # Execute SQL Query
    ${query_result1}=    Query    ${sql_query1}
    #Log To Console    ${query_result}

    FOR    ${row}    IN    @{query_result1}
        Log To Console    created_on = ${row[0]}
        Log To Console    updated_on = ${row[0]}

    END


TC - MSME-T3733 (1.0)
    Log To Console    Verify by entering valid authentication
    ${auth}=    Create List    526526315047    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case34

TC - MSME-T3734 (1.0)
    Log To Console    Verify by entering invalid authentication
    ${auth}=    Create List    526526315047#    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case35

TC - MSME-T3736 (1.0)
    Log To Console    Verify by entering one client username and another client’s password
    ${auth}=    Create List    526526315047    EA6F34B4B3B618A10CF5C22232290778

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case36

TC - MSME-T3737 (1.0)
    Log To Console    Verify by entering a client that doesn’t have e challan validation service
    ${auth}=    Create List    14270240    oM6QTWR7iy2osBgLMVuqbAQ7aqkgFbZt

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case37

TC - MSME-T3738 (1.0)
    Log To Console    Verify by entering an empty username
    ${auth}=    Create List    ${EMPTY}    BI9WnuOcxLBKKgPEB4qtLdADGc9PH0d5

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case38

TC - MSME-T3739 (1.0)
    Log To Console    Verify by entering an empty password
    ${auth}=    Create List    526526315047    ${EMPTY}

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case39

TC - MSME-T3740 (1.0)
    Log To Console    Verify by entering both username and password as empty
    ${auth}=    Create List    ${EMPTY}    ${EMPTY}

    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0

    ${body}=    Create Dictionary    reg_no=${row['reg_no']}    client_ref_num=${row['client_ref_num']}
    Send Post Request And Validate    ${auth}    ${body}    ${json_schema_file}    case40


TC - MSME-T3741 (1.0)
    log to console    Verify by changing the request method from POST to GET
    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true

    # Read test data from CSV file
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0    # Select the first row

    ${reg_no}=    Get From Dictionary    ${row}    reg_no
    ${client_ref_num}=    Get From Dictionary    ${row}    client_ref_num


    ${body}=    create dictionary    reg_no=${reg_no}    client_ref_num=${client_ref_num}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Get Request    mysession     ${endpoint_url}   json=${body}    headers=${header}

    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    # Validations
    Should Be Equal As Strings    ${response.json()['message']}    API running successfully


TC - MSME-T3742 (1.0)
    log to console    Verify by changing from HTTPS to HTTP
    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    http://svcstage.digitap.work    auth=${auth}    verify=true

    # Read test data from CSV file
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0    # Select the first row

    ${reg_no}=    Get From Dictionary    ${row}    reg_no
    ${client_ref_num}=    Get From Dictionary    ${row}    client_ref_num


    ${body}=    create dictionary    reg_no=${reg_no}    client_ref_num=${client_ref_num}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Get Request    mysession     ${endpoint_url}   json=${body}    headers=${header}

    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    # Validations
    Should Be Equal As Strings    ${response.status_code}    503


TC - MSME-T3744 (1.0)
    log to console    Verify by changing the endpoint URL

    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}     auth=${auth}    verify=true

    # Read test data from CSV file
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0    # Select the first row

    ${reg_no}=    Get From Dictionary    ${row}    reg_no
    ${client_ref_num}=    Get From Dictionary    ${row}    client_ref_num


    ${body}=    create dictionary    reg_no=${reg_no}    client_ref_num=${client_ref_num}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Get Request    mysession     /validation/kyc/v1/echalla   json=${body}    headers=${header}

    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    # Validations
#    Should Be Equal As Strings    ${response.status_code}    503


TC - MSME-T3745 (1.0)
    log to console    Verify that the success response is returned within 5 seconds

    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true

    # Read test data from CSV file
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    0    # Select the first row

    ${reg_no}=    Get From Dictionary    ${row}    reg_no
    ${client_ref_num}=    Get From Dictionary    ${row}    client_ref_num


    ${body}=    create dictionary    reg_no=${reg_no}    client_ref_num=${client_ref_num}
    ${header}=    create dictionary    Content-Type=application/json

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

    # Validations
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    200
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    Almond
    Should Be Equal As Strings  ${response.json()['result_code']}    101
    Should Be Equal As Strings  ${response.json()['result']['echallan_count']}    1
    Should Be Equal As Strings  ${response.json()['result']['rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_for']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['accused_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_name']}    DEVARAJAN K
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_father_name']}    KUPPAIYER G R
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_contact_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dl_rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_no']}    TN107563221009124224
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['state']}    TN
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_date']}    2022-10-09 00:00:00
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['offence']}    Driving a motor cycle without a protective headgear (helmet)/ Driving a motor cycle or causing or allowing a motor cycle to be driven in contravention of the provisions of section 129 of the Motor vehicles Act1988 ( u/s 194D ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['offence']}    Not producing. Driving Licence. Conductors Licence. Registration Certificate. permit. fitness certificate and insurance certificate on demand ( u/s 177 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['offence']}    Pillion Rider riding in a motor cycle without a protective headgear (helmet) Sec / Under 129 M V act 1988 ( U/Sec 129 MV Act 1988 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['investigate_under']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['long_lat']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_location']}    GH Bus Stop, Shevapet, Salem, Tamil Nadu 636001, India
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_remark']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['form_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_1']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_2']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_3']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_images']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV1_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV2_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_number']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_details']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['suspend_ISDL']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_father_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_age']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_gender']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_validity']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issue_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issued_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_amount']}    300
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['status']}    Paid
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_source']}    Card
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_date']}    2022-10-09 12:42:24
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['transaction_ID']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no_offline']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['offline_receipt']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['mobile_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ac_fIS']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_amount']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['RTO_name']}    Salem City
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_document']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_vehicle']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_class']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['permit_upto']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['chassis_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['engine_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_owner_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['father_owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_related_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['order_release_img']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['release_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_court_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['action_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dispatch_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['user_charges']}    ${EMPTY}


TC - MSME-T3746 (1.0)
    log to console    Verify that the failure response is returned within 3 seconds
     ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true

    # Read test data from CSV file
    ${test_data}=    Read Test Data From CSV    ${file_path}
    ${row}=    Get From List    ${test_data}    10   # Select the first row

    ${reg_no}=    Get From Dictionary    ${row}    reg_no
    ${client_ref_num}=    Get From Dictionary    ${row}    client_ref_num


    ${body}=    create dictionary    reg_no=${reg_no}    client_ref_num=${client_ref_num}
    ${header}=    create dictionary    Content-Type=application/json

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

    # Validations
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    200
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    Almond
    Should Be Equal As Strings  ${response.json()['result_code']}    103
    Should Be Equal As Strings  ${response.json()['message']}    No record found for the given input


TC - MSME-T3747 (1.0)
    LOG TO CONSOLE    To verify test scenarios with a wheels_analytics_source_down
    ${auth}=    create list    ${client-username}    ${cLient-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "reg_no":"TN07CL5988", "client_ref_num":"${random_client_ref_num}", "test_scenario":"wheels_analytics_source_down"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Post Request    mysession     ${endPoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${response_content}=    Set Variable    ${response.content}
    ${status_code}=    Set Variable    ${response.status_code}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}


   #validation
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    503
    Should Be Equal As Strings  ${response.json()['error']}      Source is busy or unavailable. Try again later
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}


TC - MSME-T3748 (1.0)
    LOG TO CONSOLE    To verify test scenarios with a wheels_analytics_signin_failed
    ${auth}=    create list    ${client-username}    ${cLient-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "reg_no":"TN07CL5988", "client_ref_num":"${random_client_ref_num}", "test_scenario":"wheels_analytics_signin_failed"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Post Request    mysession     ${endPoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${response_content}=    Set Variable    ${response.content}
    ${status_code}=    Set Variable    ${response.status_code}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}


   #validation
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    500
    Should Be Equal As Strings  ${response.json()['error']}      Internal Error
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}


TC - MSME-T3749 (1.0)
    log to console    To verify test scenarios with a wheels_analytics_redis_token_failed
     ${auth}=    create list    ${client-username}    ${cLient-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "reg_no":"TN54M7497", "client_ref_num":"${random_client_ref_num}", "test_scenario":"wheels_analytics_redis_token_failed"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Post Request    mysession     ${endPoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${response_content}=    Set Variable    ${response.content}
    ${status_code}=    Set Variable    ${response.status_code}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}


   #validation
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    200
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}
    Should Be Equal As Strings  ${response.json()['result_code']}    101
    Should Be Equal As Strings  ${response.json()['result']['echallan_count']}    1
    Should Be Equal As Strings  ${response.json()['result']['rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_for']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['accused_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_name']}    DEVARAJAN K
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_father_name']}    KUPPAIYER G R
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violator_contact_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dl_rc_number']}    TN54M7497
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_no']}    TN107563221009124224
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['state']}    TN
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_date']}    2022-10-09 00:00:00
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['offence']}    Driving a motor cycle without a protective headgear (helmet)/ Driving a motor cycle or causing or allowing a motor cycle to be driven in contravention of the provisions of section 129 of the Motor vehicles Act1988 ( u/s 194D ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][0]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['offence']}    Not producing. Driving Licence. Conductors Licence. Registration Certificate. permit. fitness certificate and insurance certificate on demand ( u/s 177 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][1]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['offence']}    Pillion Rider riding in a motor cycle without a protective headgear (helmet) Sec / Under 129 M V act 1988 ( U/Sec 129 MV Act 1988 ) ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['violation_details'][2]['penalty']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['investigate_under']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['long_lat']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_location']}    GH Bus Stop, Shevapet, Salem, Tamil Nadu 636001, India
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_remark']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['book_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['form_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_1']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_2']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['witness_3']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_images']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV1_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['CCTV2_image']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_number']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_details']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['suspend_ISDL']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_father_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_age']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_acc_gender']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_validity']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issue_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['DL_issued_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['challan_amount']}    300
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['status']}    Paid
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_source']}    Card
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_date']}    2022-10-09 12:42:24
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['transaction_ID']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_no_offline']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['offline_receipt']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['mobile_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['payment_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ac_fIS']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_amount']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['ACF_receipt_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['RTO_name']}    Salem City
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_document']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['impound_vehicle']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_class']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_type']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['permit_upto']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['chassis_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['engine_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['vehicle_owner_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['father_owner_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['owner_address']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_related_id']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['order_release_img']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['release_date']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['receipt_court_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['action_by']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['dispatch_no']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['court_name']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['result']['data'][0]['user_charges']}    ${EMPTY}
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}


TC - MSME-T3750 (1.0)
    log to console    To verify test scenarios with a wheels_analytics_credits_expired.
    ${auth}=    create list    ${client-username}    ${cLient-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]
    ${body}=    Evaluate     { "reg_no":"TN07CL5988", "client_ref_num":"${random_client_ref_num}", "test_scenario":"wheels_analytics_credits_expired"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Post Request    mysession     ${endPoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${response_content}=    Set Variable    ${response.content}
    ${status_code}=    Set Variable    ${response.status_code}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}


   #validation
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    500
    Should Be Equal As Strings  ${response.json()['error']}      Internal Error
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}


TC - MSME-T3751 (1.0)
    log to console    To verify test scenarios with a timeout.

    ${auth}=    create list    ${client-username}    ${client-password}
    create session    mysession    ${base_url}    auth=${auth}    verify=true
    ${random_client_ref_num}=    Generate Random String    10    [LETTERS]

    ${body}=    Evaluate     { "reg_no":"TN07CL5988", "client_ref_num":"${random_client_ref_num}", "test_scenario":"timeout"}
    ${header}=    create dictionary    Content-Type=application/json
    ${response}=    Post Request    mysession     ${endPoint_url}   json=${body}    headers=${header}
    Log To Console    ${body}
    Log To Console    ${response.status_code}
    Log To Console    ${response.content}

    ${response_content}=    Set Variable    ${response.content}
    ${status_code}=    Set Variable    ${response.status_code}
    ${client_ref_num}=    Set Variable    ${response.json()['client_ref_num']}


   #validation
    ${result_body}=    convert to string    ${response.content}
    Should Be Equal As Strings  ${response.json()['http_response_code']}    503
    Should Be Equal As Strings  ${response.json()['error']}      Source is busy or unavailable. Try again later
    Should Be Equal As Strings  ${response.json()['client_ref_num']}    ${random_client_ref_num}