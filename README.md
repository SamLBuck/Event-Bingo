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


### UML Diagram ###

The UML diagram of our backend structure is accessible here: https://www.mermaidchart.com/app/projects/cb2ce2f9-4192-4cbe-a448-ffa9df06efd6/diagrams/59f3022d-255b-4f41-be22-ebfc38281f7e/share/invite/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkb2N1bWVudElEIjoiNTlmMzAyMmQtMjU1Yi00ZjQxLWJlMjItZWJmYzM4MjgxZjdlIiwiYWNjZXNzIjoiRWRpdCIsImlhdCI6MTc2MjQ0MDY3NH0.LoeVQdBksTSxVDP3QdDPnSuFIsygUrjO-NVAXtDPf84

please update the UML as we refine and improve our ideas 

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