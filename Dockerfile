# Container image that runs your code
FROM amazonlinux:2

COPY entrypoint.sh /entrypoint.sh
COPY tailcall.tf /tmp/tailcall.tf

RUN yum update -y && yum upgrade -y
RUN yum install -y yum-utils jq
RUN yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
RUN yum -y install terraform

ENTRYPOINT ["/entrypoint.sh"]
