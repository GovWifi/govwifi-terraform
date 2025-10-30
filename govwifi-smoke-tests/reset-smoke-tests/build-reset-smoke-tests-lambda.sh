#!/bin/bash
rm -rf package
rm -f lambda_deployment_package.zip

# Create package directory
mkdir package

# Install dependencies
PIP=pip
if [ -z "$(which $PIP)" ]; then
    echo "pip is not installed. Using pip3 instead."
    PIP=pip3
fi
$PIP install --target ./package -r requirements.txt

# Copy your function code
cp src/lambda_function.py package/

# Create deployment package
cd package
zip -r ../lambda_deployment_package.zip .
cd ..
