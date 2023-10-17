import json

def courses_getter_handler(event, context):
    
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
    
    return{
        "statusCode": 200,
        "body": json.dumps(courses, indent=3)
    }


# def course_update_handler(event, context):
#     return{}


# def course_delete_handler(event, context):
#     return{}



