curl -sS -X POST \
  "https://www.digicert.com/services/v2/order/certificate/ssl" \
  -H "Content-Type: application/json" \
  -H "X-DC-DEVKEY: ${DIGICERT_API_KEY}" \
  -d '{
    "certificate": {
      "common_name": "example.com",
      "dns_names": ["www.example.com"],
      "csr": "'"${CSR}"'",
      "signature_hash": "sha256"
    },
    "renewal_of_order_id": '"${ORDER_ID}"',
    "skip_approval": false
  }' | jq .

## https://dev.digicert.com/certcentral-apis/services-api/orders/order-ssl-type_hint.html