# docker-nginx-helloworld
This project shows how to deploy an app to a Kubernetes cluster with manual and automated processes.

## Manual

### Run locally with docker compose
docker-compose build
  
docker-compose up

### Deploy to Kubernetes manually 
kubectl create -f nginx-deployment.yaml

kubectl create -f nginx-service.yaml

## Automated

### Create GitRunner (or reuse one)
   * We'll need to run one VM per environment dev, uat, prod.  The VM needs to run in the **same
     OpenStack project** as the target environment so that the runner can communicate with the
     kubernetes rest admin api.

   * Install GitRunner on a server (dev for example)  (you can skip this step if you want to re-use an existing GitRunner server)
    
      [GitLab Runner Installation Guide](https://docs.gitlab.com/runner/install/linux-repository.html)
        
        - Install Docker on the same server from the previous step
    
        - Give the gitlab-runner user permission to run docker
    
            sudo usermod -aG docker gitlab-runner          

   * Register a new runner for your app with the third option Docker socket binding for doing docker builds
        
      + This is a sample (replace the registration-token with your GitLab projects token, 
        and give it a description that matches your app.)
        
       $ sudo gitlab-runner register -n --url http://gitlab.gvllab.windstream.net/ --registration-token 8GBcGZExVQzkCBNc4Fxt --executor docker --description "intent-path-gitrunner-docker-network-host" --docker-image "docker:latest"       --docker-volumes /var/run/docker.sock:/var/run/docker.sock --docker-network-mode "host"
     
      
      + Additional documentation:       
                   
        [GitLab Docker Build Tutorial](https://docs.gitlab.com/ce/ci/docker/using_docker_build.html)
              
        [Using Docker build](https://docs.gitlab.com/ce/ci/docker/using_docker_build.html)      
        
      + Add our private docker registory cert to the gitlab runner **VM**.
         
        ssh into the runner VM and run these commands:
             
        $ wget http://gitlab.gvllab.windstream.net/PN/Kailash/raw/master/certs/dockerCA.crt

        $ sudo mv dockerCA.crt /usr/local/share/ca-certificates/

        $ sudo update-ca-certificates

        $ sudo service docker restart  
                  
          
   * Register another runner for your app to do Git commits.
                              
      + This is a sample (replace the registration-token with your GitLab projects token,
           and give it a description that matches your app.)
           
       $ sudo gitlab-runner register -n        --url http://gitlab.gvllab.windstream.net/        --registration-token  8GBcGZExVQzkCBNc4Fxt   --executor shell        --description "intent-path-gitrunner-shell"

           
      + Prep the git-runner's user env on the **VM**:        
       1. $ ssh ubuntu@dev-gitlab-runner-vm-for-example
       2. $ sudo su - gitlab-runner
       3. $ sudo apt install bc
       4. $ ssh-keyscan -t rsa gitlab.gvllab.windstream.net >> ~/.ssh/known_hosts
       5. $ ssh-keygen -t rsa       
         -- Register the public ssh key (/home/gitlab-runner/.ssh/id_rsa.pub) with a GitLab user's account ssh keys. 
            
### Release process
* Commit a work branch for review.
* The **automation kicks in**:
    +  Gitlab runs a local build of the code and unit tests (mvn clean install gets run for example)
    +  Gitlab builds the Docker image (branch version)
    +  Gitlab pushes the Docker image to our private Docker registry.
    +  Gitlab deploys the Docker image to a Kubernetes dev cluster.
* Create a merge request for the branch and assign it to a teammate.
* Teammate will approve the merge request which merges the branch into the master branch.
* The **automation kicks in again**:
    +  We will get Gitlab to automatically tag the master after a merge is done.
    
        + Gitlab will automatically increment the minor version from the most previous tag.  
        
          Example:
          
          They previous version was 19.2.0.  GitLab will automatically tag the master with 19.**3**.0.
             
    +  Gitlab runs a local build of the code and unit tests (mvn clean install gets run for example)
    +  Gitlab builds the Docker image (tagged version)
    +  Gitlab pushes the Docker image to our private Docker registry.
    +  Gitlab deploys the Docker image to the Kubernetes uat cluster.
    +  Automated tests are run.
    +  Gitlab deploys the Docker images to the kubernetes production cluster.    
    
### Helm
kubectl create clusterrolebinding tiller-cluster-admin --clusterrole=cluster-admin --serviceaccount=default:tiller