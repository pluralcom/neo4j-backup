# FROM debian:9.12

# # Install core packages
# RUN apt-get update
# RUN apt-get install -y bash curl wget gnupg apt-transport-https apt-utils lsb-release unzip
# #  software-properties-common

# # Install Java 11
# RUN add-apt-repository -y ppa:linuxuprising/java
# RUN apt-get update
# RUN apt install openjdk-11-jdk

# # Install Neo4j
# # RUN wget -O - https://debian.neo4j.org/neotechnology.gpg.key | apt-key add -
# # RUN echo 'deb https://debian.neo4j.org/repo stable/' | tee -a /etc/apt/sources.list.d/neo4j.list
# RUN wget -O - https://debian.neo4j.com/neotechnology.gpg.key | apt-key add -
# RUN echo 'deb https://debian.neo4j.com stable 4.0' | tee /etc/apt/sources.list.d/neo4j.list

# RUN echo "neo4j-enterprise neo4j/question select I ACCEPT" | debconf-set-selections
# RUN echo "neo4j-enterprise neo4j/license note" | debconf-set-selections

# RUN apt-get update
# RUN apt-get install -y neo4j-enterprise=1:4.0.4
FROM neo4j:4.0.4-enterprise

RUN apt-get update
RUN apt-get install -y bash curl wget gnupg apt-transport-https apt-utils lsb-release unzip

WORKDIR /

# Install AWS CLI

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

# Running backup script
RUN mkdir /backup
ADD ./backup.sh /scripts/backup.sh
RUN chmod +x /scripts/backup.sh

CMD ["/scripts/backup.sh"]