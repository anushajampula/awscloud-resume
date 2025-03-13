import boto3
import json

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('visitorCount')

def lambda_handler(event, context):
    try:
        # Increment visitor count
        response = table.update_item(
            Key={'id': '1'},
            UpdateExpression='ADD visitorCount :incr',
            ExpressionAttributeValues={':incr': 1},
            ReturnValues='UPDATED_NEW'
        )
        
        # Get updated count
        visitor_count = int(response['Attributes']['visitorCount'])

        # Return API response with proper headers for CloudFront caching
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',  # Allow CORS
                'Cache-Control': 'max-age=10, public'  # Cache for 10 seconds
            },
            'body': json.dumps({'visitorCount': visitor_count})
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
