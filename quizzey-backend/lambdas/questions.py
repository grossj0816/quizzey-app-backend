import json
import os
import datetime
from mysql.connector import Error
from db import DbUtils

host = os.environ.get('HOST')
db_name = os.environ.get('DATABASE_NAME')
username = os.environ.get('USERNAME')
password = os.environ.get('PASSWORD')

print('Loading function')


def get_questions_by_sId_handler(event, context):
    set_id = event['pathParameters']['setId']

    try:
        with DbUtils(host, db_name, username, password) as db:
            if db.is_connected():
                db_info = db.get_server_info()
                print("Connected to MySQL Server version:", db_info)

                query = ("SELECT * FROM c WHERE setId = %(set_id)s")
                cursor = db.cursor(dictionary=True)
                cursor.execute(query, {'set_id': set_id})
                rows = cursor.fetchall()
                print('FETCHED ALL QUESTIONS BY SET ID...')
                cursor.close()
                print('CURSOR CLOSED...')
    except Error as e:
        print('Error while connecting to MySQL...', e)

    return{
        "statusCode": 200,
        "body": json.dumps(rows, indent=3, default=str)
    }

def create_new_question_handler(event, context):
    # LOAD JSON LIST INTO PYTHON DICT
    request_body = json.loads(event['body'])
    created_date = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # CONNECT TO DB...
    try:
        with DbUtils(host, db_name, username, password) as db:
            if db.is_connected():
                db_info = db.get_server_info()
                print("Connected to MySQL Server version:", db_info)
                
                query = ("INSERT INTO questions"
                         "(setId, question, answer, createdBy, createdDate, lastModifiedDate)"
                         "VALUES (%s, %s, %s, %s, %s, %s)")

                cursor = db.cursor(dictionary=True)

                # LOOP THROUGH DATA
                for item in response_body:
                    print(item['setId'])
                    print(item['question'])
                    print(item['answer'])
                    print(item['createdBy'])
                    print(created_date)
                    

                    data_for_query = (item['setId'], item['question'], item['answer'], item['createdBy'], createdDate, createdDate)
                    cursor.execute(query, data_for_query)

                db.commit()
                print('COMMITTED NEW RECORD...')
                cursor.close()
                print('CURSOR CLOSED...')                
                    
    except Error as e:
        print('Error while connecting to MySQL...', e)

    return{
        "statusCode": 200,
        "body": json.dumps({'Success': 'Question creation process has completed. Double check if your new course record was added correctly.'}, indent=3)
    }

def question_update_handler(event, context):
    return{}


def question_delete_handler(event, context):
    return{}