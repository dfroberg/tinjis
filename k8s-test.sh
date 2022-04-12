#!/bin/bash
echo -e "► Starting tests"

TEST_PATHS=$(cat <<'EOT'
rest/health
rest/v1/Customers
rest/v1/Customers/1
rest/v1/invoices
rest/v1/invoices/1
EOT
)
TMPF="/tmp/content.txt"
touch $TMPF 

if test -f "$TMPF"; then
    echo "  Buffer file $TMPF exists."
else
    echo "  Can't create buffer file $TMPF aborting tests."
    exit 1
fi
echo "► Waiting up to 240s for antaeus deployments to be ready..."
kubectl wait -n payments --timeout=240s --for=condition=available deployment --all |  sed 's/^/  /'

NOTICE=0
RUNTESTS=false

echo -e "► Testing Antaeus availability..."
ANTAEUS_POD=$(kubectl -n payments get pods --field-selector status.phase=Running -l app=antaeus -o jsonpath='{.items[*].metadata.name}')
if [ -z "$ANTAEUS_POD" ]; then
    echo -e "  Antaeus Not yet available"
    exit 1
fi
ANTAEUS_PORT=$(kubectl get pod $ANTAEUS_POD -n payments --template='{{(index (index .spec.containers 0).ports 0).containerPort}}{{"\n"}}')
ANTAEUS_IMAGE=$(kubectl get pods -n payments -o json | jq -r '.items[] | select(.metadata.name | test("antaeus-")).spec.containers[].image')
ANTAEUS_SVC=$(kubectl -n payments get svc -l app=antaeus -o jsonpath='{.items[*].metadata.name}')
ANTAEUS_SVC_PORT=$(kubectl get svc -n payments -o json | jq -r '.items[] | select(.metadata.name | test("antaeus-service")).spec.ports[].targetPort')
ANTAEUS_INGRESS=$(kubectl -n payments get ingress -l app=antaeus -o jsonpath='{.items[*].metadata.name}')
PAYMENT_POD=$(kubectl -n payments get pods --field-selector status.phase=Running -l app=payments -o jsonpath='{.items[*].metadata.name}')
if [ -z "$PAYMENT_POD" ]; then
    echo -e "  Payment Not yet available"
    exit 1
fi
PAYMENT_PORT=$(kubectl get pod $PAYMENT_POD -n payments --template='{{(index (index .spec.containers 0).ports 0).containerPort}}{{"\n"}}')
PAYMENT_IMAGE=$(kubectl get pods -n payments -o json | jq -r '.items[] | select(.metadata.name | test("payments-")).spec.containers[].image')
PAYMENT_SVC=$(kubectl -n payments get svc -l app=payments -o jsonpath='{.items[*].metadata.name}')
PAYMENT_SVC_PORT=$(kubectl get svc -n payments -o json | jq -r '.items[] | select(.metadata.name | test("payments-")).spec.ports[].targetPort')

echo -e "  $ANTAEUS_POD using $ANTAEUS_IMAGE image is available on port $ANTAEUS_PORT"
echo -e "  $ANTAEUS_SVC is available on port $ANTAEUS_SVC_PORT"
echo -e "► Testing Payment availability..."
echo -e "  $PAYMENT_POD using $PAYMENT_IMAGE image is available on port $PAYMENT_PORT"
echo -e "  $PAYMENT_SVC is available on port $PAYMENT_SVC_PORT"
echo -e "► Testing accessibility..."
# Check for Javalin has started
#kubectl logs -n payments $ANTAEUS_POD
#
# If the antaeus-test-service is deployed it's likely an automated test and has no ingress or portforward.
ANTAEUS_POD_HOST_IP=$(kubectl -n payments get pods --field-selector status.phase=Running -l app=antaeus -o jsonpath='{.items[*].status.hostIP}')
ANTAEUS_TEST_SVC_IP=$(kubectl -n payments get svc -o json | jq -r '.items[] | select(.metadata.name | test("antaeus-test-service")).spec.clusterIP')
ANTAEUS_TEST_SVC_NODEPORT=$(kubectl -n payments get svc -o json | jq -r '.items[] | select(.metadata.name | test("antaeus-test-service")).spec.ports[0].nodePort')
ANTAEUS_SVC_NODEPORT=$(kubectl get svc -n payments -o json | jq -r '.items[] | select(.metadata.name | test("antaeus-service")).spec.ports[].nodePort')
ANTAEUS_INGRESS_HOST=$(kubectl -n payments get ingress -l app=antaeus -o json | jq -r '.items[] | select(.metadata.name | test("antaeus-ingress")).spec.rules[].host')
#
# If this auto detect of PF won't do it, simply uncomment the next line and comment the auto detect
# TEST_PORTFORWARD=31811
#
TEST_PORTFORWARD=$(ps -aux | grep -v "grep" | grep "kubectl port-forward -n payments service/antaeus-service" | awk -F ":" '{print $3}' | awk -F " " '{print $7}')
if [ -z "$TEST_PORTFORWARD" ]; then
    TEST_PORTFORWARD=$(ps -aux | grep -v "grep" | grep "kubectl port-forward -n payments service/antaeus-test-service" | awk -F ":" '{print $3}' | awk -F " " '{print $7}')
