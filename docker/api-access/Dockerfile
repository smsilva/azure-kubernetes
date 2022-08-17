FROM alpine:3.16.2
RUN apk --no-cache add \
  bash \
  curl \
  bind-tools
ADD kubeconfig.template.yaml   /opt/kubernetes/kubeconfig.template.yaml
ADD docker_build_temp/kubectl* /opt/kubernetes/kubectl
ENV PATH=${PATH?}:/opt/kubernetes/
RUN chmod +x /opt/kubernetes/kubectl
