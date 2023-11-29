import json
import os
import mysql.connector
from mysql.connector import Error


def all_tables_create_handler(event, context):
    host = os.environ.get('HOST')
    db_name = os.environ.get('DATABASE_NAME')
    username = os.environ.get('USERNAME')
    password = os.environ.get('PASSWORD')

    try:
        connection = mysql.connector.connect(host=host, database=db_name, user=username, password=password)
        cursor = connection.cursor()

        if connection.is_connected():
            db_info = connection.get_server_info()
            print("Connected to MySQL Server version:", db_info)

            #TODO: TEST IF QUIZZEY SETS AND QUESTIONS TABLE SCRIPTS ARE GOOD.
            cursor.execute("CREATE TABLE IF NOT EXISTS `courses`(`courseId` INT PRIMARY KEY NOT NULL AUTO_INCREMENT, `courseName` VARCHAR(75), `organization` VARCHAR(150), `textbook` VARCHAR(150), `active` BOOLEAN, `createdBy` VARCHAR(100), `createdDate` DATETIME(0))")
            cursor.execute("CREATE TABLE IF NOT EXISTS `quizzey_sets`(`setId` INT PRIMARY KEY NOT NULL AUTO_INCREMENT, courseId INT NOT NULL, `setName` VARCHAR(175), `createdBy` VARCHAR(100), `createdDate` DATETIME(0), `lastViewedDate` DATETIME(0), FOREIGN KEY(`courseId`) REFERENCES `courses`(`courseId`))")
            cursor.execute("CREATE TABLE IF NOT EXISTS `questions`(`questionId` INT PRIMARY KEY NOT NULL AUTO_INCREMENT, setId INT NOT NULL, `question` VARCHAR(450), `answer` VARCHAR(450), `createdBy` VARCHAR(100), `createdDate` DATETIME(0), FOREIGN KEY (`setId`) REFERENCES `quizzey_sets`(`setId`))")
            print("Table creation has been completed.")
    except Error as e:
        print('Error while connecting to MySQL...', e)
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()
            print("MySQL connection is closed.")
    return{
        "statusCode": 200,
        "body": json.dumps({'Success': 'Database creation process has completed. Double check if you tables were added correctly.'})
    }