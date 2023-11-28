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

        with DbUtils(host, db_name, username, '1111') as db:
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

    if course_id is None:       
        return{
            "statusCode": 400,
            "body": json.dumps({'ERROR': 'The course id value was not valid or empty.'})
        }
    else: 
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

        # connection = mysql.connector.connect(host=host, database=db_name, user=username, password=password)
        # cursor = connection.cursor(dictionary=True)
        with DbUtils(host, db_name, username, password) as db:
            if db.is_connected():
                db_info = db.get_server_info()
                print("Connected to MySQL Server version:", db_info)
                

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
        print('Error while connecting to MySQL...')
        db.rollback()
        print('Rollbacked db commit due to error...', e)

            
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

        connection = mysql.connector.connect(host=host, database=db_name, user=username, password=password)
        cursor = connection.cursor(dictionary=True)

        if connection.is_connected():
            db_info = connection.get_server_info()
            print("Connected to MySQL Server version:", db_info)
            

            #Select all records from courses table    
            query = ("""UPDATE courses
                        SET courseName=%s, organization=%s, textbook=%s, active=%s, createdBy=%s, createdDate=%s
                        WHERE courseId=%s""") 

            data_for_query = (course_name, organization, textbook, active, created_by, created_date_obj, course_id)
            cursor.execute(query, data_for_query)

            # Commit data to db
            connection.commit()
    except Error as e:
        print('Error while connecting to MySQL...')
        connection.rollback()
        print('Rollbacked db commit due to error...', e)
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()
            print("MySQL connection is closed.")
            
    return{
        "statusCode": 200,
        "body": json.dumps({'Success': 'Course creation process has completed. Double check if your new course record was added correctly.'}, indent=3)
    }


# function is doing a soft delete...
def course_delete_handler(event, context):
    return{}



