#!/bin/bash

sudo yum install httpd -y
sudo service httpd start
cat <<EOF
<html>
    <head>
        <title>This is Index Page</title>
    </head>
    <body style="align-items: center ;">
        <h1>Welcome to my project !!</h1>
        <h3>Please type some number against url like '/11' and check the data!</h3>
    </body>
</html>
EOF | sudo tee /var/www/html/index.html