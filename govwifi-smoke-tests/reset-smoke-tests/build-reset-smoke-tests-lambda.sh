#!/bin/bash
rm -rf package
rm -f lambda_deployment_package.zip

# Create package directory
mkdir package

# Install dependencies
pip install --target ./package -r requirements.txt

# Copy your function code
cp src/lambda_function.py package/

# Create deployment package
cd package
zip -r ../lambda_deployment_package.zip .
cd ..
