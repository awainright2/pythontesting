import io
import json
import logging
logging.getLogger().info('Trying to import pyodbc')
import pyodbc

from fdk import response

def handler(ctx, data: io.BytesIO=None):
    logging.getLogger().info('Testing')
    name = "World"
    try:
        body = json.loads(data.getvalue())
        name = body.get("name")
    except (Exception, ValueError) as ex:
        logging.getLogger().info('error parsing json payload: ' + str(ex))

    logging.getLogger().info("Inside Python Hello World function")
    #isConnected = sqlConnection()
    return response.Response(
        ctx, response_data=json.dumps(
            #{"Message": "{0}".format(isConnected)}),
            {"Message": "test"}),
        headers={"Content-Type": "application/json"}
    )

def sqlConnection():
    server = '10.23.9.206'
    database = 'Apps'
    username = 'wainriac-lsa'
    password = 'mYaPP1ei$GolDen'

    try:
        logging.info('Attempting database connection...')
        conn = pyodbc.connect('DRIVER={SQL Server};SERVER='+server+',1433;DATABASE='+database+';UID='+username+';PWD='+ password)
        logging.info('Database connection successful')
        # Additional code for executing SQL statements or working with the database goes here
        # For example: cursor = conn.cursor()
        #              cursor.execute('SELECT * FROM your_table')
        #              rows = cursor.fetchall()
        #              print(rows)
        conn.close()  # Close the connection when done
    except pyodbc.Error as ex:
        error_message = "An error occurred: " + str(ex)
        logging.error(error_message)
        return error_message
        # Handle the error as per your application's requirements
    return "Connection successful"