fi
# PF overrides ingress
if [ -z "$TEST_PORTFORWARD" ]; then
    if [ -z "$ANTAEUS_INGRESS" ]; then
        echo -e " ✔ No Ingress defined"
        unset TEST_HOST
    else
        echo -e " ✔ Ingress: $ANTAEUS_INGRESS defined and is exposed on host $ANTAEUS_INGRESS_HOST"
        TEST_HOST="$ANTAEUS_INGRESS_HOST"
    fi
else
    TEST_HOST="localhost:$TEST_PORTFORWARD"
fi
# Check to see if we have anything
if [ -z "$TEST_HOST" ]; then
    echo -e " ✔ No Host defined"
else
    # Ok we have a host, lets check if it works...
    TEST_URL="http://$TEST_HOST/rest/health"
    echo -e " ✔ Host defined $TEST_URL"
    HTTP_STATUS=$(curl -k -I -L -X GET -q --max-time 5 -s -w '%{http_code}' -o ${TMPF} $TEST_URL)
    if [ $HTTP_STATUS -ne 200 ]; then
        echo -e " X Failed [$HTTP_STATUS]"
        RUNTESTS=false
    else
        echo -e " ✔ Passed [$HTTP_STATUS]"
        RUNTESTS=true
    fi
fi

# Ok that didn't work lets try alternatives
if [ $RUNTESTS == false ]; then
    ANTAEUS_TEST_SVC_NODEPORT=$(kubectl get svc -n payments -o json | jq -r '.items[] | select(.metadata.name | test("antaeus-test-service")).spec.ports[].nodePort')
    if [ -z $ANTAEUS_TEST_SVC_NODEPORT ]; then
        # No antaeus-test-service found
        ANTAEUS_SVC_IP=$(kubectl -n payments get pods --field-selector status.phase=Running -l app=antaeus -o jsonpath='{.items[*].status.hostIP}')
        ANTAEUS_SVC_PORT=$(kubectl get svc -n payments -o json | jq -r '.items[] | select(.metadata.name | test("antaeus-service")).spec.ports[].port')
        TEST_HOST="$ANTAEUS_SVC_IP:$ANTAEUS_SVC_PORT"
        # Ok we have a host, lets check if it works...
        TEST_URL="http://$TEST_HOST/rest/health"
        echo -e "  - Testing $TEST_URL"
        HTTP_STATUS=$(curl -k -I -L -X GET -q --max-time 5 -s -w '%{http_code}' -o ${TMPF} $TEST_URL)
        if [ $HTTP_STATUS -ne 200 ]; then
            # Lets patch first
            kubectl patch svc antaeus-service -n payments -p '{"spec":{"type":"NodePort"}}'
            kubectl patch svc antaeus-service -n payments -p '{"spec":{"externalTrafficPolicy":"Local"}}'
            ANTAEUS_SVC_IP=$(kubectl -n payments get pods --field-selector status.phase=Running -l app=antaeus -o jsonpath='{.items[*].status.hostIP}')
            ANTAEUS_SVC_NODEPORT=$(kubectl get svc -n payments -o json | jq -r '.items[] | select(.metadata.name | test("antaeus-service")).spec.ports[].nodePort')
            TEST_HOST="$ANTAEUS_SVC_IP:$ANTAEUS_SVC_NODEPORT"
        fi
    else
        # antaeus-test-service found
        # Lets patch first
        kubectl patch svc antaeus-test-service -n payments -p '{"spec":{"type":"NodePort"}}'
        kubectl patch svc antaeus-test-service -n payments -p '{"spec":{"externalTrafficPolicy":"Local"}}'
        ANTAEUS_TEST_SVC_IP=$(kubectl -n payments get pods --field-selector status.phase=Running -l app=antaeus -o jsonpath='{.items[*].status.hostIP}')
        ANTAEUS_TEST_SVC_NODEPORT=$(kubectl get svc -n payments -o json | jq -r '.items[] | select(.metadata.name | test("antaeus-test-service")).spec.ports[].nodePort')
        TEST_HOST="$ANTAEUS_TEST_SVC_IP:$ANTAEUS_TEST_SVC_NODEPORT"
    fi
    # Ok we have a host, lets check if it works...
    TEST_URL="http://$TEST_HOST/rest/health"
    echo -e "  - Testing  $TEST_URL"
    HTTP_STATUS=$(curl -k -I -L -X GET -q --max-time 5 -s -w '%{http_code}' -o ${TMPF} $TEST_URL)

    if [ $HTTP_STATUS -ne 200 ]; then
        echo -e " X Failed [$HTTP_STATUS]"
        RUNTESTS=false
    else
        echo -e " ✔ Passed [$HTTP_STATUS]"
        RUNTESTS=true
    fi
