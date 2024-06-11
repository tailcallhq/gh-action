#!/bin/sh -l

cd /app

depends_on="[ local_sensitive_file.bootstrap,";
for file_path in $(find . -type f); do
  echo "Path: $file_path"
  name=$(basename $file_path | tr '.' '_')
  config_path="${file_path/#./config}"

  resource="resource \"local_sensitive_file\" \"$name\" {\n content_base64 = filebase64(\"$file_path\") \n filename = \"$config_path\"\n }"

  printf "\n$resource\n" >> /aws/tailcall.tf

  depends_on="$depends_on local_sensitive_file.$name,"
  echo $resource
done
depends_on="$depends_on ]"

archive_file="data \"archive_file\" \"tailcall\" { \n depends_on = $depends_on \n type = \"zip\" \n source_dir = \"config\" \n output_path = \"tailcall.zip\"\n }"
printf "\n$archive_file\n" >> /aws/tailcall.tf

echo "tailcall.tf"
cat /aws/tailcall.tf
