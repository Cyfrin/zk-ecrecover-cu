#!/bin/bash

input_file="inputs.txt"
output_file="Prover.toml"

# Extract only the value inside quotes for a given key
extract_value() {
    local key=$1
    # Extract the part inside quotes after the equals sign
    grep "^$key\s*=" "$input_file" | sed -E 's/^[^=]+= *"(.*)"/\1/'
}

# Convert hex string (without 0x) to quoted decimal byte array
hex_to_dec_quoted_array() {
    local hexstr=$1
    local len=${#hexstr}
    local arr=()
    for (( i=0; i<len; i+=2 )); do
        # Extract two hex digits
        local hexbyte="${hexstr:i:2}"
        # Convert hex to decimal number
        local dec=$((16#$hexbyte))
        # Add decimal number as quoted string
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
