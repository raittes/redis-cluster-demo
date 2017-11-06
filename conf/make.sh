print_conf(){
echo """bind 0.0.0.0
port $PORT
cluster-enabled yes
"""
}

for PORT in 700{1..6}; do
  FILE=$PORT.conf
  echo "Writing $FILE"
  print_conf > $FILE
done
