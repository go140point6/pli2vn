#!/bin/bash
#set -x

PLI_VARS_FILE="plinode_$(hostname -f).vars"
source ~/$PLI_VARS_FILE

GREEN='\033[0;32m'
NC='\033[0m' # No Color
RAND_NUM=$((1 + $RANDOM % 10000))
JOB_TITLE="cryptocompare_XDC_USD_test_$RAND_NUM"
JOB_FNAME="pli2vn_testjob_CC_USD_XDC.toml"

#clear
echo -e "${GREEN}#"
echo -e "#   This script generates the necessary json blob for the Job-Setup section in the docs"
echo -e "#   source: https://docs.goplugin.co/oracle/job-setup"
echo -e "#"
echo -e "#   The script checks for leading  / trailing white spaces and removes as necessary"
echo -e "#   & converts the 'xdc' prefix to '0x' as necessary"
echo -e "#"
echo -e "#${NC}"
sleep 0.5s
source ~/"plinode_$(hostname -f)".vars
read -p 'Enter your Oracle Contract Address : ' _INPUT
ORACLE_ADDR="$(echo $_INPUT | sed '/^$/d;/^\\\s*$/d;s/^xdc/0x/g')"
#echo "$_INPUT"
#echo "$ORACLE_ADDR"
#diff -u <(echo "$_INPUT") <(echo "$ORACLE_ADDR") > /dev/null 2>&1
#sleep 2s

cat <<EOF > ~/$JOB_FNAME
type = "directrequest"
schemaVersion = 1
name = "$JOB_TITLE"
maxTaskDuration = "0s"
contractAddress = "$ORACLE_ADDR"
minIncomingConfirmations = 0
observationSource = """
    decode_log   [type="ethabidecodelog"
                  abi="OracleRequest(bytes32 indexed specId, address requester, bytes32 requestId, uint256 payment, address callbackAddr, bytes4 callbackFunctionId, uint256 cancelExpiration, uint256 dataVersion, bytes data)"
                  data="\$(jobRun.logData)"
                  topics="\$(jobRun.logTopics)"]

    decode_cbor  [type="cborparse" data="\$(decode_log.data)"]
    fetch        [type="http" method=GET url="https://min-api.cryptocompare.com/data/price?fsym=XDC&tsyms=USD" allowUnrestrictedNetworkAccess="true"]
    parse        [type="jsonparse" path="USD" data="\$(fetch)"]

    multiply     [type="multiply" input="\$(parse)" times="\$(decode_cbor.times)"]

    encode_data  [type="ethabiencode" abi="(bytes32 requestId, uint256 value)" data="{ \\\"requestId\\\": \$(decode_log.requestId), \\\"value\\\": \$(multiply) }"]
    encode_tx    [type="ethabiencode"
                  abi="fulfillOracleRequest2(bytes32 requestId, uint256 payment, address callbackAddress, bytes4 callbackFunctionId, uint256 expiration, bytes calldata data)"
                  data="{\\\"requestId\\\": \$(decode_log.requestId), \\\"payment\\\":   \$(decode_log.payment), \\\"callbackAddress\\\": \$(decode_log.callbackAddr), \\\"callbackFunctionId\\\": \$(decode_log.callbackFunctionId), \\\"expiration\\\": \$(decode_log.cancelExpiration), \\\"data\\\": \$(encode_data)}"
                  ]
    submit_tx    [type="ethtx" to="$ORACLE_ADDR" data="\$(encode_tx)"]

    decode_log -> decode_cbor -> fetch -> parse -> multiply -> encode_data -> encode_tx -> submit_tx
"""
EOF
#sleep 1s
#echo
#echo " Local node json blob for AlarmClockSample job - Reference only"
#echo
#cat ~/$JOB_FNAME

plugin admin login -f $PLI_DEPLOY_PATH/apicredentials.txt 
plugin jobs create ~/$JOB_FNAME > /tmp/plivn_job_id.raw
#plugin jobs list 
ext_job_id="$(sudo -u postgres -i psql -d plugin_mainnet_db -t -c "SELECT external_job_id FROM jobs WHERE name = '$JOB_TITLE';")"

echo -e "${GREEN}#"
echo -e "Local node job id - Copy to your Solidity script"
echo -e "================================================================="
echo -e 
echo -e "Oracle Contract Address is :   $ORACLE_ADDR"
echo -e "Job $JOB_TITLE ID is :   $ext_job_id ${NC}"
echo 
echo 