FROM archlinux:latest

# Set non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive

# Create a user for testing
RUN useradd -m -G wheel -s /bin/zsh user && echo "tester ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set the working directory
WORKDIR /home/user

# Copy the setup script into the container
COPY gnomi.sh /home/tester/gnomi.sh

# Make the script executable
RUN chmod +x /home/tester/gnomi.sh

# Set the user
USER tester
