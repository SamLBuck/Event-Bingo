# README #

This README would normally document whatever steps are necessary to get your application up and running.


### database setup procedure ###

* make sure docker is running and the proper environment variables are set 
* open pgAdmin 4
* open the csci 392 database
* right-click on schemas -> create -> schema. name the schema 'inspirepractice'
* in terminal, execute 'cd server\src\main\resources\db'
* execute liquibase update
* if you need to undo a change, execute 'liquibase rollback-count x' where x is the number of changesets you want to undo. remember that this is a stack operation. you can't undo
a changeset without first undoing all later changesets


### How do I get set up? ###

* Summary of set up
* Configuration
* Dependencies
* Database configuration
* How to run tests
* Deployment instructions

### Contribution guidelines ###

* Writing tests
* Code review
* Other guidelines

### Who do I talk to? ###

* Repo owner or admin
* Other community or team contact