#!/bin/bash
cat <<EOF
{
  "user": "${USER#*\\}",
  "hostname": "${HOSTNAME}"
}
EOF
