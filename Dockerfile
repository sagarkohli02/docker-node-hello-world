FROM node:7
COPY package.json /tmp/package.json
COPY package-lock.json /tmp/package-lock.json
WORKDIR /tmp
RUN npm install
RUN npm install nodemon -g
RUN mkdir -p /app/node_modules && cp -a /tmp/node_modules/ /app
COPY . /app
WORKDIR /app
CMD npm start
EXPOSE 8081
# // docker run -p 8089:8081 -v $PWD/node_modules:/app/node_modules hello-world
# docker build -t hello-world .