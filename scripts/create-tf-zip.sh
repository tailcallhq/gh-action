#!/bin/sh -l

cd /app

depends_on="[";
for file_path in $(find . -type f); do
  echo "Path: $file_path"
  name=$(basename $file_path | tr '.' '_')
  resource="resource \"local_sensitive_file\" \"$name\" { content_base64 = filebase64(\"$file_path\") filename = \"config\" }"

  echo "\n$resource" >> /aws/tailcall.tf

  depends_on="$depends_on local_sensitive_file.$name,"
  echo $resource
done
depends_on="$depends_on]"

archive_file="data \"archive_file\" \"tailcall\" { depends_on = $depends_on type = \"zip\" source_dir = \"config\" output_path = \"tailcall.zip\" }"
echo "\n$archive_file" >> /aws/tailcall.tf
