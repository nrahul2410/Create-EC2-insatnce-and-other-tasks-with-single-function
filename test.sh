#!/bin/sh

instance_id=$(aws ec2 run-instances --image-id ami-cfe4b2b0 --count 1 --instance-type t2.micro --key-name *********** --security-group-ids sg-8a433ec0 --subnet-id subnet-0350260c --user-data file://install-server.txt --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=***********},{Key=Owner,Value=***********}]' 'ResourceType=volume,Tags=[{Key=Name,Value=***********},{Key=Owner,Value=***********}]' --output text --query 'Instances[*].InstanceId' )

echo “The Instance ID is ”, $instance_id

#delay until AWS says instance is running
start_state=''
while [ "${start_state}" != '16running' ]
	do
	 start_state=$(aws ec2 describe-instances --instance-ids $instance_id --output text --query 'Reservations[*].Instances[*].State')
	 start_state=$(echo $start_state | tr -d '" []')
	 echo ${start_state}
	 sleep 10
done
echo $instance_id," is up and running"

public_dns=$(aws ec2 describe-instances --instance-ids $instance_id --output text --query 'Reservations[*].Instances[*].PublicDnsName')

echo "The Public DNS is ",${public_dns}
echo 'ssh -i ***********.pem "ec2-user@${public_dns}"'

#Creating a classis load balancer 
load_balancer=$(aws elb create-load-balancer --load-balancer-name *********** --listeners "Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80" --subnets subnet-0350260c --security-groups sg-8a433ec0)

load_balancer=cand$(echo $load_balance | grep -oP '(?<=cand).*' )
load_balancer=$(echo ${load_balancer::-1})

echo "DNS Name of the load balancer is ", $load_balancer

#To register instance with the load balancer
aws elb register-instances-with-load-balancer --load-balancer-name *********** --instances $instance_id

#Updating the health check configuration
aws elb configure-health-check --load-balancer-name *********** --health-check Target=HTTP:80/ping,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3

#Checking the health of instance 
aws elb describe-instance-health --load-balancer-name ***********

