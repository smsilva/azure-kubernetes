FROM alpine:3.13.6
ENV KUBECONFIG_DATA=""
ADD entrypoint.sh /opt/kubernetes/entrypoint.sh
ADD docker_build_temp/kubectl* /opt/kubernetes/kubectl
RUN chmod +x /opt/kubernetes/kubectl
ENTRYPOINT ["/opt/kubernetes/entrypoint.sh"]
