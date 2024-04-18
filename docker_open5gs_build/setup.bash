#!/bin/bash
source color

function RUNNING() {
	bash ./COMMAND
	rm -f COMMAND
}

APN_INTERNET=1
APN_IMS=2
MCC=999
MNC=070


DOCKER_IP=$(ip address show docker0 | grep "inet " | sed "s#/# #" | awk '{print $2}')

#APN
echo -e "${BYellow}=> APN <=${Reset}"
echo "curl -X 'PUT' 'http://DOCKER_IP:8080/apn/' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"apn\": \"internet\", \"apn_ambr_dl\": 0, \"apn_ambr_ul\": 0 }'" > COMMAND;RUNNING
echo "curl -X 'PUT' 'http://DOCKER_IP:8080/apn/' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"apn\": \"ims\", \"apn_ambr_dl\": 0, \"apn_ambr_ul\": 0 }'" > COMMAND;RUNNING
echo
echo -e "${BRed}=> OTHER <=${Reset}"
MSISDN="MSISDN 00000001 00000002 00000003 00000004 00000005 00000006 00000007 00000008 00000009 00000010"
IMSI=$(cat raw.key | awk '{print $1}')
KI=$(cat raw.key | awk '{print $8}')
OPC=$(cat raw.key | awk '{print $9}')
COUNT=0
rm -f OSMOHLR COMMAND
for ID in $MSISDN ; do
	COUNT=$(( $COUNT + 1 ))
	if [[ "$COUNT" != "1" ]]; then
		# GET VALUE
		msisdn=$(echo $MSISDN | awk -v "COUNT=$COUNT" '{print $COUNT}')
		imsi=$(echo $IMSI | awk -v "COUNT=$COUNT" '{print $COUNT}')
		ki=$(echo $KI | awk -v "COUNT=$COUNT" '{print $COUNT}')
		opc=$(echo $OPC | awk -v "COUNT=$COUNT" '{print $COUNT}')

		echo "subscriber imsi $imsi create" >> OSMOHLR
		echo "subscriber imsi $imsi update msisdn $msisdn" >> OSMOHLR

		echo -e "${BYellow}=> HSS $msisdn <=${Reset}"
		docker exec -it hss misc/db/open5gs-dbctl add $imsi $ki $opc

		echo -e "${BYellow}=> AUC $msisdn <=${Reset}"
		echo "curl -X 'PUT' 'http://$DOCKER_IP:8080/auc/' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"ki\": \"$ki\", \"opc\": \"$opc\", \"amf\": \"8000\", \"sqn\": 0, \"imsi\": \"$imsi\" }'" > COMMAND;RUNNING
		# AUC_ID, NEED BY NEXT STEP
		echo "curl -X 'GET' 'http://$DOCKER_IP:8080/auc/imsi/$imsi' -H 'accept: application/json' | awk '{print \$8}'| sed \"s#,##\"" > COMMAND
		auc_id=$(RUNNING)
		#echo -e $BRed$auc_id$Reset
		
		echo -e "${BYellow}=> subscriber $msisdn <=${Reset}"
		echo "curl -X 'PUT' 'http://$DOCKER_IP:8080/subscriber/' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"imsi\": \"$imsi\", \"enabled\": true, \"auc_id\": $auc_id, \"default_apn\": $APN_INTERNET, \"apn_list\": \"$APN_INTERNET,$APN_IMS\", \"msisdn\": \"$msisdn\", "ue_ambr_dl": 0, "ue_ambr_ul": 0 }'" > COMMAND;RUNNING
		
		echo -e "${BYellow}=> ims_subscriber $msisdn <=${Reset}"
		echo "curl -X 'PUT' 'http://$DOCKER_IP:8080/ims_subscriber/' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"imsi\": \"$imsi\", \"msisdn\": \"$msisdn\", \"sh_profile\": \"string\", \"scscf_peer\": \"scscf.ims.mnc${MNC}.mcc${MCC}.3gppnetwork.org\", \"msisdn_list\": \"[${msisdn}]\", \"ifc_path\": \"default_ifc.xml\", \"scscf\": \"sip:scscf.ims.mnc${MNC}.mcc${MCC}.3gppnetwork.org:6060\", \"scscf_realm\": \"ims.mnc${MNC}.mcc${MCC}.3gppnetwork.org\" }'"
	fi
done
