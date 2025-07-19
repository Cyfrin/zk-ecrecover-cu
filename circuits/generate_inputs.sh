#!/bin/bash
set -euo pipefail

input_file="inputs.txt"
output_file="Prover.toml"

# Extract only the value inside quotes for a given key
extract_value() {
    local key=$1
    local value=$(grep -E "^$key\s*=" "$input_file" | head -n 1 | cut -d '"' -f2)
    echo "$value"
}

# Convert hex string (without 0x) to quoted decimal byte array
hex_to_dec_quoted_array() {
    local hexstr=$1
    local len=${#hexstr}
    local arr=()

    # If the length is odd, we add a 0 at the beginning
    if (( len % 2 != 0 )); then
        hexstr="0$hexstr"
        len=${#hexstr}
    fi

    for (( i=0; i<len; i+=2 )); do
        local hexbyte="${hexstr:$i:2}"

        # Strict byte validation
        if [[ ! "$hexbyte" =~ ^[0-9a-fA-F]{2}$ ]]; then
            echo "Error: '$hexbyte' is not a valid hexadecimal byte (index $i of the string '$hexstr')" >&2
            continue
        fi

        local dec=$((16#$hexbyte))
        arr+=("\"$dec\"")
    done

    echo "["$(IFS=,; echo "${arr[*]}")"]"
}

# Read values from file
expected_address=$(extract_value expected_address)
hashed_message=$(extract_value hashed_message)
pub_key_x=$(extract_value pub_key_x)
pub_key_y=$(extract_value pub_key_y)
signature=$(extract_value signature)

# Strip 0x from everything except expected_address
hashed_message=${hashed_message#0x}
pub_key_x=${pub_key_x#0x}
pub_key_y=${pub_key_y#0x}
signature=${signature#0x}

# Validate signature length
sig_len=${#signature}
if (( sig_len < 130 )); then
    echo "Error: Invalid signature length ($sig_len characters)" >&2
    exit 1
fi

# Strip last byte (2 hex chars) from signature to remove v
signature=${signature:0:${#signature}-2}

# Convert hex strings to decimal quoted arrays
hashed_message_arr=$(hex_to_dec_quoted_array "$hashed_message")
pub_key_x_arr=$(hex_to_dec_quoted_array "$pub_key_x")
pub_key_y_arr=$(hex_to_dec_quoted_array "$pub_key_y")
signature_arr=$(hex_to_dec_quoted_array "$signature")

# Write output
cat > "$output_file" <<EOF
expected_address = "$expected_address"
hashed_message = $hashed_message_arr
pub_key_x = $pub_key_x_arr
pub_key_y = $pub_key_y_arr
signature = $signature_arr
EOF

echo "Wrote $output_file"
