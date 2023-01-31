# Put Latest flag so that it will behave like git rebase 
FROM gcr.io/kaggle-gpu-images/python:latest

# Define Global Variable
#ARG PUB_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCppoB1YfV43IYAWWMpXFe3C+cjyJ/rA9gaMWrxWtzBOop9Ie50E0DjA3Qr9NJve5O/siVAv5QxNydcCr7aBynp7daLqEe824PlvgtH6hi05YGnr/KcGEayeyaaBYFu7dYqr+zFYRtvLhRRhZykc+JREJarRa6x2Vot1gP/xHhOCRbdGZnxrXo4qe+HzpSAXFsYmrmZVRqaN0MOkGzg/C4R+nymgvBMFZEY0gRfpnrLCh/z2g86kRXspLGA7me/mrM8TSXExTOUsEy+MOg8XUbFoDZJtGeTrkQmP+RdGGNAq4pn8BOcoXMreBr/tlLuVg/wNIsW/jH99UEJ2nzDfq7V root"
ARG PUB_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC2Z4WMPh5DdfgT/qPAmA8BkRHmEawUAt9HY2ARVUeQ25Z3V3fzNWGUIXOTjdisdUkurS219TvsMC5KywD1DrwPTRDZamEo8dVWq4fjXo5twGdRQ9TsvJB7pDBg/9vRq3UizEZeO5FfIUu5CX/yQPSRhY37TP1ENdxh+RpcuOjEpIxMlmhcMUAL6zpEDtSpMGbS90RlpTXTmairpli4fTt3vWM1cp/9/EHoa2I2itRIjiW/XB57h/JutwA0pzcLEeUXERJ9o0/4a9F1D2PVGF1tjmwUJHBLfavlmQps2RqQ8NnhLfxhZFmTy4Fh67myrfYxYxLRG3jBZuIUSqvaFT7o6gN1UuqKzqXUygnDF6oTD4Zx4mQ++NFP+INRiMA+kqd8smpzvjphc+e5mNjZRn5tKKAGSJpNxwAiZymhI/aV41ssJLTmNZKxl/+CGRlGG7zfaI2n7r44K4bKi+JJIHbi33iPKpElqswJ5q8AMvkYimFzTMN9ctYjdRL6/KDudc8= asus@LAPTOP-V6RH4QP3"

# Obtain Latest SHA : 
# https://api.github.com/repos/microsoft/vscode/releases/latest, Then copy tag_name, insert it to 
# https://api.github.com/repos/microsoft/vscode/git/ref/tags/{insert tag_name here}
#ARG VSCODE_COMMIT_SHA="ccbaa2d27e38e5afa3e5c21c1c7bef4657064247"
ARG VSCODE_COMMIT_SHA="97dec172d3256f8ca4bfb2143f3f76b503ca0534"

ARG VSCODE_ARCHIVE="vscode-server-linux-x64.tar.gz"
ARG VSCODE_OWNER='microsoft'
ARG VSCODE_REPO='vscode'
#ARG VSCODE_PYTHON_PACK="ms-python.python-2021.11.1422169775.vsix"
ARG VSCODE_PYTHON_PACK="ms-python.python-2023.1.10271009.vsix"

# Update Package & Install 
RUN apt-get update -y
RUN apt-get install -y nano openssh-server 

# Path Hack.. 
RUN export PATH="/opt/bin:/opt/conda/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Root SSH Setup
RUN echo "root:root" | chpasswd
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
RUN cat /etc/ssh/sshd_config
RUN mkdir /root/.ssh
RUN chown -R root:root /root/.ssh;chmod -R 700 /root/.ssh
RUN echo  "StrictHostKeyChecking=no" >> /etc/ssh/ssh_config

# Install VSCODE SERVER : https://gist.github.com/b01/0a16b6645ab7921b0910603dfb85e4fb
RUN curl -L "https://update.code.visualstudio.com/commit:${VSCODE_COMMIT_SHA}/server-linux-x64/stable" -o "/tmp/${VSCODE_ARCHIVE}"
# Make the parent directory where the server should live.
# NOTE: Ensure VS Code will have read/write access; namely the user running VScode or container user.
RUN mkdir -vp ~/.vscode-server/bin/"${VSCODE_COMMIT_SHA}"
# Extract the tarball to the right location.
RUN tar --no-same-owner -xzv --strip-components=1 -C ~/.vscode-server/bin/"${VSCODE_COMMIT_SHA}" -f "/tmp/${VSCODE_ARCHIVE}"

# Install Python VSCode Extension Package
# Unfortunately code cli cannot run on SSH (Only by WSL or Integrated Terminal)
RUN chown -R root:root /root/.vscode-server; chmod -R 777 /root/.vscode-server
RUN mkdir /root/.vscode-server/extensions
COPY extensions /root/.vscode-server/extensions

# Install Public Key 
RUN echo ${PUB_KEY} >> /root/.ssh/authorized_keys

# Enable SSH to obtain environment variable from /etc/environment. 
# By default env is cleared by sshd whenever ssh loged in, so need to obtain env from /etc/environment
# then purge /etc/environment & replace with current env
RUN echo "PermitUserEnvironment yes" >> /etc/ssh/sshd_config; \ 
   rm /etc/environment; \
   env >> /etc/environment

# Run all neccesary server
ENTRYPOINT service ssh restart & \
jupyter notebook --no-browser --ip="0.0.0.0" --NotebookApp.token='' --NotebookApp.password='' --allow-root 

# Default command so that it will not close
CMD /bin/bash