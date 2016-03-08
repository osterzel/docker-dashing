FROM 		ubuntu
MAINTAINER	Oliver Sterzel oliver@cloudsurge.co.uk	

# Add and update apt sources
RUN apt-get clean
RUN apt-get update; apt-get -y upgrade

# Add compiler package and ruby1.9.1
RUN apt-get install -y build-essential ruby1.9.1-dev nodejs

# Install dashing and bundle
RUN gem install dashing bundle --no-ri --no-rdoc

#Copy dashboard
#RUN mkdir /dashboard
COPY dashboard /

#Install additional gems
WORKDIR /dashboard
RUN pwd && bundle install --path vendor/bundle 

# Default command that autostarts the dashing project
CMD ["bundle exec dashing start"]
