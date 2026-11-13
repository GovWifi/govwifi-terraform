CSR=$(awk 'NF {sub(/\r/, ""); printf "%s\\n", $0}' server.csr)

curl -sS -X POST \
  "https://www.digicert.com/services/v2/order/certificate/${ORDER_ID}/reissue" \
  -H "Content-Type: application/json" \
  -H "X-DC-DEVKEY: ${DIGICERT_API_KEY}" \
  -d '{
    "certificate": {
      "common_name": "example.com",
      "dns_names": ["www.example.com"],
      "csr": "'"${CSR}"'",
      "signature_hash": "sha256"
    }
  }' | jq .