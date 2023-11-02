import json
import boto3
import os
import mysql.connector
from mysql.connector import Error
from functions import *

courses = [
    {'courseId':1, 
        'name':'Human Anatomy & Physiology', 
        'org':'SUNY Cobleskill', 
        'textbook':'Human Anatomy & Physiology Version 1',
        'active':True
    },
    {'courseId':2, 
        'name':'Paramedic Field Clinical', 
        'org':'SUNY Cobleskill', 
        'textbook':'Paramedic Field Clinical Version 1',
        'active':True
    },
    {'courseId':3, 
        'name':'Paramedic Hospital Clinical', 
        'org':'SUNY Cobleskill', 
        'textbook':'Paramedic Hospital Clinical Version 1',
        'active':True
    },
    {'courseId':6, 
        'name':'Paramedic Lab ', 
        'org':'SUNY Cobleskill', 
        'textbook':'Paramedic Lab Version 1',
        'active':True
    },        
]

print("Start")

def courses_getter_handler(event, context):
    db_secret = os.environ.get('DB_SECRET')
    db_secret_value = json.loads(get_secret(db_secret))
    
    # host = db_secret_value['host']
    # db_name = db_secret_value['dbname']
    # username = db_secret_value['username']
    # password = db_secret_value['password']

    # print("db_secret_value", db_secret_value)
    # print("host: ", host)
    # print("db_name: ", db_name)
    # print("username: ", username)
    # print("password: ", password)

    print(db_secret)   
    
    # try:

    #     connection = mysql.connector.connect(host=host, database=db_name, user=username, password=password)
        
    #     if connection.is_connected():
    #         db_info = connection.get_server_info()
    #         print("Connected to MySQL Server version:", db_info)
    # except Error as e:
    #     print('Error while connecting to MySQL...', e)
    # finally:
    #     if connection.is_connected():
    #         connection.close()
    #         print("MySQL connection is closed.")
            
    return{
        "statusCode": 200,
        "body": json.dumps(courses, indent=3)
    }


def course_getter_handler(event, context):
    
    course_id = event['pathParameters']['courseId']
    ind_course = None

    if course_id is None:
       ind_course = next(item for item in courses if item["courseId"] == course_id)
       return{
            "statusCode": 200,
            "body": json.dumps(ind_course, indent=3)
       }
    return{
        "statusCode": 400,
        "body": json.dumps({'ERROR': 'The course id value was not valid or empty.'})
    }


# def course_update_handler(event, context):
#     return{}


# def course_delete_handler(event, context):
#     return{}



