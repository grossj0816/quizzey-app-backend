import json
import os
import datetime
from mysql.connector import Error
from db import DbUtils

host = os.environ.get('HOST')
db_name = os.environ.get('DATABASE_NAME')
username = os.environ.get('USERNAME')
password = os.environ.get('PASSWORD')


print("Loading function")

# Retrieve all active courses
def courses_getter_handler(event, context):
    try:

        with DbUtils(host, db_name, username, password) as db:
            if db.is_connected():
                db_info = db.get_server_info()
                print("Connected to MySQL Server version:", db_info)
                
                #Select all course records from courses table where the active flag is set to true.    
                query = ("SELECT * FROM courses where active = true")
                cursor = db.cursor(dictionary=True)
                cursor.execute(query)
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


# Retrieve a single course record by courseId
def course_getter_handler(event, context):
    
    course_id = event['pathParameters']['courseId']
    ind_course = None
    row = None

    try:
        with DbUtils(host, db_name, username, password) as db:
            if db.is_connected():
                db_info = db.get_server_info()
                print("Connected to MySQL Server version:", db_info)      
                
                #Select all course records from courses table where the active flag is set to true.    
                query = ("SELECT * FROM courses where courseId = %(course_id)s")
                cursor = db.cursor(dictionary=True)
                cursor.execute(query, {'course_id': course_id})
                row = cursor.fetchone()
                print('FETCHED COURSE BY ID...')
                cursor.close()
                print('CURSOR CLOSED...')      
    except Error as e:
        print('Error while connecting to MySQL...', e)


    return{
        "statusCode": 200,
        "body": json.dumps(row, indent=3, default=str)
    }

# Create a new course record
def create_new_course_handler(event, context):
    request_body = json.loads(event['body'])
    course_name = request_body['courseName']
    organization = request_body['organization']
    textbook = request_body['textbook']
    active = request_body['active']
    created_by = request_body['createdBy']
    created_date = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    print(course_name)
    print(organization)
    print(textbook)
    print(active)
    print(created_by)
    print(created_date)

    try:
        with DbUtils(host, db_name, username, password) as db:
            if db.is_connected():
                db_info = db.get_server_info()
                print("Connected to MySQL Server version:", db_info)
                
                if isinstance(course_name, str) and isinstance(organization, str) and isinstance(textbook, str) and isinstance(active, bool) and isinstance(created_by, str):
                    #Select all records from courses table    
                    query = ("INSERT INTO courses"
                            "(courseName, organization, textbook, active, createdBy, createdDate)"
                            "VALUES (%s, %s, %s, %s, %s, %s)") 

                    data_for_query = (course_name, organization, textbook, active, created_by, created_date)
                    
                    cursor = db.cursor(dictionary=True)
                    cursor.execute(query, data_for_query)
                    # Commit data to db
                    db.commit()
                    print('COMMITTED NEW RECORD...')
                    cursor.close()
                    print('CURSOR CLOSED...')

    except Error as e:
        print('Error while connecting to MySQL...', e)
            
    return{
        "statusCode": 200,
        "body": json.dumps({'Success': 'Course creation process has completed. Double check if your new course record was added correctly.'}, indent=3)
    }



#Update a pre-existing course record by courseId
def update_course_handler(event, context):
    request_body = json.loads(event['body'])
    course_id = request_body['courseId']
    course_name = request_body['courseName']
    organization = request_body['organization']
    textbook = request_body['textbook']
    active = True if request_body['active'] == 1 else False #ternary operator
    created_by = request_body['createdBy']
    created_date = request_body['createdDate']
    created_date_obj = datetime.datetime.strptime(created_date, '%Y-%m-%d %H:%M:%S')

    print(course_id)
    print(course_name)
    print(organization)
    print(textbook)
    print(active)
    print(created_by)
    print(created_date_obj)

    try:
        with DbUtils(host, db_name, username, password) as db:
            if db.is_connected():
                db_info = db.get_server_info()
                print("Connected to MySQL Server version:", db_info)
                
                if isinstance(course_name, str) and isinstance(organization, str) and isinstance(textbook, str) and isinstance(textbook, str) and isintance(active, bool) and isinstance(created_by, str):
                    #Select all records from courses table    
                    query = ("""UPDATE courses
                                SET courseName=%s, organization=%s, textbook=%s, active=%s, createdBy=%s, createdDate=%s
                                WHERE courseId=%s""") 

                    data_for_query = (course_name, organization, textbook, active, created_by, created_date_obj, course_id)
                    cursor = db.cursor(dictionary=True)
                    cursor.execute(query, data_for_query)
                    db.commit()
                    print('COMMITTED NEW RECORD...')
                    cursor.close()
                    print('CURSOR CLOSED...')

    except Error as e:
        print('Error while connecting to MySQL...', e)
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()
            print("MySQL connection is closed.")
            
    return{
        "statusCode": 200,
        "body": json.dumps({'Success': 'Course update process has completed. Double check if your new course record was added correctly.'}, indent=3)
    }



# function is doing a soft delete...
def course_delete_handler(event, context):
    request_body = json.loads(event['body'])
    course_id = request_body['courseId']
    active = True if request_body['active'] == 1 else False

    print(course_id)
    print(active)

    try:
        with DbUtils(host, db_name, username, password) as db:
            if db.is_connected():
                db_info = db.get_server_info()
                print("Connected to MySQL Server version:", db_info)
                
                query = ("UPDATE courses SET active=%s WHERE courseId=%s")
                
                data_for_query = (active, course_id)
                cursor = db.cursor(dictionary=True)
                db.commit()
                print('COMMITTED NEW RECORD...')
                cursor.close()
                print('CURSOR CLOSED...')

    except Error as e:
        print('Error while connecting to MySQL...', e)

    return{
        "statusCode": 200,
        "body": json.dumps({'Success': 'Course soft deletion process has completed. Double check if your selected course was deleted.'})
    }



