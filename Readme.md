

# An attempt to have Developer friendly express and docker Setup

I wished to have developer friendly express and docker application, I understand we can acheive better results with **docker-compose** (which we will discuss in another repo). Reson for doing this is to explore boundries of the tool being used and need of another/better tools.

Here is the list of features I, as a developer, wish to have

1. Setup should not leave any stack footprint on my host machine, it must live and die with container.
2. Faster Image building time by exploiting docker cache feature.
3. No hassle to rebuid or rerun image after code changes.

## Code Structure

Let's see how files are placed here. Seems pretty simple, Entry point is defined at ```src/index.js```  

```shell
        .
        ├── Dockerfile
        ├── node_modules
        ├── package.json
        ├── package-lock.json
        ├── Readme.md
        └── src
            └── index.js

```

## Package json file

To start quickly here is the **package.json** file. Just skip **scripts** section, we will come to that later

```json
{
  "name": "helloworld",
  "version": "1.0.0",
  "description": "",
  "main": "src/index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1",
    "start": "cd src && nodemon index.js"
  },
  "author": "",
  "license": "ISC",
  "dependencies": {
    "express": "^4.16.4"
  }
}

```

So we have 

> ```
>  "dependencies": {
>     "express": "^4.16.4"
>   }
> ```

**express js** dependency only which seems desirable. 

Now the interesting part, **start** script.

> ```
> "scripts": {
>     "test": "echo \"Error: no test specified\" && exit 1",
>     "start": "cd src && nodemon index.js"
>   },
> ```

You may have noticed start script has **nodemon** command.  **nodemon** command helps us in achieving later part 3rd point i.e *No hassle to rebuid or **rerun image after code changes.*** by restarting the node process on any change in source code

## Doker File

Finally we have docker file. Prior to further discussion let's understand how docker creates and caches the layers and how it can help us to acheive faster build cycle.

> When building an image from a Dockerfile, each line generates its own layer. These layers are cached, and they can be reused if no changes are detected. If a layer changes, all the following layers have to be created from scratch.

Let's have a look at Dockerfile now.

```dockerfile
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
```

### O/P of First Image build

Here is the output of first run using  ```docker build -t hello-world .```

```
Step 1/11 : FROM node:7
7: Pulling from library/node
ad74af05f5a2: Pull complete 
2b032b8bbe8b: Pull complete 
a9a5b35f6ead: Pull complete 
3245b5a1c52c: Pull complete 
afa075743392: Pull complete 
9fb9f21641cd: Pull complete 
3f40ad2666bc: Pull complete 
49c0ed396b49: Pull complete 
Digest: sha256:af5c2c6ac8bc3fa372ac031ef60c45a285eeba7bce9ee9ed66dad3a01e29ab8d
Status: Downloaded newer image for node:7
 ---> d9aed20b68a4
Step 2/11 : COPY package.json /tmp/package.json
 ---> ceb7182b517d
Step 3/11 : COPY package-lock.json /tmp/package-lock.json
 ---> bef8bdf4972b
Step 4/11 : WORKDIR /tmp
 ---> Running in 13e3a7f68c46
Removing intermediate container 13e3a7f68c46
 ---> 37af0f95a1d7
Step 5/11 : RUN npm install
 ---> Running in 53d9e9572394
npm info it worked if it ends with ok
npm info using npm@4.2.0
npm info using node@v7.10.1
npm info attempt registry request try #1 at 7:50:42 AM
.....
.....
.....
.
.
.
....
Removing intermediate container 571019d5a432
 ---> 552978753a55
Step 7/11 : RUN mkdir -p /app/node_modules && cp -a /tmp/node_modules/ /app
 ---> Running in d18d9fe3c3d2
Removing intermediate container d18d9fe3c3d2
 ---> 29df614352bf
Step 8/11 : COPY . /app
 ---> 4a427e1468ff
Step 9/11 : WORKDIR /app
 ---> Running in 218291631e06
Removing intermediate container 218291631e06
 ---> f0bd7770a0fe
Step 10/11 : CMD npm start
 ---> Running in 432d2cfa6eba
Removing intermediate container 432d2cfa6eba
 ---> 58f784486279
Step 11/11 : EXPOSE 8081
 ---> Running in 73b1f7f80d19
Removing intermediate container 73b1f7f80d19
 ---> 3a4f6fbda363
Successfully built 3a4f6fbda363
Successfully tagged hello-world:latest
```

as output indicates that every step creates fresh layer and thus takes it's own time. What if same command is executed again.

### O/P of Consicutive Image builds

```
[sid@localhost helloworld]$ docker build -t hello-world .
Sending build context to Docker daemon  22.02kB
Step 1/11 : FROM node:7
 ---> d9aed20b68a4
Step 2/11 : COPY package.json /tmp/package.json
 ---> Using cache
 ---> fb58144d7914
Step 3/11 : COPY package-lock.json /tmp/package-lock.json
 ---> Using cache
 ---> b3d7ee241538
Step 4/11 : WORKDIR /tmp
 ---> Using cache
 ---> 9d0073741b40
Step 5/11 : RUN npm install
 ---> Using cache
 ---> d92c0fa58f38
Step 6/11 : RUN npm install nodemon -g
 ---> Using cache
 ---> 1978442c2196
Step 7/11 : RUN mkdir -p /app/node_modules && cp -a /tmp/node_modules/ /app
 ---> Using cache
 ---> c880415d4ca8
Step 8/11 : COPY . /app
 ---> 29adbffd88a7
Step 9/11 : WORKDIR /app
 ---> Running in c6ca22cd1486
Removing intermediate container c6ca22cd1486
 ---> e5c25069636b
Step 10/11 : CMD npm start
 ---> Running in 8db3b5238912
Removing intermediate container 8db3b5238912
 ---> 9829e7db1282
Step 11/11 : EXPOSE 8081
 ---> Running in 54e16bc618bf
Removing intermediate container 54e16bc618bf
 ---> 3a2433d865a6
Successfully built 3a2433d865a6
Successfully tagged hello-world:latest

```

Rerun uses the cache till 7th step which saves the efforts and time required to build an Image.

## Avoid rebuilding Image to reflect code changes

Though we have saved time while re builing image but as a developer it's still a big pain to rebuild the docker image after code changes. I am sure it can not be accepted as possible developer friendly setup using docker.

Here comes the saviour, docker run time arguments, what if i can mount my source dirctory in running container?

Ans: **nodemon** will monitor changes in directory and restart the application and thus latest code will be updated automaticaly. 

In short ```docker run -p 8089:8081 -v $PWD/node_modules:/app/node_modules hello-world``` Command will do the task.

## Conclusion

Let's discuss our check list again

- [x] Setup should not leave any stack footprint on my host machine, it must live and die with container.

- [x] Faster Image building time by exploiting docker cache feature.

- [x] No hassle to rebuid image after code changes.

Though all requirements are satisfied up to a level but it can not be claimed as a perfect solution.

Let's consider following cases

* **What if changes are in package.json**? 
  * A simple reload wont work it will require a complete image rebuild.
* **What if application boot time is too High**?
  * This is really a serious issue as an application might require n number of external services at the boot time.