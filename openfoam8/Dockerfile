# Based on the openfoam/openfoam8-paraview56 image
FROM openfoam/openfoam8-paraview56

# Set environment variables using build arguments
ARG USER_UID
ARG USER_GID
ARG USERNAME=openfoam

# Switch to the root user to perform apt-get update and install sudo
USER root

# Output the provided USER_UID and USER_GID
RUN echo "Building with USER_UID=${USER_UID} and USER_GID=${USER_GID}"

# Update package lists and install sudo
RUN apt-get update && apt-get install -y sudo

# Check if the user already exists; if so, modify UID and GID. Otherwise, create a new user
RUN if id -u $USERNAME >/dev/null 2>&1; then \
        echo "User $USERNAME exists. Modifying UID and GID..."; \
        groupmod -g $USER_GID $USERNAME; \
        usermod -u $USER_UID -g $USER_GID $USERNAME; \
        chown -R $USER_UID:$USER_GID /home/$USERNAME; \
    else \
        echo "User $USERNAME does not exist. Creating user..."; \
        groupadd --gid $USER_GID $USERNAME; \
        useradd --uid $USER_UID --gid $USER_GID -m $USERNAME; \
    fi \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Switch to the non-root user
USER $USERNAME

# Set the default working directory
WORKDIR /home/$USERNAME

# Override the base image's ENTRYPOINT
ENTRYPOINT []

# Use CMD to start a bash shell when the container starts
CMD ["/bin/bash"]
