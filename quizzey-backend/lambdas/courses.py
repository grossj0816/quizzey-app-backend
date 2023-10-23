import json

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
    {'courseId':4, 
        'name':'Paramedic Lab ', 
        'org':'SUNY Cobleskill', 
        'textbook':'Paramedic Lab Version 1',
        'active':True
    },        
]

def courses_getter_handler(event, context):
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



