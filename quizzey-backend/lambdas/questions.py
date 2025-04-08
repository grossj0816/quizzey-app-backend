import json
import os
import datetime
from mysql.connector import Error
from db import DbUtils

host = os.environ.get('HOST')
db_name = os.environ.get('DATABASE_NAME')
username = os.environ.get('USERNAME')
password = os.environ.get('PASSWORD')

response_headers = {
    "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "OPTIONS,PUT,GET,POST",
}

print('Loading function')


def get_questions_by_sId_handler(event, context):
    set_id = event['pathParameters']['id']

    try:
        with DbUtils(host, db_name, username, password) as db:
            if db.is_connected():
                db_info = db.get_server_info()
                print("Connected to MySQL Server version:", db_info)

                query = ("SELECT * FROM questions WHERE setId = %(set_id)s")
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
        "headers": response_headers,
        "body": json.dumps(rows, indent=3, default=str)
    }

def create_new_questions_handler(event, context):
    # LOAD JSON LIST INTO PYTHON DICT
    request_body = json.loads(event['body'])
    created_date = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    print(body)
    
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
                for item in request_body:                    
                    if isinstance(item['setId'], int) and isinstance(item['question'], str) and isinstance(item['answer'], str) and isinstance(item['createdBy'], str):
                        data_for_query = (item['setId'], item['question'], item['answer'], item['createdBy'], created_date, created_date)
                        cursor.execute(query, data_for_query)

                db.commit()
                print('COMMITTED NEW RECORD...')
                cursor.close()
                print('CURSOR CLOSED...')                
                    
    except Error as e:
        print('Error while connecting to MySQL...', e)

    return{
        "statusCode": 200,
        "headers": response_headers,
        "body": json.dumps({'Success': 'Question creation process has completed. Double check if your new course record was added correctly.'}, indent=3)
    }

def options_handler(event, context):
    return{
        "statusCode": 200,
        "headers": response_headers,
        "body": json.dumps({'Success': 'OPTIONS method was successful.'}, indent=3)
    }

def update_questions_handler(event, context):
    request_body = json.loads(event['body'])
    last_mod_date = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    try:
        with DbUtils(host, db_name, username, password) as db:
            if db.is_connected():
               db_info = db.get_server_info()
               print("Connected to MySQL Server version:", db_info)
                
               query = ("""UPDATE questions
                           SET question=%s, answer=%s, createdBy=%s, lastModifiedDate=%s
                           WHERE questionId=%s""")
                
               cursor = db.cursor(dictionary=True)

               for item in request_body:
                    if isinstance(item['question'], str) and isinstance(item['answer'], str) and isinstance(item['createdBy'], str):
                        data_for_query = (item['question'], item['answer'], item['createdBy'], last_mod_date, item['questionId'])
                        cursor.execute(query, data_for_query)
                
               db.commit()
               print('COMMITTED NEW RECORD...')
               cursor.close()
               print('CURSOR CLOSED...')

    except Error as e:
        print('Error while connecting to MySQL...', e)
    
    return{
        "statusCode": 200,
        "headers": response_headers,
        "body": json.dumps({'Success': 'Batch question update process has completed. Double check if your new question records were updated correctly.'}, indent=3)
    }


def delete_questions_handler(event, context):
    request_body = json.loads(event['body'])

    try:
        with DbUtils(host, db_name, username, password) as db:
            if db.is_connected():
                db_info = db.get_server_info()
                print("Connected to MySQL Server version:", db_info)

                query = ("DELETE FROM questions WHERE questionId=%s")

                cursor = db.cursor()

                for item in request_body:
                    data_for_query = (item['questionId'], )
                    print(data_for_query)
                    cursor.execute(query, data_for_query)

                db.commit()
                print('COMMITTED NEW RECORD...')
                cursor.close()
                print('CURSOR CLOSED...')

    except Error as e:
        print('Error while connecting to MySQL...', e)
    return{
        "statusCode": 200,
        "headers": response_headers,
        "body": json.dumps({'Success': 'Batch question delete process has completed.'}, indent=3)
    }