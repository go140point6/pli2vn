#!/bin/bash

# Set Colour Vars
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color


FUNC_RPC_MENU(){

        FUNC_SET_FILE;
        
        while true; do
            echo -e "${GREEN}       ##${NC}"
            echo -e "${GREEN}       ##  This script sets the WS & RPC server configuration & chain ID based on the selected option ${NC}"
            echo -e "${GREEN}       ##  below. The script will overwrite the existing values with those of the selected option ..${NC}"
            echo -e "${GREEN}       ##${NC}"
            echo
            echo -e "${GREEN}       ##  1 -- Set to 'Mainnet' option ${NC}"
            echo -e "${GREEN}       ##  2 -- Set to 'Apothem' option ${NC}"
            echo
            read -t30 -r -p "       Enter the option NUMBER from the list above : " _RES_INPUT
            if [ $? -gt 128 ]; then
                #clear
                echo
                echo
                echo "      ....timed out waiting for user response - please select a NUMBER from the list... exiting"
                #echo "....timed out waiting for user response - proceeding as standard in-place restore to existing system..."
                echo
                #DR_RESTORE=false
                #FUNC_RPC_MENU;
                FUNC_EXIT_ERROR
            fi
            case $_RES_INPUT in
                1* )
                    VARVAL_CHAIN_NAME=$(mainnet_name)
                    VARVAL_CHAIN_ID=$(mainnet_ChainID)
                    VARVAL_CONTRACT_ADDR=$(mainnet_ContractAddress)
                    VARVAL_RPC=$(mainnet_httpUrl)
                    VARVAL_WSS=$(mainnet_wsUrl)
                    break
                    ;;
                2* ) 
                    VARVAL_CHAIN_NAME=$(testnet_name)
                    VARVAL_CHAIN_ID=$(testnet_ChainID)
                    VARVAL_CONTRACT_ADDR=$(testnet_ContractAddress)
                    VARVAL_RPC=$(testnet_httpUrl)
                    VARVAL_WSS=$(testnet_wsUrl)
                    break
                    ;;
                * ) echo -e "${RED}  please select a NUMBER from the list${NC}";;
            esac
        done

        FUNC_SED_FILE;
}




FUNC_SET_FILE(){

    PLI_VARS_FILE="plinode_$(hostname -f)".vars
    if [ ! -e ~/$PLI_VARS_FILE ]; then
        #clear
        echo
        echo -e "${RED} #### ERROR : No VARIABLES file found. ####${NC}"
        echo 

        FUNC_EXIT_ERROR
    fi

    source ~/$PLI_VARS_FILE
}  


FUNC_SED_FILE(){

    #ChainID
    #LinkContractAddress
    #name
    #wsUrl
    #httpUrl

    RAND_NUM=$((1 + $RANDOM % 10000))
    BKUP_FILE="$PLI_DEPLOY_PATH/$BASH_FILE3_$RAND_NUM"
    cp $PLI_DEPLOY_PATH/$BASH_FILE3 $BKUP_FILE

    sed  -i 's|^ChainID.*|ChainID = '$VARVAL_CHAIN_ID'|g' $PLI_DEPLOY_PATH/$BASH_FILE3

    cat $PLI_DEPLOY_PATH/$BASH_FILE3 | grep ChainID

    sed  -i 's|^LinkContractAddress.*|LinkContractAddress = "'$VARVAL_CONTRACT_ADDR'"|g' $PLI_DEPLOY_PATH/$BASH_FILE3

    cat $PLI_DEPLOY_PATH/$BASH_FILE3 | grep LinkContractAddress

    sed  -i 's|^name.*|name = "'$VARVAL_CHAIN_NAME'"|g' $PLI_DEPLOY_PATH/$BASH_FILE3

    cat $PLI_DEPLOY_PATH/$BASH_FILE3 | grep name

    sed  -i 's|^wsUrl.*|wsUrl = "'$VARVAL_WSS'"|g' $PLI_DEPLOY_PATH/$BASH_FILE3

    cat $PLI_DEPLOY_PATH/$BASH_FILE3 | grep wsUrl

    sed  -i 's|^httpUrl.*|httpUrl = '$VARVAL_WSS'|g' $PLI_DEPLOY_PATH/$BASH_FILE3

    cat $PLI_DEPLOY_PATH/$BASH_FILE3 | grep httpUrl

    pm2 restart all
    pm2 reset all
    pm2 list

    #cat ~/plugin-deployment/$BASH_FILE2 | grep ETH_URL && cat ~/plugin-deployment/$BASH_FILE3 | grep https

}


FUNC_EXIT_ERROR(){
	exit 1
}

FUNC_RPC_MENU;