fi
echo -e "- Gathered Test Host Endpoint:  $TEST_HOST"

if [ -z "$TEST_HOST" ]; then
    echo -e "► No ingress - Please run either of the below to continue"
    echo -e "  Open a new terminal and run;"
    echo -e "    kubectl port-forward -n payments service/$ANTAEUS_SVC 31811:$ANTAEUS_SVC_PORT"
    echo -e "  or; "
    echo -e "    kubectl apply -f manifests/antaeus-ingress.yaml"
    echo -e "Please Rerun Test"
else
    echo -e "► Testing API Endpoints:"
    for p in $TEST_PATHS
    do
        TEST_URL="http://${TEST_HOST}/${p}"
        echo -e -n "► Testing ${TEST_URL} ..."
        HTTP_STATUS=""
        HTTP_STATUS=$(curl -k -L -X GET -q --max-time 5 -s -w '%{http_code}' -o ${TMPF} ${TEST_URL})
        CONTENT=$(< ${TMPF})
        if [ $HTTP_STATUS -ne 200 ]
        then
            echo -e " X Failed [$HTTP_STATUS]"
            echo -e "  Got: $CONTENT"
            echo -e "  Antaeus service is quite slow to build ~1 minute or something is really wrong, check and try again."
            exit 1
        else
            echo -e " ✔ Passed [$HTTP_STATUS]"
            echo -e "  ---\n  $CONTENT\n  ---"
        fi
        echo -e "  ✔ Done"
    done
    echo -e "► Testing Payments: Show distribution of INVOICE_STATUS"
    for p in "rest/v1/invoices"
    do
        TEST_URL="http://$TEST_HOST/$p"
        echo -e -n "► Calling $TEST_URL ..."
        for i in {1..1}
        do
            HTTP_STATUS=""
            HTTP_STATUS=$(curl -k -L -X GET -q --max-time 5 -s -w '%{http_code}' -o ${TMPF} ${TEST_URL})
            CONTENT=$(< ${TMPF})
            if [ $HTTP_STATUS -ne 200 ]; then
                echo -e "X Failed testing, Got Code $HTTP_STATUS "
                exit 1
            else
                if [ "$CONTENT" == "" ]; then
                    echo -e " x Reachable but empty reply [$HTTP_STATUS]"
                else
                    echo -e " ✔ Passed [$HTTP_STATUS]"
                    PAYMENT_STATUS=$(echo $CONTENT | jq '.[].status' | sort | uniq -c | awk -F " " '{print "{\"status\":" $2 ",\"count\":" $1"}"}'| jq .)
                    #echo -e "---\n$PAYMENT_STATUS\n---\n"
                    x=($(echo $PAYMENT_STATUS | jq -r '.[] | .' ))
                    if [ ${#x[@]} -gt 2 ]; then
                        echo "  Invoices ${x[0]}=${x[1]} & ${x[2]}=${x[3]}"
                    else
                        echo "  All Invoices ${x[0]}=${x[1]}"
                        NOTICE=1
                    fi
                fi
            fi

        done
        echo -e "  ✔ Done"
    done
    echo -e "► Testing Payments: Making a payment call"
    for p in "rest/v1/invoices/pay"
    do
        TEST_URL="http://$TEST_HOST/$p"
        echo -e -n "► Calling $TEST_URL ..."
        for i in {1..1}
        do
            HTTP_STATUS=""
            HTTP_STATUS=$(curl -k -L -X POST -q --max-time 5 -s -w '%{http_code}' -o ${TMPF} ${TEST_URL})
            CONTENT=$(< ${TMPF})
            if [ $HTTP_STATUS -gt 200 ]; then
                echo -e "X Failed testing, Got Code $HTTP_STATUS "
                exit 1
            else
                if [ "$CONTENT" == "" ]; then
                    echo -e " x Reachable but empty reply [$HTTP_STATUS]"
                else
                    echo -e " ✔ Passed [$HTTP_STATUS]"
                    if [ "$CONTENT" == "true" ]; then
                        echo -e "  Returned $CONTENT, Successfuly paid all invoices"
                        NOTICE=1
                    else
                         echo -e "  Returned $CONTENT, Not all invoices paid successfuly"
                    fi
                fi
            fi
        done
        echo -e "  ✔ Done"
    done
    echo -e "► Testing Payments: Show distribution of INVOICE_STATUS"
    for p in "rest/v1/invoices"
    do
        TEST_URL="http://$TEST_HOST/$p"
        echo -e -n "► Calling $TEST_URL ..."
        for i in {1..1}
        do
            HTTP_STATUS=""
            HTTP_STATUS=$(curl -k -L -X GET -q --max-time 5 -s -w '%{http_code}' -o ${TMPF} ${TEST_URL})
            CONTENT=$(< ${TMPF})
            if [ $HTTP_STATUS -ne 200 ]; then
                echo -e "X Failed testing, Got Code $HTTP_STATUS "
                exit 1
            else
                if [ "$CONTENT" == "" ]; then
                    echo -e " x Reachable but empty reply [$HTTP_STATUS]"
                else
                    echo -e " ✔ Passed [$HTTP_STATUS]"
                    PAYMENT_STATUS=$(echo $CONTENT | jq '.[].status' | sort | uniq -c | awk -F " " '{print "{\"status\":" $2 ",\"count\":" $1"}"}'| jq .)
                    #echo -e "---\n$PAYMENT_STATUS\n---\n"
                    x=($(echo $PAYMENT_STATUS | jq -r '.[] | .' ))
                    if [ ${#x[@]} -gt 2 ]; then
                        echo "  Invoices ${x[0]}=${x[1]} & ${x[2]}=${x[3]}"
                    else
                        echo "  All Invoices ${x[0]}=${x[1]}"
                        NOTICE=1
                    fi
                fi
            fi

        done
        echo -e "  ✔ Done"
    done
    #kubectl logs -n payments $ANTAEUS_POD
    echo -e "✔ All Tests Done"
    rm $TMPF
    if [ $NOTICE -gt 0 ]; then
        echo -e "\n*** NOTICE: ***"
        echo "It seems all invoices now have the status PAID, restart the ANTAEUS_POD if you wish to retry the test."
        echo "kubectl delete pod $ANTAEUS_POD -n payments "
        echo -e "\n\n"
    fi
fi
