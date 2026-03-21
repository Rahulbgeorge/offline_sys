# log Streamer

## Problem statement:
- We are using a multitenant architecture
- Each tenant has its own server running on their system and a set of log files
- we could have 100s of such tenants

# Requirement
- we need a centralized monitoring system, where all the logs are aggregated and errors can be monitored and alterted for
- once error is detected, we need the ability to detect which tenant is facing teh errors and trace/ download all the errors and exception
- we also need to know which tenant is facing the most amount of errors
- so we need a tenant view, where there is list of tenants with error count shown and we need to be able to select tenant by tenant and list all the logs


## Sol:
- one of the solution approach is using graphana and loki,
- please recommend the best architecture and document it on exactly how to setit up
- use a dockerized system to make it quick and fast
- create a future modification .md file which teaches how to modify the system for future use cases


create a folder caled as observability and write the code documenation and setup tools required for setting up the system. if possible create a script which will setup everything in one, click, or a centralized env file, where all the inputs can be given in one shot, rather than running around everytheere to make changes



