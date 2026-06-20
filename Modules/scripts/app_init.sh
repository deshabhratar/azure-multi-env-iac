#!/bin/bash

sudo apt update -y
sudo apt install python3-pip -y
sudo pip3 install flask gunicorn


cat > /home/azureuser/app.py <<EOF
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello from app tier'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
   
EOF 
 cd /home/azureuser
python3 app.py &