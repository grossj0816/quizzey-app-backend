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


def get_sets_by_cId_handler(event, context):
    
    course_id = event['queryStringParameters']['courseId']
    
    try:
        with DbUtils(host, db_name, username, password) as db:
            if db.is_connected():
                db_info = db.get_server_info()
                print("Connected to MySQL Server version:", db_info)

                query = ("SELECT * FROM quizzey_sets where setId = %(course_id)s")
                cursor = db.cursor(dictionary=True)
                cursor.execute(query, {'course_id': course_id})
                rows = cursor.fetchall()
                print('FETCHED ALL COURSES...')
                cursor.close()
                print('CURSOR CLOSED...')
    except Error as e:
        print('Error while connecting to MySQL...', e)


    return{
        "statusCode": 200,
        "body": json.dumps(rows, indent=3, default=str)
    }




def create_new_set_handler(event, context):
    request_body = json.loads(event['body'])
    course_id = request_body['courseId']
    set_name = request_body['setName']
    created_by = request_body['createdBy']
    created_date = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    print(course_id)
    print(set_name)
    print(created_by)
    print(created_date)

    try:
        with DbUtils(host, db_name, username, password) as db:
            if db.is_connected():
                db_info = db.get_server_info()
                print("Connected to MySQL Server version:", db_info)

                if isinstance(set_name, str) and isinstance(created_by, str):
                    query = ("INSERT INTO quizzey_sets"
                             "(courseId, setName, createdBy, createdDate, lastViewedDate)"
                             "VALUES (%s, %s, %s, %s, %s)")
                    data_for_query = (course_id, set_name, created_by, created_date, None)
                    cursor = db.cursor(dictionary=True)
                    cursor.execute(query, data_for_query)
                    db.commit()
                    print('COMMITTED NEW RECORD...')
                    cursor.close()
                    print('CURSOR CLOSED...')
    
    except Error as e:
        print('Error while connecting to MySQL...', e)

    return{
        "statusCode": 200,
        "body": json.dumps({'Success': 'Quizzey set creation process has completed. Double check if your new course record was added correctly.'}, indent=3)
    }


def set_update_handler(event, context):
    return{}


def set_delete_handler(event, context):
    return{}
