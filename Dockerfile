FROM neo4j:4.0.4-enterprise

RUN apt-get update
RUN apt-get install -y bash curl wget gnupg apt-transport-https apt-utils lsb-release unzip

WORKDIR /

# Install AWS CLI

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

RUN mkdir /backup

# Adding backup script
ADD ./scripts/backup.sh /scripts/backup.sh
RUN chmod +x /scripts/backup.sh

# Adding restore script
ADD ./scripts/restore.sh /scripts/restore.sh
RUN chmod +x /scripts/restore.sh

CMD ["/scripts/backup.sh"]