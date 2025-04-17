import json
import boto3
import os
import jwt
import datetime
from boto3.dynamodb.conditions import Key

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb')
users_table = dynamodb.Table(os.environ.get('USERS_TABLE_NAME'))

# Secrets Manager client
secretsmanager = boto3.client('secretsmanager')

# Environment variables
JWT_SECRET_NAME = os.environ.get('JWT_SECRET_NAME')
JWT_EXPIRATION = int(os.environ.get('JWT_EXPIRATION', '86400'))

# Cache the secret
JWT_SECRET = None

def get_jwt_secret():
    global JWT_SECRET
    if JWT_SECRET is None:
        response = secretsmanager.get_secret_value(SecretId=JWT_SECRET_NAME)
        secret_dict = json.loads(response['SecretString'])
        JWT_SECRET = secret_dict['jwt_secret']
        print(f"[DEBUG] Loaded JWT secret: {JWT_SECRET[:8]}...")  # log first few chars
    return JWT_SECRET


def lambda_handler(event, context):
    try:
        http_method = event.get('httpMethod', '')
        path = event.get('path', '')
        body = {}

        if event.get('body'):
            body = json.loads(event['body'])

        print(f"[DEBUG] Handling {http_method} {path}")

        if http_method == 'POST' and path.endswith('/login'):
            return handle_login(body)
        elif http_method == 'POST' and path.endswith('/logout'):
            return handle_logout()
        elif http_method == 'GET' and path.endswith('/user'):
            return handle_get_user(event)
        else:
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'Invalid endpoint'})
            }

    except Exception as e:
        print(f"[ERROR] General exception: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Internal server error'})
        }


def handle_login(body):
    username = body.get('username')
    password = body.get('password')

    if not username or not password:
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Username and password are required'})
        }

    print(f"[DEBUG] Login attempt for username: {username}")

    response = users_table.query(
        IndexName='UsernameIndex',
        KeyConditionExpression=Key('username').eq(username)
    )

    items = response.get('Items', [])
    if not items:
        print("[WARN] No user found")
        return {
            'statusCode': 401,
            'body': json.dumps({'message': 'Invalid credentials'})
        }

    user = items[0]

    if user.get('password') != password:
        print("[WARN] Password mismatch")
        return {
            'statusCode': 401,
            'body': json.dumps({'message': 'Invalid credentials'})
        }

    token = generate_token(user)
    user.pop('password', None)

    print(f"[DEBUG] Token generated for user id: {user.get('id')}")

    return {
        'statusCode': 200,
        'body': json.dumps({
            'token': token,
            'user': user
        })
    }


def handle_logout():
    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Logout successful'})
    }


def generate_token(user):
    payload = {
        'sub': user['id'],
        'username': user['username'],
        'exp': datetime.datetime.utcnow() + datetime.timedelta(seconds=JWT_EXPIRATION)
    }
    token = jwt.encode(payload, get_jwt_secret(), algorithm='HS256')
    return token


def handle_get_user(event):
    auth_header = event.get('headers', {}).get('Authorization', '')
    print(f"[DEBUG] Authorization header: {auth_header[:40]}...")

    if not auth_header.startswith('Bearer '):
        return {
            'statusCode': 401,
            'body': json.dumps({'message': 'Invalid token'})
        }

    token = auth_header.split(' ')[1]
    print(f"[DEBUG] Raw token: {token[:40]}...")

    try:
        payload = jwt.decode(token, get_jwt_secret(), algorithms=['HS256'])
        print(f"[DEBUG] Decoded payload: {payload}")

        user_id = payload.get('sub')

        response = users_table.get_item(Key={'id': user_id})
        user = response.get('Item', {})

        if not user:
            print(f"[WARN] User not found for id: {user_id}")
            return {
                'statusCode': 404,
                'body': json.dumps({'message': 'User not found'})
            }

        user.pop('password', None)

        return {
            'statusCode': 200,
            'body': json.dumps(user)
        }

    except jwt.ExpiredSignatureError:
        print("[WARN] Token expired")
        return {
            'statusCode': 401,
            'body': json.dumps({'message': 'Token expired'})
        }
    except jwt.InvalidTokenError as e:
        print(f"[ERROR] Invalid token: {e}")
        return {
            'statusCode': 401,
            'body': json.dumps({'message': 'Invalid token'})
        }
