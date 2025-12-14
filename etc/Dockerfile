FROM archlinux:latest

ENV DEBIAN_FRONTEND=noninteractive
RUN useradd -m -G wheel -s /bin/zsh user && echo "tester ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
WORKDIR /home/user
COPY gnomi.sh /home/tester/gnomi.sh
RUN chmod +x /home/tester/gnomi.sh
USER tester
RUN /home/tester/gnomi.sh
