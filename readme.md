Build your image

Please run the following in terminal: 

docker build --no-cache -t muhaman/kaggle-gpu:latest .

This command is structured as follows:

1. docker build is the command to build a Docker image from a Dockerfile

2. --no-cache, is to force docker build to purge cache and build from strach

3. -t muhaman/kaggle-gpu:latest defines the tag (hence -t) of the image, which will be basically the name of the image. As the first part I put my own name muhaman, because I’m the maintainer of the image, then I gave it a human readable name kaggle-gpu and provided a version number latest.

4. please note the . (dot) at the end of the line. You need to specify the directory where docker build should be looking for a Dockerfile. Therefore . tells docker build to look for the file in the current directory.


Prepare extensions

1. install neccesary extension in your local pc. Locate those folders (more than one) then copy it put it in /extensions folder.
Neccesary Extension so far :
python
pdf

Then Run the following : 

docker run -d --name=kagglecontainer -v /mnt/d/workspace/foresight:/home/workspace/foresight --restart=always  --gpus=all -p 9999:8888 -p 1111:22 -it muhaman/kaggle-gpu:latest