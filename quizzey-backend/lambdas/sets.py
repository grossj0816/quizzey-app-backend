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
    
    course_id = event['pathParameters']['courseId']
    
    try:
        with DbUtils(host, db_name, username, password) as db:
            if db.is_connected():
                db_info = db.get_server_info()
                print("Connected to MySQL Server version:", db_info)

                query = ("SELECT * FROM quizzey_sets where courseId = %(course_id)s")
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
    active = request_body['active']
    created_by = request_body['createdBy']
    created_date = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    print(course_id)
    print(set_name)
    print(active)
    print(created_by)
    print(created_date)

    try:
        with DbUtils(host, db_name, username, password) as db:
            if db.is_connected():
                db_info = db.get_server_info()
                print("Connected to MySQL Server version:", db_info)

                if isinstance(set_name, str) and isinstance(active, bool) and isinstance(created_by, str):
                    query = ("INSERT INTO quizzey_sets"
                             "(courseId, setName, active, createdBy, createdDate, lastModifiedDate)"
                             "VALUES (%s, %s, %s, %s, %s, %s)")
                    data_for_query = (course_id, set_name, active, created_by, created_date, created_date)
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


def update_set_handler(event, context):
    request_body = json.loads(event['body'])
    set_id = request_body['setId']
    set_name = request_body['setName']
    active = True if request_body['active'] == 1 else False
    created_by = request_body['createdBy']
    created_date = request_body['createdDate']
    created_date_obj = datetime.datetime.strptime(created_date, '%Y-%m-%d %H:%M:%S')
    last_mod_date = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    print(set_id)
    print(set_name)
    print(active)
    print(created_by)
    print(created_date_obj)
    print(last_mod_date)

    try:
        with DbUtils(host, db_name, username, password) as db:
            if db.is_connected():
                db_info = db.get_server_info()
                print("Connected to MySQL Server version:", db_info)

                if isinstance(set_name, str) and isinstance(active, bool) and isinstance(created_by, str):
                    query = ("""UPDATE quizzey_sets
                                SET setName=%s, active=%s, createdBy=%s, createdDate=%s, lastModifiedDate=%s
                                WHERE setId=%s""")

                    data_for_query = (set_name, active, created_by, created_date_obj, last_mod_date, set_id)
                    cursor = db.cursor(dictionary=True)
                    cursor.execute(query, data_for_query)
                    db.commit()
                    print('COMMITTED EXISTING RECORD UPDATE...')
                    cursor.close()
                    print('CURSOR CLOSED...')
    except Error as e:
        print('Error while connecting to MySQL...', e)

    return{
        "statusCode": 200,
        "body": json.dumps({'Success', 'Set update process has completed. Double check if your new set record was added correctly.'}, indent=3)
    }


