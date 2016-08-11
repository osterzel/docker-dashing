FROM 		centos:7	
MAINTAINER	Oliver Sterzel oliver@cloudsurge.co.uk	

# Add and update apt sources
RUN yum -y install centos-release-scl
RUN yum install -y rh-ruby22 rh-ruby22-ruby-devel nodejs010 make gcc gcc-c++ rh-ruby22-rubygem-bundler

# Install dashing and bundle
RUN scl enable rh-ruby22 "gem install dashing bundle --no-ri --no-rdoc"

#Copy dashboard
RUN mkdir /dashboard
COPY dashboard /dashboard

#Install additional gems
WORKDIR /dashboard
RUN pwd && scl enable rh-ruby22 "bundle install --path vendor/bundle" 

# Default command that autostarts the dashing project
CMD scl enable rh-ruby22 nodejs010 "bundle exec dashing start"
